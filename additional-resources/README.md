# Additional Resources

This directory contains Kubernetes manifests that are not part of the upstream Dify Helm chart but are needed for our deployment.

## Files

### keepalive-cronjob.yaml
- **Purpose**: Prevents nginx 65-second timeout issues by sending health checks every 30 seconds
- **When to use**: Always deploy this after the main Helm chart to prevent connection timeouts
- **Deploy**: `kubectl apply -f additional-resources/keepalive-cronjob.yaml`

## Deployment Order

1. First deploy the main Dify Helm chart:
   ```bash
   helm upgrade --install dify ./charts/dify -n trendgpt-dify --kubeconfig <kubeconfig> -f dify-prod-values.yaml
   ```

2. Then apply additional resources:
   ```bash
   kubectl apply -f additional-resources/ --kubeconfig <kubeconfig>
   ```