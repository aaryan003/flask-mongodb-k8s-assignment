#!/bin/bash

set -e

read -p "This will delete all resources in flask-mongodb-ns namespace. Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled"
    exit 0
fi

echo "Deleting namespace and all resources..."
kubectl delete namespace flask-mongodb-ns

echo "Waiting for namespace deletion..."
kubectl wait --for=delete namespace/flask-mongodb-ns --timeout=120s || true

echo ""
echo "Checking for remaining resources..."

# Check for PVs (they may persist due to Retain policy)
PVS=$(kubectl get pv --no-headers 2>/dev/null | grep flask-mongodb || true)
if [ -n "$PVS" ]; then
    echo ""
    echo "WARNING: The following Persistent Volumes still exist:"
    echo "$PVS"
    echo ""
    read -p "Delete these Persistent Volumes? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl get pv --no-headers | grep flask-mongodb | awk '{print $1}' | xargs kubectl delete pv
        echo "Persistent Volumes deleted"
    else
        echo "Persistent Volumes retained. Delete manually with: kubectl delete pv <pv-name>"
    fi
fi

echo ""
echo "========================================="
echo "Cleanup completed"
echo "========================================="
echo ""
echo "To stop Minikube:"
echo "  minikube stop"
echo ""
echo "To completely remove Minikube cluster:"
echo "  minikube delete"