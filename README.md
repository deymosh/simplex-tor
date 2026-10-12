# 🧅 SimpleX Chat Node (Tor-Only)

This repository contains a self-hosted architecture to deploy a **SimpleX SMP** (messaging) and **SimpleX XFTP** (encrypted file transfer) server, plus a **SimpleX chat relay** (channel delivery), operating exclusively over the **Tor (Onion v3)** network. 

The deployment is fully optimized to run without root privileges (`rootless`) and features a smart controller script that automates cryptographic key generation and environment self-healing.

---

## 🛠️ Prerequisites

* **Operating System:** Linux (Ubuntu / Debian recommended), or Windows via Git Bash with Docker Desktop.
* **Engine:** Docker and Docker Compose installed.

On Linux, Tor runs as the invoking user, who owns `./data/tor`. On Docker Desktop (Git Bash), where bind mounts always appear root-owned inside containers, the `./simplex` script hands `./data/tor` to the image's unprivileged `toruser` (uid 1000) so Tor can still run without root.

---

## 🚀 Management Architecture: The `simplex` Script

Instead of interacting directly with `docker compose`, the entire stack is managed via the unified `./simplex` script. This orchestrator handles:

1. **Environment Initialization:** Automatically creates a clean `.env` file from `.env.example` if it is missing.
2. **Native File Permissions:** Secures all data directories by dynamically injecting your current host `UID` and `GID` into the containers, preventing ownership and permission conflicts.
3. **Official Cryptography:** Uses an ephemeral Tor container to generate genuine, network-compliant Onion v3 hidden service addresses natively, ensuring perfect compatibility with the Tor network.
4. **Validation & Self-Healing:** If the `.env` file gets out of sync or its variables do not match the real keys stored on disk, the script uses `sed` to automatically rewrite the configuration to reflect reality.
5. **Chat Relay Bootstrapping:** The script waits for the SMP server fingerprint on first boot and automatically points the chat relay's address at your own SMP onion (`RELAY_SMP_SERVER` in `.env`).

## 🗂️ Repository Layout

```
.
├── simplex              # Management script (entrypoint)
├── docker-compose.yml   # Stack definition (tor + smp + xftp + relay)
├── tor/
│   └── torrc            # Tor configuration (SOCKS proxy + onion services)
├── relay/
│   ├── Dockerfile       # Chat relay image (official simplex-chat CLI, relay mode)
│   └── entrypoint.sh    # Address capture + Tor-only relay startup
└── data/                # Runtime state (keys, databases, relay address) - gitignored
```

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

### 📡 The Chat Relay
The stack includes a [chat relay](https://simplex.chat/docs/chat-relay.html) — the SimpleX Chat CLI running in `--relay --headless` mode. It is a normal SimpleX *client*: it has **no inbound ports and no onion service of its own**. Instead, it connects outbound to SMP servers exclusively through the Tor SOCKS proxy of the `simplex-tor` container (it shares that container's network namespace), and its relay address is created on **your own SMP onion server**.

Notes:

* Set the relay's display name via `RELAY_NAME` in `.env` (shown to channel members).
* `RELAY_SMP_SERVER` is managed automatically by `./simplex` — do not set it manually.
* The first relay start builds the image (downloads the official prebuilt `simplex-chat` binary) and then creates the relay address, which can take a couple of minutes over Tor.
* The relay address is captured to `data/relay-address.txt` and shown by `./simplex info`. In the app, use *Add relay* with that link so channel members can route delivery through your relay.

---

## 📚 References & Credits

This project relies on the following technologies and standards:

* **[SimpleX](https://simplex.chat/):** The core messaging protocol and architecture for private, decentralized communication.
* **[SimpleX App](https://github.com/simplex-chat/simplex-chat):** Official client repository.
* **[SimpleX Server](https://github.com/simplex-chat/simplexmq):** Official server (SMP/XFTP) implementation.
* **[Chat Relay guide](https://simplex.chat/docs/chat-relay.html):** Official chat relay hosting documentation.
* **[Tor Project](https://www.torproject.org/):** The underlying anonymity network that enables hidden services, ensuring location privacy for the node.
* **[deymosh/tor](https://github.com/deymosh/tor):** The maintained Tor container image used by this stack (published on `ghcr.io`, drop-in replacement for the unmaintained `lncm/tor`).