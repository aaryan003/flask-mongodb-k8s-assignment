#!/bin/bash

set -e

# Check if Minikube is running
if ! minikube status > /dev/null 2>&1; then
    echo "Error: Minikube is not running"
    echo "Please start Minikube with: minikube start --cpus=2 --memory=4096"
    exit 1
fi

echo "Minikube is running"

# Check if metrics-server is enabled
if ! kubectl get deployment metrics-server -n kube-system > /dev/null 2>&1; then
    echo "Enabling metrics-server..."
    minikube addons enable metrics-server
    echo "Waiting for metrics-server to be ready..."
    kubectl wait --for=condition=available --timeout=120s deployment/metrics-server -n kube-system
fi

echo "Metrics server is enabled"
echo ""

# Deploy namespace
echo "Step 1: Creating namespace..."
kubectl apply -f kubernetes/namespace.yaml
echo "Namespace created"
echo ""

# Deploy MongoDB
echo "Step 2: Deploying MongoDB..."
kubectl apply -f kubernetes/mongodb/mongodb-secret.yaml
kubectl apply -f kubernetes/mongodb/mongodb-pv.yaml
kubectl apply -f kubernetes/mongodb/mongodb-pvc.yaml
kubectl apply -f kubernetes/mongodb/mongodb-statefulset.yaml
kubectl apply -f kubernetes/mongodb/mongodb-service.yaml

echo "Waiting for MongoDB to be ready..."
kubectl wait --for=condition=ready pod -l app=mongodb -n flask-mongodb-ns --timeout=120s
echo "MongoDB deployed successfully"
echo ""

# Deploy Flask
echo "Step 3: Deploying Flask application..."
kubectl apply -f kubernetes/flask/flask-deployment.yaml
kubectl apply -f kubernetes/flask/flask-service.yaml
kubectl apply -f kubernetes/flask/flask-hpa.yaml

echo "Waiting for Flask pods to be ready..."
kubectl wait --for=condition=ready pod -l app=flask-app -n flask-mongodb-ns --timeout=120s
echo "Flask application deployed successfully"
echo ""

# Display status
echo "========================================="
echo "Deployment Status"
echo "========================================="
kubectl get all -n flask-mongodb-ns
echo ""

echo "========================================="
echo "Storage Status"
echo "========================================="
kubectl get pv
echo ""
kubectl get pvc -n flask-mongodb-ns
echo ""

echo "========================================="
echo "Access Information"
echo "========================================="
echo "Get service URL with:"
echo "  minikube service flask-service -n flask-mongodb-ns --url"
echo ""
echo "Or use port forwarding:"
echo "  kubectl port-forward -n flask-mongodb-ns service/flask-service 8080:80"
echo ""
echo "Test endpoints:"
echo "  curl http://<service-url>/"
echo "  curl http://<service-url>/health"
echo "  curl http://<service-url>/data"
echo ""
echo "Deployment completed successfully!"