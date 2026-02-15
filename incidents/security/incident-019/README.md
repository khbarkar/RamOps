# Secrets Leaked in Image Layers

**Difficulty:** Intermediate
**Category:** Container Security
**Time estimate:** 20-25 minutes

## Scenario

Your security team discovered that an API key was leaked in a public Docker image. The developer claims they deleted it with `RUN rm -rf /tmp/*` in the Dockerfile, but the secret is still extractable from the image layers.

An attacker pulled your image from Docker Hub and extracted the API key from layer 5. They've been using it to access your production API for the past week.

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

1. Inspect the vulnerable image and find the leaked secret
2. Understand why deleting files doesn't remove them from layers
3. Rebuild the image securely without leaking secrets
4. Verify the secret is not extractable from the new image
5. Run `./verify.sh` to confirm

## Hints

Hint 1: Use docker history IMAGE_NAME to see all layers and commands

Hint 2: Use docker history --no-trunc IMAGE_NAME to see full commands including secrets

Hint 3: Layers are immutable - deleting a file in a later layer doesn't remove it from earlier layers

Hint 4: Use multi-stage builds or BuildKit secrets to avoid leaking secrets in any layer

## Cleanup

```bash
./teardown.sh
```
