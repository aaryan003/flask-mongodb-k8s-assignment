# Design Choices & Alternatives – Quick README

## 1. MongoDB Deployment

**Choice:** StatefulSet
**Why:** Stable pod names, automatic PVCs, safe for databases
**Alternative:** Deployment → no stable identity, risk of data loss

---

## 2. MongoDB Service

**Choice:** ClusterIP
**Why:** Internal-only, secure, no cost
**Alternatives:**

* NodePort → exposes DB, insecure
* LoadBalancer → unnecessary + costly

---

## 3. Flask Service

**Choice:** NodePort
**Why:** Simple external access in Minikube
**Alternatives:**

* LoadBalancer → needs cloud setup
* Ingress → better for production, overkill here

---

## 4. Storage

**Choice:** hostPath
**Why:** Works in Minikube
**Alternatives:**

* Cloud volumes → production only
* NFS/Ceph → complex for local

---

## 5. Volume Reclaim Policy

**Choice:** Retain
**Why:** Prevent accidental data loss
**Alternative:** Delete → dangerous for databases

---

## 6. Resource Requests & Limits

**Choice:** 200m CPU / 250Mi RAM (req), 500m CPU / 500Mi RAM (limit)
**Why:** Balanced for Minikube; avoids OOM issues
**Alternatives:**

* Higher → wasteful
* Lower → unstable

---

## 7. HPA Settings

**Choice:** 70% CPU target, 2–5 replicas
**Why:** Safe headroom + stability
**Alternatives:** 50% (too aggressive), 90% (too risky)

---

## 8. Authentication Storage

**Choice:** Kubernetes Secrets
**Why:** Built-in and better than ConfigMaps
**Alternatives:**

* External Secrets (Vault/AWS SM) → best for production
* Hardcoded → never acceptable

---

## 9. Flask Replicas

**Choice:** 2 replicas
**Why:** High availability, rolling updates
**Alternative:** 1 replica → downtime risk

---

## 10. Container Image Build

**Choice:** Build inside Minikube
**Why:** Fast, simple, no registry needed
**Alternatives:** Docker Hub/private registry → production use

---

## 11. MongoDB Version

**Choice:** 7.0
**Why:** Latest stable & optimized
**Alternatives:** Older versions → unnecessary

---

## 12. Flask Base Image

**Choice:** python:3.9-slim
**Why:** Lightweight + compatible
**Alternatives:**

* Full image → too heavy
* Alpine → dependency issues

---

## 13. Health Checks

**Flask:** HTTP probe
**MongoDB:** Exec probe (`db.adminCommand('ping')`)
**Why:** Validates real application health
**Alternative:** TCP → too shallow

---

## 14. Namespacing

**Choice:** Separate namespace
**Why:** Isolation & cleaner management
**Alternative:** default → cluttered and unorganized

---

## Summary Table

| Component        | Chosen             | Reason                |
| ---------------- | ------------------ | --------------------- |
| MongoDB Workload | StatefulSet        | Data persistence      |
| MongoDB Access   | ClusterIP          | Security              |
| Flask Access     | NodePort           | Minikube-friendly     |
| Storage          | hostPath           | Local dev             |
| Reclaim Policy   | Retain             | Prevent data loss     |
| Resources        | 200m/250Mi         | Balanced              |
| HPA              | 70%                | Stable scaling        |
| Secrets          | Kubernetes Secrets | Secure enough for dev |
| Replicas         | 2                  | High availability     |
| Image Build      | Minikube Docker    | Fast iteration        |
| MongoDB Version  | 7.0                | Latest stable         |
| Python Image     | slim               | Lightweight           |
| Probes           | HTTP + Exec        | Accurate checks       |
| Namespace        | custom             | Clean isolation       |

---

## Production Upgrade Path

* Use cloud persistent volumes
* Add Ingress + TLS
* Move secrets to Vault/AWS SM
* Add monitoring & logging
* Use private registry
* Add CI/CD and backups
* Apply NetworkPolicies
* Replace hostPath

