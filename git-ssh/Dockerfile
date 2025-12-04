# Debian 12.12
FROM debian:bookworm-20251117-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
