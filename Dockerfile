FROM node:24-bookworm

ENV DEBIAN_FRONTEND=noninteractive
ENV XDG_CONFIG_HOME=/home/claude/.config
ENV CLAUDE_CONFIG_DIR=/home/claude/.config/claude

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
RUN mkdir -p /home/claude/.config/claude /workspace && \
    chown -R claude:claude /home/claude /workspace

COPY tmux.conf /home/claude/.tmux.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER claude
WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
