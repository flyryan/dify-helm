# Dify Security Migration - Internal Access Only

## Overview
This document outlines the security migration of Dify from public LoadBalancer access to internal-only access via AWS ALB ingress.

## Security Changes Made

### Before (Insecure)
- **Service Type**: LoadBalancer (publicly accessible)
- **Access**: Direct internet exposure via AWS NLB
- **URLs**: Public ELB hostname
- **Security Risk**: Application exposed to the entire internet

### After (Secure)
- **Service Type**: ClusterIP (internal only)
- **Access**: Internal ALB via ingress controller
- **URLs**: Internal domain `trendgptdify.runtime.trendmicro.com`
- **Security**: Internal network access only with SSL/TLS

## Files Modified

### 1. `dify-internal-ingress.yaml` (NEW)
- Internal ALB ingress configuration
- SSL termination with certificate
- Part of `rdsec.internal-services` ALB group
- Target type: IP for better performance

### 2. `dify-prod-values.yaml` (UPDATED)
- Changed service from LoadBalancer to ClusterIP
- Updated all API URLs to use internal domain
- Removed public LoadBalancer annotations

### 3. `deploy-internal-ingress.sh` (NEW)
- Automated deployment script
- Applies ingress and updates Helm deployment
- Monitors ALB provisioning status

## Deployment Instructions

1. **Review Configuration**
   ```bash
   # Check current certificate ARN in dify-internal-ingress.yaml
   # Update if needed for your environment
   ```

2. **Deploy Security Changes**
   ```bash
   ./deploy-internal-ingress.sh
   ```

3. **Update DNS**
   - Point `trendgptdify.runtime.trendmicro.com` to the ALB hostname
   - Ensure internal DNS resolution is configured

4. **Test Access**
   - Verify application is no longer publicly accessible
   - Test internal access via VPN/internal network

## Security Benefits

✅ **No Public Internet Exposure**
- Application only accessible from internal network
- Eliminates external attack surface

✅ **SSL/TLS Encryption**
- All traffic encrypted in transit
- Certificate-based authentication

✅ **ALB Integration**
- Part of existing internal services group
- Consistent security policies

✅ **Network Segmentation**
- Clear separation between internal and external traffic
- Follows zero-trust principles

## Rollback Plan

If needed, rollback by:
1. Reverting `dify-prod-values.yaml` to LoadBalancer configuration
2. Deleting the internal ingress: `kubectl delete -f dify-internal-ingress.yaml`
3. Running `helm upgrade` with original values

## Monitoring

Monitor the following after deployment:
- ALB health checks and target health
- Application accessibility from internal network
- SSL certificate expiration
- DNS resolution for internal domain

## Notes

- The original LoadBalancer will be removed automatically
- Existing sessions may be interrupted during migration
- Internal access requires VPN or internal network connectivity
- Certificate ARN may need updating for your specific environment