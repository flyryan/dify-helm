# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Helm chart repository for deploying [langgenius/dify](https://github.com/langgenius/dify), an LLM-based chatbot application, on Kubernetes clusters. The repository contains the Helm chart definition, templates, and deployment configurations.

## Common Commands

### Helm Chart Development
```bash
# Add required chart repositories for dependencies
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add weaviate https://weaviate.github.io/weaviate-helm
helm repo update

# Install/upgrade Dify deployment
helm upgrade --install my-release ./charts/dify -n <namespace> --kubeconfig <path-to-kubeconfig> -f <values-file>

# Example deployment with custom values
helm upgrade --install my-release ./charts/dify -n trendgpt-difynew --kubeconfig <path-to-kubeconfig> -f dify-custom-values.yaml

# Chart testing (using ct tool configuration in ct.yaml)
ct lint --config ct.yaml
```

### Working with Multiple Clusters
```bash
# The project involves cross-cluster migrations between:
# - Source: runtime-prod cluster, trendgpt-difynew namespace
# - Target: PSC-PROD cluster, trendgpt-dify namespace

# Scale deployments (for PVC conflicts)
kubectl --kubeconfig <path-to-kubeconfig> -n <namespace> scale deployment <deployment-name> --replicas=0
kubectl --kubeconfig <path-to-kubeconfig> -n <namespace> scale deployment <deployment-name> --replicas=1
```

## Architecture and Structure

### Chart Components
The Helm chart deploys the following Dify components:
- **Core Services**: API, Worker, Sandbox
- **Plugin Daemon**: For plugin management
- **Support Services**: SSRF Proxy, Web frontend
- **Data Layer**: PostgreSQL, Redis, Weaviate (vector database)
- **Networking**: Ingress configuration, proxy setup

### Key Configuration Files
- `charts/dify/values.yaml`: Default values for all components
- `dify-custom-values.yaml`: Production-specific overrides including:
  - Image versions for all components
  - Persistence configurations (PVC sizes)
  - Environment variables (URLs, passwords)
  - Resource limits (especially for Weaviate: 4 CPU cores, 8Gi memory)
- `dify-prod-values.yaml`: Template for production deployments

### Data Persistence
All stateful components use Persistent Volume Claims (PVCs):
- PostgreSQL: Primary (210Gi) and read replicas (210Gi each)
- Redis: Master (100Gi) and replicas (100Gi each)
- Weaviate: 60Gi storage
- API/Worker/Plugin Daemon: 16Gi each for shared data

### Migration Context
The repository is actively used for migrating Dify deployments between Kubernetes clusters. Key considerations:
- Database sizes: PostgreSQL ~11GB, Weaviate ~7.6GB
- Network constraints: Direct cluster-to-cluster transfer needed (user's internet is bottleneck)
- Known issues: PostgreSQL embeddings table corruption (can be excluded during migration)
- Database password: `difyai123456` (for migration purposes)

### Resource Requirements
Weaviate requires significant resources to prevent crashes:
- Requests: 1 CPU core, 2Gi memory
- Limits: 4 CPU cores, 8Gi memory

These allocations were determined through testing and are necessary for vector cache prefilling operations.