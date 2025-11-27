# ------------------------------------
# STAGE 1: Build the Frontend (Node/NPM build, based on your original)
# ------------------------------------
FROM node:20-alpine AS frontend-builder
WORKDIR /app
# We no longer need to clone the repo, as the code is already checked out!
COPY project_frontend/package*.json ./
COPY project_frontend/ ./

# Install dependencies and build static files
RUN npm install
RUN npm run build
# Frontend output will be in /app/dist

# ------------------------------------
# STAGE 2: Build the Backend (Maven/Java/Spring Boot, based on your original)
# ------------------------------------
FROM maven:3.9.6-eclipse-temurin-21 AS backend-builder
WORKDIR /app
# We no longer need to clone the repo, as the code is already checked out!
COPY project_backend/ .

# Build the Spring Boot JAR
# Note: You can remove the 'apt-get install -y git' as it's not needed here
RUN mvn clean package -DskipTests
# Output: /app/target/*.jar 

# ------------------------------------
# STAGE 3: Final Production Image (Combines Nginx for Frontend and JRE for Backend)
# ------------------------------------
# Base the final image on the JRE, as your backend is the primary server
FROM eclipse-temurin:21-jre-alpine 
WORKDIR /app

# 1. Copy the built JAR file (Backend)
COPY --from=backend-builder /app/target/*.jar /app/app.jar 

# 2. Copy the built static files (Frontend)
# We need to serve the static files. Since your original setup used Nginx,
# the simplest way in a unified image is to put the static files where
# the Spring Boot application (your backend) expects them to be.
# A common default for Spring Boot is 'src/main/resources/static' or 'public'.
# Let's assume you've configured Spring to serve static files from '/app/static' or '/app/public'.
COPY --from=frontend-builder /app/dist /app/public 

# Set Environment Variables (matching your docker-compose)
ENV SPRING_DATASOURCE_URL=jdbc:mysql://event-db:3306/event
ENV SPRING_DATASOURCE_USERNAME=root
ENV SPRING_DATASOURCE_PASSWORD=root
ENV SPRING_JPA_HIBERNATE_DDL_AUTO=update
ENV JAVA_OPTS="" 
# Expose the port (matching your backend service port 8081 inside the container)
EXPOSE 8081

# Command to run the application (matching your original backend ENTRYPOINT)
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]