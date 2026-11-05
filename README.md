# Paradev (Superset) cloud host on Railway

Runs the Paradev/Superset host server (`superset start`) in a Railway container. It registers
with the Superset relay, so your local desktop app can pick it as a remote host and run
workspaces, terminals and agents on it. No inbound ports or public domain needed.

## Variables

| Variable | Required | Purpose |
|---|---|---|
| `SUPERSET_API_KEY` | yes | API key from the desktop app: Settings -> API Keys |
| `SUPERSET_ORG` | if you have several orgs | Org id, slug or name the host registers under |
| `GH_TOKEN` | recommended | GitHub token (repo scope) so `gh`/`git` can clone private repos and open PRs |
| `ANTHROPIC_API_KEY` | optional | For Claude Code on the host |
| `OPENAI_API_KEY` | optional | For Codex on the host |
| `GIT_USER_NAME` / `GIT_USER_EMAIL` | optional | Git identity for commits made on the host |

## Volume

Mount a volume at `/data`. `HOME` is `/data/home`, so Paradev state, git/gh config, repo
clones and worktrees persist across redeploys.

## Use it

1. Deploy, then check the deploy logs for "Starting host server".
2. In the desktop app: Settings -> Hosts, or the workspaces Device filter -> pick the host.
3. Create workspaces on it from the app, or with the CLI: `superset projects create`, `superset workspaces create`.

## Caveats

- Remote workspaces require a Pro plan on the Superset side.
- Ports listening on the host are not forwarded to your machine; use SSH or Tailscale for that.
- A redeploy or restart interrupts running terminals and agents.
- Anything reachable by the host (files, terminals, agent runs) is reachable by members you
  grant access to, so keep the host's secrets scoped (use a fine-grained `GH_TOKEN`).