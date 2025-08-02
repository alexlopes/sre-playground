# Managed Resource - My App Release

This directory contains the Crossplane provider-helm Release manifest to deploy the my-app Helm chart from a Git repository.

## Files

- `release.yaml`: Crossplane provider-helm Release resource that deploys the chart directly from GitHub

## Prerequisites

1. **Crossplane installed** in your cluster
2. **provider-helm** installed and configured:
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: pkg.crossplane.io/v1
   kind: Provider
   metadata:
     name: provider-helm
   spec:
     package: xpkg.upbound.io/crossplane-contrib/provider-helm:v0.15.0
   EOF
   ```

3. **ProviderConfig** for Helm provider:
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: helm.crossplane.io/v1beta1
   kind: ProviderConfig
   metadata:
     name: default
   spec:
     credentials:
       source: InjectedIdentity
   EOF
   ```

## Setup Instructions

### 1. Deploy the Release

Apply the manifest to your cluster:

```bash
kubectl apply -f managed-resource/release.yaml
```

### 2. Monitor the Deployment

Check the status of your resources:

```bash
# Check Crossplane Release status
kubectl get release my-app-release

# Check the deployed application
kubectl get deployment my-app-release-external-resource

# View Release details and conditions
kubectl describe release my-app-release

# Check Crossplane provider-helm logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-helm
```

## Configuration

The Crossplane Release overrides several default values:
- Reduced sleep duration to 3 minutes for faster testing
- Increased resource limits
- Configured post-delete hook with 4-minute timeout

You can modify these values in the `release.yaml` file under the `forProvider.values` section.

## Testing the Post-Delete Hook

To test the post-delete validation:

1. Delete the Crossplane Release:
   ```bash
   kubectl delete release my-app-release
   ```

2. Monitor the post-delete hook job:
   ```bash
   kubectl get jobs -l component=post-delete-hook
   kubectl logs -l component=post-delete-hook
   ```

The hook will validate that the external resource deployment is properly cleaned up.

## Key Benefits

Using Crossplane provider-helm gives you:
- **Declarative Helm management** as Kubernetes resources
- **GitOps compatibility** with your existing Crossplane workflows
- **Consistent resource lifecycle** management alongside other Crossplane resources
- **Built-in status reporting** through Crossplane's resource conditions