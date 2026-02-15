# Exposed Database Credentials

**Difficulty:** Beginner-Intermediate
**Category:** Security & Best Practices
**Time estimate:** 15-20 minutes

## Scenario

A security audit has flagged your application deployment. The auditors found sensitive credentials stored insecurely in your Kubernetes configuration. This is a critical security vulnerability that must be fixed immediately.

Your task is to identify how credentials are being exposed and implement proper secret management.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Docker running

## Setup

```bash
./setup.sh
```

## Your Task

1. Identify how credentials are currently being stored
2. Understand why this is a security risk
3. Migrate credentials to use proper Kubernetes Secret objects
4. Run `./verify.sh` to confirm proper secret management

## Hints

<details>
<summary>Hint 1</summary>
Check the ConfigMap in the default namespace. What kind of data is stored there?
</details>

<details>
<summary>Hint 2</summary>
ConfigMaps are designed for non-sensitive configuration. Secrets should use the Secret resource type.
</details>

<details>
<summary>Hint 3</summary>
Create a Secret with the credentials, then update the deployment to reference it using <code>secretRef</code> instead of <code>configMapRef</code>.
</details>

<details>
<summary>Hint 4</summary>
Base64 encoding is NOT encryption. In production, consider using external secret management like HashiCorp Vault, AWS Secrets Manager, or sealed-secrets.
</details>

## Cleanup

```bash
./teardown.sh
```

## Production Parallels

This scenario mirrors:
- Credentials committed to git repositories
- API keys in ConfigMaps or environment variables
- Database passwords in plain text
- Lack of secret rotation policies
- Missing RBAC controls on secret access
