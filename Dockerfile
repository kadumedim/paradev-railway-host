FROM node:22-bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive
# Set to "false" to skip installing agent CLIs (smaller/faster image)
ARG INSTALL_AGENTS=true

# Base tooling: git + gh are required by the host server. gosu lets the entrypoint
# fix volume ownership as root and then drop to an unprivileged user.
RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl ca-certificates openssh-client gnupg procps gosu tini unzip jq ripgrep \
    && mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
         -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
         > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Optional agent CLIs. The host server launches whichever are on PATH.
RUN if [ "$INSTALL_AGENTS" = "true" ]; then \
      npm install -g @anthropic-ai/claude-code @openai/codex; \
    fi

# Install the Paradev/Superset CLI into /opt (not $HOME) so the persistent
# volume mounted over $HOME at runtime doesn't hide the binary.
# The installer puts files under $HOME/superset, so point HOME at /opt/cli for this step.
RUN mkdir -p /opt/cli \
    && HOME=/opt/cli sh -c 'curl -fsSL https://paradev.com/cli/install.sh | sh' \
    && ls -la /opt/cli/superset/bin
ENV PATH="/opt/cli/superset/bin:${PATH}"

# Unprivileged runtime user (agent CLIs refuse some modes when run as root)
RUN useradd -m -u 1001 -s /bin/bash dev

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Railway volume mount point. HOME lives here so auth, git config, clones and
# worktrees survive redeploys.
ENV DATA_DIR=/data
ENV HOME=/data/home

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/start.sh"]