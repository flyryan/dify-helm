#!/bin/bash

KUBECONFIG="./ryand-20250610155917-RDSec-PSC-PROD.kubeconfig"
NAMESPACE="trendgpt-dify"

echo "=== Testing Dify NLB Connectivity ==="
echo

# 1. Check proxy pod status
echo "1. Checking proxy pod status:"
kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get pods -l component=proxy -o wide
echo

# 2. Check service endpoints
echo "2. Checking service endpoints:"
kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get endpoints dify-loadbalancer
echo

# 3. Test direct pod connectivity
echo "3. Testing direct pod-to-pod connectivity:"
POD_IP=$(kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get pod -l component=proxy -o jsonpath='{.items[0].status.podIP}')
echo "Proxy pod IP: $POD_IP"
kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE run test-direct --image=curlimages/curl:latest --rm -it --restart=Never -- curl -I http://$POD_IP:80
echo

# 4. Test service connectivity
echo "4. Testing service connectivity:"
kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE run test-service --image=curlimages/curl:latest --rm -it --restart=Never -- curl -I http://dify-loadbalancer:80
echo

# 5. Check NLB status
echo "5. Checking NLB external hostname:"
kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get svc dify-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
echo
echo

# 6. Test from a pod with longer timeout
echo "6. Testing with extended timeout:"
kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE run test-timeout --image=curlimages/curl:latest --rm -it --restart=Never -- curl -I --connect-timeout 30 --max-time 60 http://dify-loadbalancer:80
echo

# 7. Check targetPort configuration
echo "7. Service targetPort configuration:"
kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get svc dify-loadbalancer -o jsonpath='{.spec.ports[*].targetPort}'
echo
echo

# 8. Check if proxy is in dify service
echo "8. Checking original dify service:"
kubectl --kubeconfig $KUBECONFIG -n $NAMESPACE get endpoints dify
echo