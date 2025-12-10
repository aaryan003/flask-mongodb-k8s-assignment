# flask-mongodb-k8s-assignment
# Flask-MongoDB Kubernetes Deployment

A Flask REST API application with MongoDB database deployed on Kubernetes using Minikube. Features include authentication, persistent storage, autoscaling, and comprehensive resource management.

## Project Structure

```
flask-mongodb-k8s/
│── app.py
│── requirements.txt
│── Dockerfile
├── kubernetes/
│   ├── namespace.yaml
│   ├── mongodb/
│   │   ├── mongodb-secret.yaml
│   │   ├── mongodb-pv.yaml
│   │   ├── mongodb-pvc.yaml
│   │   ├── mongodb-statefulset.yaml
│   │   └── mongodb-service.yaml
│   └── flask/
│       ├── flask-deployment.yaml
│       ├── flask-service.yaml
│       └── flask-hpa.yaml
├── docs/
│   ├── DNS-RESOLUTION.md
│   ├── RESOURCE-MANAGEMENT.md
│   ├── DESIGN-CHOICES.md
│   └── TESTING.md
└── README.md
```

## Prerequisites

Install the following on your system:

- Docker (v20.10 or later)
- Minikube (v1.25 or later)
- kubectl (v1.21 or later)
- Python 3.9+ (for local development)

Verify installations:
```bash
docker --version
minikube version
kubectl version --client
```

## Quick Start

### 1. Start Minikube

```bash
minikube start --cpus=2 --memory=4096 --driver=docker
minikube addons enable metrics-server
```

Wait for metrics server to be ready (1-2 minutes):
```bash
kubectl get deployment metrics-server -n kube-system
```

### 2. Build Docker Image

Point your terminal to Minikube's Docker daemon:
```bash
eval $(minikube docker-env)
```

Build the Flask application image:
```bash
cd app
docker build -t flask-mongodb-app:v1 .
cd ..
```

Verify image exists:
```bash
docker images | grep flask-mongodb-app
```

### 3. Deploy to Kubernetes

Create namespace:
```bash
kubectl apply -f kubernetes/namespace.yaml
```

Deploy MongoDB:
```bash
kubectl apply -f kubernetes/mongodb/mongodb-secret.yaml
kubectl apply -f kubernetes/mongodb/mongodb-pv.yaml
kubectl apply -f kubernetes/mongodb/mongodb-pvc.yaml
kubectl apply -f kubernetes/mongodb/mongodb-statefulset.yaml
kubectl apply -f kubernetes/mongodb/mongodb-service.yaml
```

Wait for MongoDB to be ready:
```bash
kubectl wait --for=condition=ready pod -l app=mongodb -n flask-mongodb-ns --timeout=120s
```

Deploy Flask application:
```bash
kubectl apply -f kubernetes/flask/flask-deployment.yaml
kubectl apply -f kubernetes/flask/flask-service.yaml
kubectl apply -f kubernetes/flask/flask-hpa.yaml
```

Wait for Flask pods to be ready:
```bash
kubectl wait --for=condition=ready pod -l app=flask-app -n flask-mongodb-ns --timeout=120s
```

### 4. Access the Application

Get the service URL:
```bash
minikube service flask-service -n flask-mongodb-ns --url
```

Or use port forwarding:
```bash
kubectl port-forward -n flask-mongodb-ns service/flask-service 8080:80
```

Application will be available at the provided URL or http://localhost:8080

## API Endpoints

### Home
```bash
curl http://<service-url>/
```
Returns: Welcome message with current timestamp

### Health Check
```bash
curl http://<service-url>/health
```
Returns: Application and database health status

### Insert Data
```bash
curl -X POST http://<service-url>/data \
  -H "Content-Type: application/json" \
  -d '{"name":"John","age":30}'
```
Returns: Confirmation with inserted data ID

### Retrieve Data
```bash
curl http://<service-url>/data
```
Returns: All stored documents with count

## Verification Steps

### Check All Resources

```bash
kubectl get all -n flask-mongodb-ns
```

Expected output:
- 1 MongoDB pod (mongodb-0)
- 2 Flask pods (flask-app-xxxx)
- 2 Services (mongodb-service, flask-service)
- 1 StatefulSet (mongodb)
- 1 Deployment (flask-app)
- 1 HPA (flask-app-hpa)

### Check Persistent Storage

```bash
kubectl get pv
kubectl get pvc -n flask-mongodb-ns
```

Both PV and PVC should show STATUS: Bound

### Check Autoscaler

```bash
kubectl get hpa -n flask-mongodb-ns
```

Should show current CPU percentage and replica count

### View Logs

```bash
# Flask logs
kubectl logs -f deployment/flask-app -n flask-mongodb-ns

# MongoDB logs
kubectl logs -f mongodb-0 -n flask-mongodb-ns
```

## Testing Autoscaling

### Generate Load

Create a load generator pod:
```bash
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh
```

Inside the pod, run:
```bash
while true; do wget -q -O- http://flask-service.flask-mongodb-ns.svc.cluster.local; done
```

### Monitor Scaling

In separate terminals, watch:

HPA status:
```bash
watch kubectl get hpa -n flask-mongodb-ns
```

Pod status:
```bash
watch kubectl get pods -n flask-mongodb-ns
```

Resource usage:
```bash
watch kubectl top pods -n flask-mongodb-ns
```

Pods should scale from 2 to 5 as CPU exceeds 70% threshold. After stopping load, pods scale back down to 2 (takes a few minutes due to stabilization window).

## Architecture

The application consists of:

**Flask Application (Stateless)**
- Deployment with 2-5 replicas (autoscaled)
- NodePort service for external access
- Resource limits: 200m CPU (request), 500m CPU (limit)
- Connects to MongoDB via internal DNS

**MongoDB Database (Stateful)**
- StatefulSet with 1 replica
- ClusterIP service for internal access only
- Authentication enabled with credentials in Kubernetes Secret
- Persistent storage via PV/PVC (survives pod restarts)
- Resource limits: 200m CPU (request), 500m CPU (limit)

**Networking**
- Flask pods communicate with MongoDB using DNS name "mongodb-service"
- Kubernetes CoreDNS resolves service names to ClusterIP addresses
- External users access Flask via NodePort on Minikube IP

**Storage**
- PersistentVolume using hostPath (Minikube local storage)
- PersistentVolumeClaim automatically bound to PV
- MongoDB data stored at /mnt/data/mongodb on Minikube node
- Data persists across pod deletions and restarts

**Autoscaling**
- HorizontalPodAutoscaler monitors Flask CPU usage
- Scales up when average CPU exceeds 70% of requests (140m)
- Minimum 2 replicas (high availability)
- Maximum 5 replicas (resource constraint)
- Metrics provided by metrics-server addon

## Configuration Details

### Resource Requests and Limits

Both Flask and MongoDB pods have:
- Request: 200m CPU, 250Mi memory (guaranteed minimum)
- Limit: 500m CPU, 500Mi memory (maximum allowed)

Requests ensure each pod gets minimum resources. Limits prevent any pod from consuming excessive resources. The HPA threshold (70%) is calculated based on requests (200m), so scaling occurs at 140m CPU usage per pod.

### MongoDB Authentication

MongoDB authentication is configured via:
1. Kubernetes Secret containing base64-encoded credentials
2. Environment variables in StatefulSet (MONGO_INITDB_ROOT_USERNAME/PASSWORD)
3. Flask connection string includes credentials from same Secret
4. Authentication database is "admin" (MongoDB default)

To change credentials:
```bash
# Encode new values
echo -n 'newuser' | base64
echo -n 'newpass' | base64

```

### DNS Resolution

Flask connects to MongoDB using the service name "mongodb-service". Kubernetes DNS resolution process:

1. Flask makes request to mongodb-service:27017
2. Container queries CoreDNS (Kubernetes DNS server)
3. DNS resolves to Service ClusterIP (e.g., 10.96.5.10)
4. Service routes to MongoDB pod based on label selector
5. Connection established

Full DNS name is mongodb-service.flask-mongodb-ns.svc.cluster.local but short name works within the same namespace.

### Health Checks

**Liveness Probes**
- Check if container is alive
- If fails, Kubernetes restarts the container
- Flask: HTTP GET /health every 10 seconds
- MongoDB: Exec mongosh ping command every 10 seconds

**Readiness Probes**
- Check if container is ready to serve traffic
- If fails, pod removed from service endpoints (no traffic sent)
- Same checks as liveness but different failure handling


Verify metrics server:
```bash
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
kubectl top pods -n flask-mongodb-ns
```

If metrics show "unknown", wait 1-2 minutes for metrics collection to start.

### Data Loss

Check PV/PVC status:
```bash
kubectl get pv
kubectl get pvc -n flask-mongodb-ns
kubectl describe pvc mongodb-storage-mongodb-0 -n flask-mongodb-ns
```

Verify PV reclaim policy is "Retain" to prevent accidental data deletion.

## Cleanup

Delete all resources:
```bash
kubectl delete namespace flask-mongodb-ns
```

Or delete individually:
```bash
kubectl delete -f kubernetes/flask/
kubectl delete -f kubernetes/mongodb/
kubectl delete -f kubernetes/namespace.yaml
```

Stop Minikube:
```bash
minikube stop
```

Delete Minikube cluster:
```bash
minikube delete
```

**Resource Requirements:**
- Minimum: 2 CPU cores, 4Gi RAM (Minikube)
- Per Pod: 200m CPU request, 500m CPU limit, 250Mi RAM request, 500Mi RAM limit
- Maximum Pods: 7 total (1 MongoDB + 2-5 Flask + 1 metrics server)

**Security Features:**
- MongoDB authentication enabled
- Credentials stored in Kubernetes Secrets
- Database not exposed externally (ClusterIP service)
- Network isolation via namespace

**High Availability:**
- Minimum 2 Flask replicas
- Liveness/readiness probes for automatic recovery
- Rolling updates for zero-downtime deployments
- Persistent storage survives pod failures

## License

MIT License

## Author

Aryan Patel
