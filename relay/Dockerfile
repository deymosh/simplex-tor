# SimpleX chat relay: the official simplex-chat CLI running in relay mode.
#
# The official helper scripts (https://github.com/simplex-chat/simplex-chat/tree/stable/scripts/relay)
# build the binary from source with cabal (~30 min). This image instead uses the
# prebuilt release binary, which supports relay mode with file storage (-d), and
# keeps the same runtime contract: /usr/local/bin/simplex-chat-relay + an
# entrypoint that captures the relay address to /data/relay-address.txt.
ARG CHAT_VERSION=v7.0.4
FROM ubuntu:24.04
ARG CHAT_VERSION
ARG TARGETARCH

RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) ASSET_ARCH=x86_64 ;; \
        arm64) ASSET_ARCH=aarch64 ;; \
        *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl libtinfo6; \
    rm -rf /var/lib/apt/lists/*; \
    curl -fsSL -o /usr/local/bin/simplex-chat-relay \
        "https://github.com/simplex-chat/simplex-chat/releases/download/${CHAT_VERSION}/simplex-chat-ubuntu-24_04-${ASSET_ARCH}"; \
    chmod 0755 /usr/local/bin/simplex-chat-relay

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

# The relay shuts down cleanly on SIGINT, not SIGTERM (same as the official image)
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
