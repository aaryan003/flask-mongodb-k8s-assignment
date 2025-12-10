# Kubernetes DNS Resolution – Quick README

## Overview

Kubernetes provides internal DNS so pods communicate using service names instead of IPs, ensuring stable connectivity even when pods restart or move.

## Service DNS Format

```
<service>.<namespace>.svc.cluster.local
```

Examples:

* Same namespace: `mongodb-service`
* Cross-namespace: `mongodb-service.flask-mongodb-ns`

## Flask → MongoDB Connection

Flask connects to MongoDB using the Service name:

```python
MONGO_HOST = os.getenv("MONGO_HOST", "mongodb-service")
MONGO_URI = f"mongodb://{MONGO_USERNAME}:{MONGO_PASSWORD}@{MONGO_HOST}:27017/?authSource=admin"
```

Deployment:

```yaml
env:
- name: MONGO_HOST
  value: "mongodb-service"
```

**Connection Flow**

```
Flask Pod → DNS → Service ClusterIP → MongoDB Pod
```

## DNS Inside Pods

Search paths in `/etc/resolv.conf`:

```
<namespace>.svc.cluster.local
svc.cluster.local
cluster.local
```

DNS resolves the service name to its ClusterIP, which forwards traffic to available backend pods.

## Testing DNS

```bash
kubectl exec -it <pod> -- nslookup mongodb-service
kubectl exec -it <pod> -- nc -zv mongodb-service 27017
```

## Common Issues

* **Service not found:** `kubectl get svc -n <ns>`
* **No endpoints:** `kubectl get endpoints <service>`
* **Wrong DNS name:** verify service + namespace in YAML

## Best Practices

* Use service names, never pod IPs
* Use short DNS names within the same namespace
* Externalize DB host via environment variables
* Add readiness/liveness probes for stable routing
