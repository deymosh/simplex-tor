# 🧅 SimpleX Chat Node (Tor-Only)

This repository contains a self-hosted architecture to deploy a **SimpleX SMP** (messaging) and **SimpleX XFTP** (encrypted file transfer) server operating exclusively over the **Tor (Onion v3)** network. 

The deployment is fully optimized to run without root privileges (`rootless`) and features a smart controller script that automates cryptographic key generation and environment self-healing.

---

## 🛠️ Prerequisites

* **Operating System:** Linux (Ubuntu / Debian recommended).
* **Engine:** Docker and Docker Compose installed.

---

## 🚀 Management Architecture: The `simplex` Script

Instead of interacting directly with `docker compose`, the entire stack is managed via the unified `./simplex` script. This orchestrator handles:

1. **Environment Initialization:** Automatically creates a clean `.env` file from `.env.example` if it is missing.
2. **Native File Permissions:** Secures all data directories by dynamically injecting your current host `UID` and `GID` into the containers, preventing ownership and permission conflicts.
3. **Official Cryptography:** Uses an ephemeral Tor container to generate genuine, network-compliant Onion v3 hidden service addresses natively, ensuring perfect compatibility with the Tor network.
4. **Validation & Self-Healing:** If the `.env` file gets out of sync or its variables do not match the real keys stored on disk, the script uses `sed` to automatically rewrite the configuration to reflect reality.

---

## 📦 Deployment in 2 Steps

### 1. Grant execution permissions
Make sure the main control script has the correct execution flags on your host machine:

```bash
chmod +x simplex
```

### 2. Boot the environment
Simply run the script without parameters. It will automatically validate your directories, generate your hidden service keys natively using the official Tor binary, configure the variables, and spin up the containers:

```bash
./simplex
```

---

## ⚙️ Control Commands

The script acts as a transparent wrapper for Docker Compose. You can pass any standard compose command through it:

* **Check container status:** `./simplex ps`
* **View real-time logs:** `./simplex logs -f`
* **Stop the node:** `./simplex down`
* **Restart the environment:** `./simplex restart`

### 🔗 Retrieve Connection URLs
Once the node has booted for the first time and generated its server cryptographic fingerprints, you can extract the exact invitation links ready to copy-paste into your SimpleX Chat app by running:

```bash
./simplex info
```

*(It also responds to the alias `./simplex urls`)*