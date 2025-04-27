# GitHub Actions Workflows

This directory contains GitHub Actions workflows for CI/CD with integrated security scanning.

## Available Workflows

### CI/CD Pipeline with Security Checks (`build-and-security.yml`)

This workflow is triggered on:
- Pushes to the `main` branch
- Pull requests targeting the `main` branch
- Manual triggers via workflow_dispatch

The pipeline includes:
1. **Build and Test**: Builds the application and runs unit tests
2. **SonarQube Analysis**: Performs static code analysis
3. **Docker Build and Scan**: Builds the Docker image and scans it with Trivy
4. **Dynamic Application Security Testing**: Runs ZAP against the application
5. **Security Dashboard Generation**: Combines all security reports
6. **Deployment**: Deploys to Kubernetes (only on main branch)

### Scheduled Security Scanning (`security-scan.yml`)

This workflow is triggered on:
- Weekly schedule (Monday at 2:00 AM)
- Manual triggers via workflow_dispatch

The security scan includes:
1. **Container Scanning**: Scans the latest deployed Docker image with Trivy
2. **Dynamic Application Testing**: Runs a full ZAP scan on the deployed application
3. **SonarQube Analysis**: Performs static code analysis
4. **Security Dashboard Generation**: Creates a combined security dashboard
5. **Vulnerability Alerting**: Creates GitHub issues for critical/high vulnerabilities

## Required Secrets

To use these workflows, add the following secrets to your GitHub repository:

- `SONAR_TOKEN`: Authentication token for SonarQube
- `SONAR_HOST_URL`: URL of your SonarQube instance
- `DOCKER_USERNAME`: Docker Hub username for image pushing
- `DOCKER_PASSWORD`: Docker Hub password/token
- `KUBE_CONFIG`: Kubernetes configuration for deployments

## Security Reports

Security reports are generated as workflow artifacts and can be downloaded from the workflow run page. The main security dashboard provides a comprehensive view of all security findings. 