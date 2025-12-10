set -e


# Check if Minikube is running
if ! minikube status > /dev/null 2>&1; then
    echo "Error: Minikube is not running"
    echo "Please start Minikube with: minikube start --cpus=2 --memory=4096"
    exit 1
fi

echo "Minikube is running"
echo ""

echo "Configuring Docker to use Minikube's Docker daemon..."
eval $(minikube docker-env)
echo "✓ Docker environment configured"
echo ""

# Build image
echo "Building Docker image..."
cd app
docker build -t flask-mongodb-app:v1 .
cd ..
echo "Image built successfully"
echo ""

# Verify image
echo "Verifying image..."
if docker images | grep -q flask-mongodb-app; then
    echo "Image flask-mongodb-app:v1 available in Minikube Docker"
    echo ""
    docker images | grep flask-mongodb-app
else
    echo "Image not found"
    exit 1
fi

echo ""
echo "========================================="
echo "Build completed successfully!"
echo "========================================="
echo ""
echo "Image: flask-mongodb-app:v1"
echo ""
echo "IMPORTANT: This image is only available inside Minikube."
echo "Make sure your Kubernetes deployment uses: imagePullPolicy: Never"
echo ""
echo "Next steps:"
echo "1. Deploy to Kubernetes: ./scripts/deploy.sh"
echo "2. Or deploy manually: kubectl apply -f kubernetes/"
echo ""
echo "To push to Docker Hub instead:"
echo "1. docker login"
echo "2. docker tag flask-mongodb-app:v1 yourusername/flask-mongodb-app:v1"
echo "3. docker push yourusername/flask-mongodb-app:v1"
echo "4. Update deployment YAML to use: yourusername/flask-mongodb-app:v1"
echo "5. Change imagePullPolicy to: Always or IfNotPresent"