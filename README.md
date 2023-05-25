# graciani-blog

A minimal, dark-themed personal blog. Rails 8, SQLite, Action Text with the
[Lexxy](https://github.com/basecamp/lexxy) editor, admin gated by GitHub SSO,
deployed with Kamal to a Google Cloud Compute Engine VM.

## Stack

- Rails 8.1, Ruby 3.4.7, SQLite + Solid Queue/Cache/Cable
- Lexxy rich text editor (Action Text), attachments on Cloudflare R2
- Auth: `omniauth-github`, single allow-listed GitHub login (no user table)
- Hosting: GCP `e2-micro` VM (Always Free tier, `us-central1`), Kamal 2
- DNS: Cloudflare (`blog.graciani.ar`)

## Local development

```bash
bin/setup
bin/rails server
```

Visit `http://localhost:3000`. `/admin` requires `GITHUB_CLIENT_ID` /
`GITHUB_CLIENT_SECRET` / `ALLOWED_GITHUB_LOGIN` to be set (see below) — without
them the GitHub sign-in button will fail.

## One-time manual setup

A few things can't be done from the CLI/API and need to happen once, by hand:

1. **GitHub OAuth App** — github.com → Settings → Developer settings → OAuth
   Apps → New OAuth App.
   - Homepage URL: `https://blog.graciani.ar`
   - Authorization callback URL: `https://blog.graciani.ar/auth/github/callback`
   - Copy the Client ID, generate a Client Secret.
2. Provide those as `GH_OAUTH_CLIENT_ID` / `GH_OAUTH_CLIENT_SECRET` repo
   secrets (used by `.github/workflows/deploy.yml`), or as
   `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` env vars for a local deploy.

## Deploying

Deploys run via [Kamal](https://kamal-deploy.org) against the GCP VM at
`35.208.185.229`, configured in `config/deploy.yml`.

### Via GitHub Actions (recommended)

`.github/workflows/deploy.yml` is a manually-triggered (`workflow_dispatch`)
job that builds and deploys on a GitHub-hosted runner — no local Docker
needed. Run it from the Actions tab, or:

```bash
gh workflow run deploy.yml
```

It expects these repository secrets: `DEPLOY_SSH_KEY`, `RAILS_MASTER_KEY`,
`GH_OAUTH_CLIENT_ID`, `GH_OAUTH_CLIENT_SECRET`, `ALLOWED_GITHUB_LOGIN`,
`R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`. `GITHUB_TOKEN` (for pushing to
GHCR) is provided automatically by Actions.

### Locally

Requires Docker and the `write:packages` scope on your `gh` token
(`gh auth refresh -h github.com -s write:packages`):

```bash
export KAMAL_REGISTRY_PASSWORD=$(gh auth token)
export RAILS_MASTER_KEY=$(cat config/master.key)
export GITHUB_CLIENT_ID=... GITHUB_CLIENT_SECRET=... ALLOWED_GITHUB_LOGIN=lautarograc
export R2_ACCESS_KEY_ID=... R2_SECRET_ACCESS_KEY=...
bin/kamal deploy
```

## Infrastructure

Provisioned once via `gcloud` and the Cloudflare API — see the plan/session
history for the exact commands. Summary:

- GCP project `graciani-blog`: one `e2-micro` VM (`graciani-blog-vm`,
  `us-central1-a`) with Docker, a `kamal` deploy user (SSH key + docker
  group), a reserved static IP, firewall rules for 22/80/443.
- Cloudflare: `blog.graciani.ar` A record (DNS-only, not proxied — Kamal's
  built-in Let's Encrypt needs the HTTP-01 challenge to reach the VM
  directly), plus an R2 bucket (`graciani-blog-attachments`) for Active
  Storage.
