FROM node:24-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# System dependencies (tmux INCLUDED)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git \
      tmux \
      ca-certificates \
      curl \
      bash \
    && rm -rf /var/lib/apt/lists/*

# Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user
RUN useradd -m -s /bin/bash claude

# Prepare dirs
RUN mkdir -p /home/claude/.claude /workspace && \
    chown -R claude:claude /home/claude /workspace

COPY tmux.conf /home/claude/.tmux.conf
COPY claude-settings.json /home/claude/.claude/settings.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chown claude:claude /home/claude/.claude/settings.json

USER claude
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
