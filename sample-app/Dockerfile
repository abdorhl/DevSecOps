FROM eclipse-temurin:11-jre-alpine

# Create non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Set working directory
WORKDIR /app

# Copy the jar file
COPY target/*.jar app.jar

# Set entry point
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

# Expose port
EXPOSE 8080 