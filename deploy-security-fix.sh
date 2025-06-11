#!/bin/bash

echo "=== Deploying Dify Security Fix ==="
echo "Making Dify internal-only via ALB ingress"
echo ""

# Use the same kubeconfig as the working monitoring terminal
export KUBECONFIG=./ryand-20250609155222-RDSec-PSC-PROD.kubeconfig

echo "1. Applying internal ingress configuration..."
kubectl apply -f dify-internal-ingress.yaml -n trendgpt-dify

echo ""
echo "2. Updating Dify deployment to use ClusterIP service..."
helm upgrade dify ./charts/dify \
  --namespace trendgpt-dify \
  --values dify-prod-values.yaml \
  --timeout 10m

echo ""
echo "3. Checking ingress status..."
kubectl get ingress -n trendgpt-dify

echo ""
echo "4. Checking service status..."
kubectl get svc -n trendgpt-dify | grep dify

echo ""
echo "=== Deployment Complete ==="
echo "Dify is now secured with internal-only access via:"
echo "https://trendgptdify.runtime.trendmicro.com"