# Leaked API Key

**Difficulty:** Intermediate
**Category:** Security
**Time estimate:** 20-25 minutes

## Scenario

Your security team received an alert: someone has been using a leaked API key to access your production systems. After investigation, they traced it back to a container image running in your Kubernetes cluster.

An attacker somehow extracted the API key from the image and has been using it for unauthorized access. The image was pulled from your container registry. You need to perform forensic analysis on the image to understand how the secret was leaked and prevent this from happening again.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Docker running

## Setup

```bash
./setup.sh
```

This creates a Kind cluster and builds a vulnerable container image with secrets leaked in the layers.

## Your Task

1. Check what's running in the cluster: `kubectl get pods -n security-demo`
2. Investigate how the attacker extracted the API key from the container image
3. Create a secure version that doesn't leak secrets
4. Run `./verify.sh` to confirm your fix works

## Hints

Hint 1: Check what image is running in the deployment. The image is already loaded in your local Docker from the setup.

Hint 2: List your local Docker images with `docker images` to find the vulnerable image.

Hint 3: Export the image to inspect its layers: `docker save IMAGE_NAME -o image.tar` then `tar -xf image.tar`

Hint 4: Each layer is a tar file. Extract them and look for files containing secrets. Or use `docker history --no-trunc IMAGE_NAME` to see what commands created each layer.

Hint 5: Look for the API_KEY in the layer history or extracted files. Even if a file was deleted in a later layer, it still exists in the layer where it was created.

Hint 6: Docker layers are immutable. Deleting a file with `RUN rm` doesn't remove it from previous layers - it just marks it as deleted in the current layer.

Hint 7: To fix this, rebuild the image using multi-stage builds where secrets are only in the build stage and never make it to the final image. Check `Dockerfile.secure` for an example.

## Cleanup

```bash
./teardown.sh
```
