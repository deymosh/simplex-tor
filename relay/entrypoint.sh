#!/usr/bin/env bash
# Entrypoint for the SimpleX chat relay, adapted from the official
# scripts/relay/entrypoint.py for a Tor-only, file-storage deployment:
# - all traffic goes through the Tor SOCKS proxy of the simplex-tor container
#   (we share its network namespace, hence 127.0.0.1:9050)
# - the relay address is created on our own SMP onion server
#   (RELAY_SMP_SERVER, e.g. smp://<fingerprint>@<onion>.onion)
# - on first start, a one-shot run captures the relay address to
#   /data/relay-address.txt (same capture logic as the official entrypoint)
set -euo pipefail

: "${RELAY_NAME:?RELAY_NAME is required (set it in .env)}"

SOCKS_PROXY="${SOCKS_PROXY:-127.0.0.1:9050}"
DB="/data/relay.db"
ADDRESS_FILE="/data/relay-address.txt"

mkdir -p /data

# Route everything through Tor
TOR_ARGS=(
    --socks-proxy "$SOCKS_PROXY"
    --socks-mode always
    --host-mode onion
)

if [ ! -s "$ADDRESS_FILE" ]; then
    if [ -z "${RELAY_SMP_SERVER:-}" ]; then
        echo "entrypoint: RELAY_SMP_SERVER is required to create the relay address." >&2
        echo "entrypoint: it is set automatically by ./simplex once the SMP fingerprint exists." >&2
        exit 1
    fi

    echo "entrypoint: relay address not found, creating it on ${RELAY_SMP_SERVER} (may take a couple of minutes over Tor)..."
    ONE_SHOT=(
        --relay --headless
        --user-display-name "$RELAY_NAME"
        --relay-address-server "$RELAY_SMP_SERVER"
        "${TOR_ARGS[@]}"
        -d "$DB"
        -t 0 -e /sa
    )
    OUTPUT=$(timeout 180 simplex-chat-relay "${ONE_SHOT[@]}" 2>&1 || true)
    echo "$OUTPUT"
    ADDRESS=$(echo "$OUTPUT" | grep -oE 'https://[^[:space:]]+|simplex:[^[:space:]]+' | head -n 1 || true)
    if [ -n "$ADDRESS" ]; then
        printf '%s\n' "$ADDRESS" > "$ADDRESS_FILE"
        echo "entrypoint: relay address captured: $ADDRESS"
    else
        echo "entrypoint: relay address not captured; will retry next start" >&2
    fi
else
    echo "entrypoint: relay address: $(cat "$ADDRESS_FILE")"
fi

exec simplex-chat-relay --relay --headless --user-display-name "$RELAY_NAME" "${TOR_ARGS[@]}" -d "$DB"
