# Incident-008

**Difficulty:** Intermediate
**Category:** Incidents & Outages
**Time estimate:** 25-30 minutes

## Scenario

Your API gateway suddenly stopped accepting HTTPS connections. Clients are reporting "certificate has expired" errors. The service was working fine yesterday, but now all HTTPS traffic is failing while HTTP still works.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Docker running

## Setup

```bash
./setup.sh
```

## Your Task

1. Diagnose why HTTPS connections are failing
2. Identify the certificate issue
3. Fix the certificate problem
4. Verify HTTPS connections work again
5. Run `./verify.sh` to confirm your fix

## Symptoms You'll See

- HTTPS requests failing with certificate errors
- `curl` showing "certificate has expired"
- HTTP traffic still works fine
- Service is running but unreachable via HTTPS

## Hints

<details>
<summary>Hint 1</summary>
Check the ingress or service TLS configuration. Look at the secret containing the certificate.
</details>

<details>
<summary>Hint 2</summary>
Use <code>kubectl get secret &lt;secret-name&gt; -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout</code> to inspect the certificate details.
</details>

<details>
<summary>Hint 3</summary>
Check the "Not After" field in the certificate. Compare it to the current date.
</details>

<details>
<summary>Hint 4</summary>
Generate a new certificate with a valid expiration date and update the secret.
</details>

## Cleanup

```bash
./teardown.sh
```

## Production Parallels

This scenario mirrors:
- Certificate expiration in production (Let's Encrypt, internal CA)
- Lack of certificate expiration monitoring
- Missing alerts for certificates expiring soon
- Manual certificate renewal processes
- Forgotten certificate rotation procedures
