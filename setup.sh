#!/bin/bash

# DevSecOps with Kubernetes - Setup Script

set -e

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if kubectl can access the cluster
kubectl cluster-info || { echo "Failed to access Kubernetes cluster. Please check your kubeconfig."; exit 1; }

# Create namespaces
echo "Creating namespaces..."
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/monitoring/namespace.yaml

# Create RBAC for Jenkins
echo "Setting up Jenkins RBAC..."
kubectl apply -f kubernetes/jenkins/rbac.yaml

# Deploy Jenkins
echo "Deploying Jenkins..."
kubectl apply -f kubernetes/jenkins/deployment.yaml

# Deploy SonarQube
echo "Deploying SonarQube..."
kubectl apply -f kubernetes/sonarqube/deployment.yaml

# Deploy Nexus
echo "Deploying Nexus..."
kubectl apply -f kubernetes/nexus/deployment.yaml

# Deploy Prometheus
echo "Deploying Prometheus..."
kubectl apply -f kubernetes/monitoring/prometheus/rbac.yaml
kubectl apply -f kubernetes/monitoring/prometheus/config.yaml
kubectl apply -f kubernetes/monitoring/prometheus/deployment.yaml

# Deploy Grafana
echo "Deploying Grafana..."
kubectl apply -f kubernetes/monitoring/grafana/datasources.yaml
kubectl apply -f kubernetes/monitoring/grafana/deployment.yaml

# Deploy Trivy Operator
echo "Deploying Trivy Operator..."
kubectl apply -f kubernetes/trivy-operator.yaml

# Create a PVC for Maven cache
echo "Creating Maven cache PVC..."
cat << EOF | kubectl apply -f -
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
EOF

echo "Creating secrets for Grafana and SonarQube..."
# Generate random passwords
SONAR_DB_PASSWORD=$(openssl rand -base64 12)
GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 12)

# Create SonarQube DB credentials secret
kubectl create secret generic sonarqube-db-credentials \
  --namespace=devops \
  --from-literal=password=$SONAR_DB_PASSWORD \
  --dry-run=client -o yaml | kubectl apply -f -

# Create Grafana admin credentials secret
kubectl create secret generic grafana-admin-credentials \
  --namespace=monitoring \
  --from-literal=password=$GRAFANA_ADMIN_PASSWORD \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed successfully!"
echo ""
echo "Access the components using the following URLs:"
echo "Jenkins: http://jenkins.example.com"
echo "SonarQube: http://sonarqube.example.com"
echo "Nexus: http://nexus.example.com"
echo "Prometheus: http://prometheus.example.com"
echo "Grafana: http://grafana.example.com"
echo ""
echo "Grafana admin password: $GRAFANA_ADMIN_PASSWORD"
echo ""
echo "Note: You need to configure your DNS or /etc/hosts file to point these domains to your Kubernetes cluster's ingress controller IP." 