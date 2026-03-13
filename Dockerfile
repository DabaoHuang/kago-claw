FROM node:22-bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    curl \
    bash \
    jq \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install official OpenClaw CLI globally.
RUN npm install -g openclaw@latest

RUN useradd --create-home --uid 10001 --shell /usr/sbin/nologin lobster

WORKDIR /workspace
RUN chown -R 10001:10001 /workspace

USER 10001:10001
ENV HOME=/workspace/.home

CMD ["tail", "-f", "/dev/null"]
