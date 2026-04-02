<p align="center">
  <img src="docs/img/logo.png" alt="RamOps" width="400">
</p>

## ⚠️ Disclaimer

**FOR EDUCATIONAL USE ONLY.** This project contains simulated security incidents, malware, and system compromises for training purposes. 

- **NEVER** run on production systems
- **NEVER** use on systems you don't own
- Only use in isolated training environments
- See [DISCLAIMER.md](DISCLAIMER.md) for full legal and security warnings

**You are responsible for any consequences of misuse. Unauthorized access to computer systems is illegal.**

---

# Ram Ops 

Incident simulation and training scenarios for Kubernetes and cloud infrastructure teams. Practice responding to outages, security breaches, chaos engineering events, and misconfigurations in a safe environment.

**Note:** VM-based scenarios (Lima) are currently tested on Apple Silicon (ARM) Macs only. Other architectures may require configuration adjustments.

## Quick Start

**Interactive TUI (Recommended):**
```bash
curl -fsSL https://raw.githubusercontent.com/khbarkar/openRam/main/install.sh | bash
ramops
```

Or run directly:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/khbarkar/openRam/main/ramops)
```
## HOW TO 
Pick any scenario and select `Setup`.  
Once completed , press any key and go to `Instructions`.    
If stuck at any time, press any key and go to `Hints`.    
Once done press any key and select `Teardown`.   

## Incidents

See [Github pages](https://khbarkar.github.io/RamOps/) for details

## Releases

Releases are created automatically from pushes to `main` using semantic versioning and Conventional Commits.

- `fix:` creates a patch release (`v1.0.1`)
- `feat:` creates a minor release (`v1.1.0`)
- `feat!:` or any commit with a `BREAKING CHANGE:` footer creates a major release (`v2.0.0`)

Commits that do not match Conventional Commit release types do not create a new tag or GitHub release.

## Getting Started

Each scenario is self-contained with its own setup, verification, and teardown scripts.

**Prerequisites:**
- **Kubernetes scenarios**: [Kind](https://kind.sigs.k8s.io/), [kubectl](https://kubernetes.io/docs/tasks/tools/), Docker
- **VM-based scenarios** (Sysadmin, Observability, Terraform, Deployment):
  - [Lima](https://lima-vm.io/) for lightweight Linux VMs
  - 4GB+ RAM free
- **Kafka scenarios**: [Kind](https://kind.sigs.k8s.io/), [kubectl](https://kubernetes.io/docs/tasks/tools/), Docker


```bash
cd kubernetes/incident-001
./setup.sh      # creates infrastructure and deploys the broken scenario
# ... debug and fix ...
./verify.sh     # checks if your fix works
./teardown.sh   # cleans up everything
```

---

<p align="center">
  <sub>If you find this project helpful, consider <a href="https://www.buymeacoffee.com/khbarkar">buying me a coffee</a> ☕</sub>
</p>
