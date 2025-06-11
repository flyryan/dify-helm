#!/bin/bash

set -e

echo "=== Deploying Dify Internal Ingress ==="
echo "This secures Dify by making it internal-only via ALB ingress"
echo ""

# Set target cluster context
export KUBECONFIG=./ryand-20250611015049-RDSec-PSC-PROD.kubeconfig

echo "1. Checking current Dify deployment status..."
kubectl get pods -n trendgpt-dify -l app.kubernetes.io/name=dify

echo ""
echo "2. Applying internal ingress configuration..."
kubectl apply -f dify-internal-ingress.yaml

echo ""
echo "3. Checking ingress status..."
kubectl get ingress -n trendgpt-dify dify-internal-ingress

echo ""
echo "4. Updating Dify deployment with new service configuration..."
helm upgrade dify ./charts/dify \
  --namespace trendgpt-dify \
  --values dify-prod-values.yaml \
  --wait \
  --timeout 10m

echo ""
echo "5. Verifying deployment..."
kubectl get pods -n trendgpt-dify -l app.kubernetes.io/name=dify
kubectl get services -n trendgpt-dify -l app.kubernetes.io/name=dify
kubectl get ingress -n trendgpt-dify

echo ""
echo "6. Waiting for ingress to be ready..."
echo "⏳ This may take a few minutes for ALB to provision..."

# Wait for ingress to get an address
timeout=300
counter=0
while [ $counter -lt $timeout ]; do
    ADDRESS=$(kubectl get ingress dify-internal-ingress -n trendgpt-dify -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$ADDRESS" ]; then
        echo "✅ Internal ALB provisioned: $ADDRESS"
        break
    fi
    echo "Waiting for ALB... ($counter/$timeout seconds)"
    sleep 10
    counter=$((counter + 10))
done

if [ $counter -ge $timeout ]; then
    echo "⚠️  Timeout waiting for ALB, but ingress is created. Check AWS console for ALB status."
else
    echo ""
    echo "✅ Dify is now secured with internal-only access!"
    echo ""
    echo "📋 Summary:"
    echo "   - Service changed from LoadBalancer to ClusterIP"
    echo "   - Internal ALB ingress created with SSL termination"
    echo "   - Access URL: https://trendgptdify.runtime.trendmicro.com"
    echo "   - ALB Hostname: $ADDRESS"
    echo ""
    echo "🔒 Security improvements:"
    echo "   - No longer exposed to public internet"
    echo "   - Internal ALB with SSL/TLS encryption"
    echo "   - Part of rdsec.internal-services ALB group"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Update DNS to point trendgptdify.runtime.trendmicro.com to $ADDRESS"
    echo "   2. Update certificate ARN in dify-internal-ingress.yaml if needed"
    echo "   3. Test access from internal network"
fi