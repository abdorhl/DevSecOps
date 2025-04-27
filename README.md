# DevSecOps Pipeline with Kubernetes

This project implements a complete DevSecOps pipeline using Kubernetes as the orchestration platform, with the following components:

## Architecture

The project architecture follows the diagram below, with Kubernetes replacing OpenShift:

```
+-----------------------------------------------------------+
|                                                           |
|                      +----------------+                    |
|                      |    Grafana     | <--+               |
|                      +----------------+    |               |
|                                           |               |
|                                      +----------------+   |
|                                      |  Prometheus    |   |
|                                      +----------------+   |
|                                                           |
|  +---------------+  +---------------+  +---------------+  |
|  |               |  |               |  |               |  |
|  |    GitHub     |  |   SonarQube   |  |     Trivy     |  |
|  |               |  |               |  |               |  |
|  +-------+-------+  +-------+-------+  +-------+-------+  |
|          |                   |                  |          |
|          v                   v                  v          |
|  +-------+-------------------+------------------+-------+  |
|  |                                                      |  |
|  |                      Jenkins                         |  |
|  |                                                      |  |
|  +-------+-------------------+------------------+-------+  |
|          |                   |                  |          |
|          v                   v                  v          |
|  +-------+-------+  +-------+-------+  +-------+-------+  |
|  |               |  |               |  |               |  |
|  |    Docker     |  |     Nexus     |  |  Kubernetes   |  |
|  |               |  |               |  |               |  |
|  +---------------+  +---------------+  +---------------+  |
|                                                           |
+-----------------------------------------------------------+
```

## Components

- **Kubernetes**: Container orchestration
- **Jenkins**: CI/CD pipeline
- **GitHub**: Source code repository
- **Maven**: Build tool
- **SonarQube**: Code quality and security analysis (SAST)
- **Trivy**: Container vulnerability scanning
- **OWASP ZAP**: Dynamic application security testing (DAST)
- **Nexus**: Artifact repository
- **Prometheus & Grafana**: Monitoring and visualization

## Project Structure

- `/kubernetes`: Kubernetes manifests for deploying all components
  - `/jenkins`: Jenkins deployment configuration
  - `/sonarqube`: SonarQube deployment configuration
  - `/nexus`: Nexus deployment configuration
  - `/monitoring`: Prometheus and Grafana configuration
- `/jenkins`: Jenkins pipeline configuration and scripts
- `/sample-app`: Sample application for demonstration
- `/reports`: Security and analysis reports
  - `/security`: Generated security reports (SonarQube, Trivy, ZAP)

## Setup Instructions

### Prerequisites

- Kubernetes cluster (local like Minikube/Kind or cloud-based)
- kubectl configured to access your cluster
- Ingress controller installed in the cluster

### Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/yourusername/devsecops-k8s.git
   cd devsecops-k8s
   ```

2. Run the setup script:

   - For Linux/macOS:
     ```bash
     chmod +x setup.sh
     ./setup.sh
     ```

   - For Windows:
     ```powershell
     ./setup.ps1
     ```

3. Configure your hosts file to point the domains to your ingress controller IP:

   ```
   <INGRESS_IP> jenkins.example.com sonarqube.example.com nexus.example.com prometheus.example.com grafana.example.com myapp.example.com
   ```

4. Access the components:
   - Jenkins: http://jenkins.example.com
   - SonarQube: http://sonarqube.example.com
   - Nexus: http://nexus.example.com
   - Prometheus: http://prometheus.example.com
   - Grafana: http://grafana.example.com

## Sample Application

The project includes a sample Spring Boot application in the `/sample-app` directory. This application demonstrates how the CI/CD pipeline works with the various tools in the DevSecOps stack.

To build and deploy the sample application:

1. Create a Jenkins pipeline job pointing to the Jenkinsfile in the repository
2. Run the pipeline

## Security Reports

The pipeline generates comprehensive security reports from multiple tools:

1. **SonarQube**: Static Application Security Testing (SAST) for code analysis
2. **Trivy**: Container vulnerability scanning for Docker images
3. **OWASP ZAP**: Dynamic Application Security Testing (DAST) for running applications

These reports are available in the Jenkins build artifacts and locally in the `/reports/security` directory when generated using the `generate-security-reports.ps1` script.

### Generating Reports Locally

You can generate security reports locally using the provided PowerShell script:

```powershell
# Basic usage (Trivy only)
./generate-security-reports.ps1 -ImageName "myapp:latest"

# With SonarQube integration
./generate-security-reports.ps1 -SonarQubeUrl "http://localhost:9000" -SonarQubeToken "your-token" -ProjectKey "sample-app" -ImageName "myapp:latest"

# With ZAP scanning
./generate-security-reports.ps1 -ImageName "myapp:latest" -AppUrl "http://localhost:8080" -RunZapScan
```

Generated reports will be available in the `./reports/security` directory, with a combined dashboard at `./reports/security/index.html`.

## Customization

You can customize the configurations in the Kubernetes manifests to match your environment's requirements. Key areas for customization:

- Ingress hostnames in the ingress resources
- Resource allocations in deployment manifests
- Storage class names for the persistent volume claims
- Security scanning parameters in the Jenkinsfile or generate-security-reports.ps1 script 