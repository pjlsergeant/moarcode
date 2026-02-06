FROM node:20

# Full tool suite for AI agents
RUN apt-get update && apt-get install -y --no-install-recommends \
    less \
    git \
    procps \
    sudo \
    fzf \
    zsh \
    unzip \
    jq \
    nano \
    vim \
    ripgrep \
    iptables \
    gosu \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Firewall script for network sandboxing (optional)
COPY init-firewall.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-firewall.sh && \
    echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
    chmod 0440 /etc/sudoers.d/node-firewall

# CRITICAL: Helps Claude skip interactive prompts
ENV DEVCONTAINER=true
ENV COLORTERM=truecolor

# Directory setup
RUN mkdir -p /workspace /home/node/.claude /home/node/.codex /usr/local/share/npm-global && \
    chown -R node:node /workspace /home/node/.claude /home/node/.codex /usr/local/share/npm-global

WORKDIR /workspace

# npm global path
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin
ENV CLAUDE_CONFIG_DIR=/home/node/.claude

USER node

# CRITICAL: Both AI tools installed
RUN npm install -g @anthropic-ai/claude-code @openai/codex

# Git config for commits
RUN git config --global --add safe.directory /workspace \
    && git config --global user.email "ai@localhost" \
    && git config --global user.name "AI Developer"

USER root
COPY container-entrypoint.sh /usr/local/bin/dev-entrypoint.sh
RUN chmod +x /usr/local/bin/dev-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dev-entrypoint.sh"]
