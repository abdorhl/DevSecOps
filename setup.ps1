# DevSecOps with Kubernetes - Setup Script for Windows

# Check if kubectl is installed
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl is not installed. Please install kubectl first."
    exit 1
}

# Check if kubectl can access the cluster
try {
    kubectl cluster-info
}
catch {
    Write-Error "Failed to access Kubernetes cluster. Please check your kubeconfig."
    exit 1
}

# Create namespaces
Write-Output "Creating namespaces..."
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/monitoring/namespace.yaml

# Create RBAC for Jenkins
Write-Output "Setting up Jenkins RBAC..."
kubectl apply -f kubernetes/jenkins/rbac.yaml

# Deploy Jenkins
Write-Output "Deploying Jenkins..."
kubectl apply -f kubernetes/jenkins/deployment.yaml

# Deploy SonarQube
Write-Output "Deploying SonarQube..."
kubectl apply -f kubernetes/sonarqube/deployment.yaml

# Deploy Nexus
Write-Output "Deploying Nexus..."
kubectl apply -f kubernetes/nexus/deployment.yaml

# Deploy Prometheus
Write-Output "Deploying Prometheus..."
kubectl apply -f kubernetes/monitoring/prometheus/rbac.yaml
kubectl apply -f kubernetes/monitoring/prometheus/config.yaml
kubectl apply -f kubernetes/monitoring/prometheus/deployment.yaml

# Deploy Grafana
Write-Output "Deploying Grafana..."
kubectl apply -f kubernetes/monitoring/grafana/datasources.yaml
kubectl apply -f kubernetes/monitoring/grafana/deployment.yaml

# Deploy Trivy Operator
Write-Output "Deploying Trivy Operator..."
kubectl apply -f kubernetes/trivy-operator.yaml

# Create a PVC for Maven cache
Write-Output "Creating Maven cache PVC..."
$m2Cache = @"
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: m2-cache
  namespace: devops
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
"@
$m2Cache | kubectl apply -f -

# Generate random passwords
Write-Output "Creating secrets for Grafana and SonarQube..."
$SonarDbPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object {[char]$_})
$GrafanaAdminPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object {[char]$_})

# Create SonarQube DB credentials secret
kubectl create secret generic sonarqube-db-credentials `
  --namespace=devops `
  --from-literal=password=$SonarDbPassword `
  --dry-run=client -o yaml | kubectl apply -f -

# Create Grafana admin credentials secret
kubectl create secret generic grafana-admin-credentials `
  --namespace=monitoring `
  --from-literal=password=$GrafanaAdminPassword `
  --dry-run=client -o yaml | kubectl apply -f -

Write-Output "Setup completed successfully!"
Write-Output ""
Write-Output "Access the components using the following URLs:"
Write-Output "Jenkins: http://jenkins.example.com"
Write-Output "SonarQube: http://sonarqube.example.com"
Write-Output "Nexus: http://nexus.example.com"
Write-Output "Prometheus: http://prometheus.example.com"
Write-Output "Grafana: http://grafana.example.com"
Write-Output ""
Write-Output "Grafana admin password: $GrafanaAdminPassword"
Write-Output ""
Write-Output "Note: You need to configure your DNS or hosts file to point these domains to your Kubernetes cluster's ingress controller IP." 