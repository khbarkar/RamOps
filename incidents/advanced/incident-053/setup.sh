#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLUSTER_NAME="consensus-failure"

echo "=== RamOps: Distributed Consensus Failure ==="
echo ""

if ! command -v kind &> /dev/null; then
  echo "ERROR: kind is not installed."
  echo "Install with: brew install kind"
  exit 1
fi

if ! command -v kubectl &> /dev/null; then
  echo "ERROR: kubectl is not installed."
  exit 1
fi

echo "Creating Kind cluster with custom etcd configuration..."
kind create cluster --name "$CLUSTER_NAME" --config "$SCENARIO_DIR/kind-config.yaml" --wait 60s

echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=ready node --all --timeout=120s

echo "Deploying etcd cluster..."
kubectl apply -f "$SCENARIO_DIR/manifests/etcd-cluster.yaml"

echo "Waiting for etcd pods..."
sleep 20
kubectl wait --for=condition=ready pod -l app=etcd -n etcd-system --timeout=120s

echo "Inducing split-brain condition..."
# Create network policies that partition the cluster
kubectl apply -f "$SCENARIO_DIR/manifests/network-partition.yaml"

echo "Waiting for split-brain to develop..."
sleep 30

echo ""
echo "============================================"
echo "  SCENARIO: Distributed Consensus Failure"
echo "  SETUP COMPLETE"
echo ""
echo "  etcd cluster is in split-brain state"
echo "  Multiple leaders may be elected"
echo "  Data consistency is compromised"
echo ""
echo "  Investigate with:"
echo "    kubectl get pods -n etcd-system"
echo "    kubectl exec -n etcd-system etcd-0 -- etcdctl endpoint health --cluster"
echo "    kubectl exec -n etcd-system etcd-0 -- etcdctl endpoint status --cluster -w table"
echo ""
echo "  WARNING: This is an expert-level scenario"
echo "  Requires deep understanding of Raft consensus"
echo "============================================"
