# Kubernetes Resource Management – Quick README

## What It Is

Kubernetes lets you assign **resource requests** (minimum guaranteed) and **limits** (maximum allowed) to keep pods stable and prevent any container from overusing CPU or memory.

---

## CPU & Memory Units

* **CPU:** `1` = 1 core, `500m` = 0.5 core
* **Memory:** `Mi`, `Gi` (e.g., `250Mi`)

---

## Requests vs Limits

### **Requests**

Minimum resources the pod is guaranteed. Scheduler uses this to pick a node.

### **Limits**

Maximum resources the container can use.

* Exceed CPU → throttled
* Exceed memory → OOMKilled (pod restarts)

---

## Example (Flask + MongoDB)

```yaml
resources:
  requests:
    cpu: "200m"
    memory: "250Mi"
  limits:
    cpu: "500m"
    memory: "500Mi"
```

---

## CPU Behavior

* Below request → normal
* Between request & limit → may get throttled
* At limit → performance slows

## Memory Behavior

* Below limit → fine
* At limit → pod is killed (OOMKilled)

---

## QoS Classes

| Class      | Condition                      | Priority |
| ---------- | ------------------------------ | -------- |
| Guaranteed | requests = limits              | Highest  |
| Burstable  | requests < limits (our config) | Medium   |
| BestEffort | no requests/limits             | Lowest   |

---

## Scheduling Logic

A node must have at least:

```
CPU ≥ request
Memory ≥ request
```

Only then the pod is scheduled.

---

## Eviction Priority

When node is under pressure:

1. BestEffort
2. Burstable (above request)
3. Burstable (within request)
4. Guaranteed

---

## Why Our Values?

* **CPU 200m → 500m:** lightweight Flask workload + burst allowance
* **Memory 250Mi → 500Mi:** enough for Python runtime + buffer

---

## HPA Note

HPA uses **requests**, not limits.
With request = `200m`:

```
70% target = 140m CPU threshold
```

---

## Monitoring

```bash
kubectl top pods -n flask-mongodb-ns
kubectl top nodes
kubectl describe pod <name>
```

---

## Common Issues

### Pod Pending

Not enough resources → lower requests or add nodes.

### OOMKilled

Exceeded memory limit → increase limit or fix memory leak.

### CPU Throttling

Hitting CPU limit → raise limit or optimize code.

---

## Best Practices

* Always define requests & limits
* Set requests based on normal usage
* Set limits 1.5×–3× above requests
* Monitor and adjust periodically

---

## Summary

Resource requests and limits ensure:

* Predictable performance
* Fair sharing of node resources
* Protection from memory/CPU starvation
* Proper autoscaling behavior

This configuration (200m/250Mi → 500m/500Mi) balances efficiency, safety, and scalability for typical Flask workloads.
