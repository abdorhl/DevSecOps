# DevSecOps Pipeline with Kubernetes - Step by Step Guide

This guide explains the step-by-step implementation of a complete DevSecOps pipeline using Kubernetes as the orchestration platform.

## Architecture Overview

The DevSecOps pipeline consists of the following components:

- **Kubernetes**: Container orchestration platform
- **Jenkins**: CI/CD automation server
- **GitHub**: Source code repository
- **Maven**: Build tool for Java applications
- **SonarQube**: Code quality and security scanning
- **Trivy**: Container vulnerability scanning
- **Nexus**: Artifact repository
- **Prometheus & Grafana**: Monitoring and visualization

## Step 1: Setup Kubernetes Cluster

1. Set up a Kubernetes cluster using one of the following options:
   - Minikube (local development)
   - Kind (local development)
   - Docker Desktop Kubernetes (local development)
   - Managed Kubernetes service (AWS EKS, Azure AKS, Google GKE)

2. Install kubectl and verify connectivity:
   ```bash
   kubectl cluster-info
   ```

## Step 2: Create Namespaces

Create dedicated namespaces for your DevSecOps tools and applications:

```bash
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/monitoring/namespace.yaml
```

## Step 3: Deploy Jenkins

1. Set up Jenkins with required permissions:
   ```bash
   kubectl apply -f kubernetes/jenkins/rbac.yaml
   kubectl apply -f kubernetes/jenkins/deployment.yaml
   ```

2. Access Jenkins UI at http://jenkins.example.com (configure DNS or hosts file to point to your cluster's ingress IP)

3. Set up Jenkins credentials and plugins:
   - Docker credentials
   - Kubernetes credentials
   - GitHub credentials
   - SonarQube configuration

## Step 4: Deploy SonarQube

1. Deploy SonarQube for code quality and security scanning:
   ```bash
   kubectl apply -f kubernetes/sonarqube/deployment.yaml
   ```

2. Access SonarQube UI at http://sonarqube.example.com
   - Create a new project
   - Generate and save a token for CI/CD integration

## Step 5: Deploy Nexus Repository Manager

1. Deploy Nexus for artifact management:
   ```bash
   kubectl apply -f kubernetes/nexus/deployment.yaml
   ```

2. Access Nexus UI at http://nexus.example.com
   - Create Maven repositories (releases and snapshots)
   - Configure security settings

## Step 6: Deploy Trivy Operator for Kubernetes

1. Deploy Trivy for container scanning:
   ```bash
   kubectl apply -f kubernetes/trivy-operator.yaml
   ```

## Step 7: Set Up Monitoring

1. Deploy Prometheus for metrics collection:
   ```bash
   kubectl apply -f kubernetes/monitoring/prometheus/rbac.yaml
   kubectl apply -f kubernetes/monitoring/prometheus/config.yaml
   kubectl apply -f kubernetes/monitoring/prometheus/deployment.yaml
   ```

2. Deploy Grafana for metrics visualization:
   ```bash
   kubectl apply -f kubernetes/monitoring/grafana/datasources.yaml
   kubectl apply -f kubernetes/monitoring/grafana/deployment.yaml
   ```

3. Access Grafana UI at http://grafana.example.com
   - Log in with the generated credentials
   - Set up dashboards for application and infrastructure monitoring

## Step 8: CI/CD Pipeline Implementation

Create a Jenkinsfile in your application repository with the following stages:

1. **Checkout**: Clone the source code from GitHub
2. **Build**: Compile the application using Maven
3. **Unit Tests**: Run unit tests and verify code coverage
4. **SonarQube Analysis**: Scan code for quality issues and security vulnerabilities
5. **Publish to Nexus**: Upload build artifacts to Nexus Repository
6. **Build Docker Image**: Create a containerized version of your application
7. **Scan Image**: Use Trivy to check the Docker image for vulnerabilities
8. **Push to Registry**: Upload the Docker image to a container registry
9. **Deploy to Kubernetes**: Apply Kubernetes manifests to deploy the application

## Step 9: Monitoring and Logging

1. Configure your application to expose metrics through Prometheus
2. Set up log collection solutions (e.g., ELK Stack or Loki)
3. Create Grafana dashboards for application-specific metrics
4. Configure alerts for critical metrics and events

## Application Deployment

1. Create Kubernetes manifests for your application:
   ```bash
   kubectl apply -f sample-app/kubernetes/deployment.yaml
   kubectl apply -f sample-app/kubernetes/service.yaml
   ```

2. Access your application at the configured URL (e.g., http://myapp.example.com)

## View Logs and Monitoring

### Application Logs

1. View application logs directly:
   ```bash
   kubectl logs -f deployment/sample-app -n default
   ```

2. If using a centralized logging solution, access logs through its UI.

### Monitoring Metrics

1. Access Prometheus UI at http://prometheus.example.com to query raw metrics.

2. Access Grafana UI at http://grafana.example.com to view dashboards:
   - System dashboards (CPU, memory, network)
   - Kubernetes dashboards (pod status, resource usage)
   - Application dashboards (custom metrics, response times)

### CI/CD Pipeline Status

1. View build status and pipeline execution in Jenkins at http://jenkins.example.com

2. View code quality and security reports in SonarQube at http://sonarqube.example.com

3. View container vulnerability reports from Trivy scans in Jenkins build logs

### Artifact Management

1. Access artifacts and Docker images in Nexus at http://nexus.example.com

## Security Practices

1. **Static Application Security Testing (SAST)**:
   - SonarQube scans during the build process

2. **Dynamic Application Security Testing (DAST)**:
   - Integration with tools like OWASP ZAP

3. **Container Security**:
   - Trivy scans for container vulnerabilities

4. **Infrastructure as Code Security**:
   - Scanning Kubernetes YAML files for security issues

5. **Secret Management**:
   - Using Kubernetes Secrets
   - Integration with external secret management tools (HashiCorp Vault)

6. **Runtime Security**:
   - Kubernetes Pod Security Policies
   - Network Policies

## Automation & Self-Service

1. Use GitOps workflows for infrastructure and application deployments
2. Implement self-service capabilities through custom operators
3. Automate routine tasks with webhooks and event-driven pipelines 