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

## Publishing New Helm Chart Versions

When you make changes to the Helm chart, follow these steps to publish a new version to GitHub Pages:

### 1. Update Chart Version

First, update the version in `charts/my-app/Chart.yaml`:

```yaml
apiVersion: v2
name: my-app
description: A Helm chart with post-delete hook validation
type: application
version: 0.2.0  # Increment this version
appVersion: "1.0.0"
```

### 2. Package the Chart

Package the updated chart:

```bash
# From the repository root
helm package charts/my-app
```

This creates a new `.tgz` file (e.g., `my-app-0.2.0.tgz`).

### 3. Update Helm Repository Index

Update the repository index to include the new version:

```bash
helm repo index . --url https://alexlopes.github.io/sre-playground
```

This updates the `index.yaml` file with the new chart version.

### 4. Commit and Push Changes

Commit all changes to trigger GitHub Pages update:

```bash
git add .
git commit -m "Release Helm chart version 0.2.0"
git push origin main
```

### 5. Wait for GitHub Pages Deployment

GitHub Pages typically takes 1-2 minutes to deploy. You can monitor the deployment in your repository's "Actions" tab.

### 6. Update Release Manifest (if needed)

If you want to use the new version, update the `release.yaml`:

```yaml
spec:
  forProvider:
    chart:
      name: my-app
      repository: https://alexlopes.github.io/sre-playground
      version: "0.2.0"  # Update to new version
```

### 7. Apply the Updated Release

```bash
kubectl apply -f managed-resource/release.yaml
```

### Verification

Verify the new chart version is available:

```bash
# Test locally
helm repo add sre-playground https://alexlopes.github.io/sre-playground
helm repo update
helm search repo sre-playground

# Check available versions
helm search repo sre-playground/my-app --versions
```

## Termination Delay Simulation

The chart now includes realistic termination delays to simulate Crossplane AWS resource cleanup:

- **PreStop Hook**: Simulates AWS resource deletion time (configurable via `externalResource.terminationDelay`)
- **Signal Handling**: Proper SIGTERM handling with cleanup simulation
- **Extended Grace Period**: Allows sufficient time for cleanup processes

**Default Values**:
- Production: 2 minutes termination delay
- Testing: 1 minute termination delay (configured in Release manifest)

## Key Benefits

Using Crossplane provider-helm gives you:
- **Declarative Helm management** as Kubernetes resources
- **GitOps compatibility** with your existing Crossplane workflows
- **Consistent resource lifecycle** management alongside other Crossplane resources
- **Built-in status reporting** through Crossplane's resource conditions
- **Realistic cleanup simulation** for external resource dependencies