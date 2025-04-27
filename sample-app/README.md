# Sample Spring Boot Application

This is a sample Spring Boot application that demonstrates a simple REST API. It is part of the DevSecOps with Kubernetes project.

## Building the Application

To build the application:

```bash
mvn clean package
```

## Running Locally

To run the application locally:

```bash
mvn spring-boot:run
```

The application will be available at http://localhost:8080

## Running Tests

To run the tests:

```bash
mvn test
```

## Building the Docker Image

To build the Docker image:

```bash
docker build -t myapp:latest .
```

## Deployment to Kubernetes

The application can be deployed to Kubernetes using the manifests in the `kubernetes` directory:

```bash
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
```

## CI/CD Pipeline

This application is designed to be built and deployed using the Jenkins pipeline defined in the project. The pipeline includes:

1. Building the application
2. Running tests
3. Static code analysis with SonarQube
4. Publishing artifacts to Nexus
5. Building a Docker image
6. Scanning the image for vulnerabilities with Trivy
7. Deploying to Kubernetes

## Monitoring

The application exposes metrics through Spring Boot Actuator, which can be scraped by Prometheus. Grafana dashboards can be used to visualize these metrics. 