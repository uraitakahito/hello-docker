# Debian 12.14
FROM debian:bookworm-20260610-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git openssh-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
