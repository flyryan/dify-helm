# Dify Helm Chart Upgrade Guide

This document provides instructions for upgrading the Dify Helm chart deployment.

## Prerequisites

- Kubernetes cluster with access via kubeconfig
- Helm v3 installed
- Access to the Dify Helm chart repository

## Upgrade Process

To upgrade the Dify deployment, use the following command:

```bash
helm upgrade --install my-release ./charts/dify -n trendgpt-difynew --kubeconfig <path-to-kubeconfig> -f dify-custom-values.yaml
```

Replace `<path-to-kubeconfig>` with the path to your kubeconfig file.

## Custom Values

All custom values for the Dify deployment are consolidated in the `dify-custom-values.yaml` file. This file includes:

1. **Image Versions**: Specifies the versions of all Dify components
2. **API Configuration**: Environment variables and persistence settings
3. **Worker Configuration**: Persistence settings
4. **Plugin Daemon Configuration**: Persistence settings
5. **PostgreSQL Configuration**: Persistence sizes for primary and read replicas
6. **Redis Configuration**: Persistence sizes for master and replicas
7. **Weaviate Configuration**: Storage size and resource allocations

## Resource Considerations

The Weaviate vector database requires significant resources to operate properly:
- CPU requests: 1 core
- Memory requests: 2Gi
- CPU limits: 4 cores
- Memory limits: 8Gi

These resource allocations were determined after testing and are necessary to prevent crashes during vector cache prefilling.

## Data Persistence

All data is stored in Persistent Volume Claims (PVCs) that are preserved during upgrades. The PVC sizes are configured in the custom values file to match the existing volumes.

## Troubleshooting

If you encounter issues during the upgrade:

1. Check the pod status: `kubectl get pods -n trendgpt-difynew`
2. Check the logs of problematic pods: `kubectl logs <pod-name> -n trendgpt-difynew`
3. If Weaviate is crashing, consider increasing its resources further in the custom values file

### Handling PVC Conflicts During Upgrades

When upgrading components that use PVCs with ReadWriteOnce access mode (like the plugin daemon), you might encounter issues where new pods are stuck in ContainerCreating state because the old pods are still using the PVCs. To resolve this:

1. Scale down the deployment to 0 replicas:
   ```bash
   kubectl --kubeconfig <path-to-kubeconfig> -n trendgpt-difynew scale deployment my-release-dify-plugin-daemon --replicas=0
   ```

2. Wait for all pods to terminate

3. Scale the deployment back up to 1 replica:
   ```bash
   kubectl --kubeconfig <path-to-kubeconfig> -n trendgpt-difynew scale deployment my-release-dify-plugin-daemon --replicas=1
   ```

This approach ensures that the new pod can successfully attach to the PVC without conflicts.
