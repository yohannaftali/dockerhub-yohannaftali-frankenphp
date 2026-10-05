# AGENTS.md

> **READ THIS FIRST.** Every AI agent working in this repository (Claude, Gemini, Copilot,
> Cursor, ...) must read this file before doing anything else. It is the single source of
> truth for what this project is and how to work on it. After any structural change
> (new file, new workflow, new tag, changed secret), update this file in the same change.
>
> **Compaction rule:** keep this file describing the *current* state. Put dated history in
> [`CHANGE_HISTORY.md`](CHANGE_HISTORY.md).

## Repository

- remote: https://github.com/yohannaftali/dockerhub-yohannaftali-frankenphp
- platform: GitHub (use the `gh` CLI; it is already authenticated on the maintainer's machine)
- default branch: `main`
- Docker Hub image: `yohannaftali/frankenphp` (https://hub.docker.com/r/yohannaftali/frankenphp)

## Big Picture

A tiny repo that builds and publishes a [FrankenPHP](https://frankenphp.dev/) image (PHP 8.3,
Debian bookworm) with common extensions, Composer 2.2 and sendmail. There is no application code:
the product is the Docker Hub image and its listing.

```
Dockerfile ──► GitHub Actions (amd64+arm64) ──► Docker Hub yohannaftali/frankenphp
README.md  ──► peter-evans/dockerhub-description / scripts/dockerhub-update.sh ──► Hub overview
```

## Repository Layout

```
Dockerfile                       # FROM dunglas/frankenphp:${FRANKEN_PHP_VERSION}-php${PHP_VERSION}-${OS}
Caddyfile, php.ini               # EXAMPLES ONLY, not copied into the image (users mount them)
README.md                        # human docs AND the Docker Hub overview (synced as-is)
AGENTS.md / CHANGE_HISTORY.md    # agent guide / dated history
CLAUDE.md                        # points agents at this file
.env.example                     # variable names only; real .env is git-ignored
.github/workflows/docker-publish.yml   # build+push, then description sync
scripts/dockerhub_update.py      # Docker Hub API helper (stdlib only, run via uv)
scripts/dockerhub-update.sh|.ps1 # bash / PowerShell wrappers around `uv run`
.claude/skills/                  # planner, coder, tester, reviewer (see below)
```

## Key Facts

- **Tags**: only `latest` (`dunglas/frankenphp:builder-php8.3-bookworm`). Build args:
  `PHP_VERSION=8.3`, `FRANKEN_PHP_VERSION=builder`, `OS=bookworm`.
- **The base tag must stay a moving, maintained tag.** The old default `latest-builder` has been
  frozen upstream since 2024-05-13 (FrankenPHP 1.1.5, PHP 8.3.7). Upstream publishes `builder-phpX.Y-<os>`
  (verify with the Hub tags API before changing). Do not go back to `latest-builder`.
- The workflow runs on push to `main`, weekly (Mon 03:00 UTC) and manually. The `description` job
  syncs `README.md` to Docker Hub after the build passes.
- **Secrets** (GitHub repo secrets): `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` (Docker Hub PAT,
  scope *Read, Write, Delete*; description updates need Delete scope).
- **Categories cannot be set via the Docker Hub API** (it silently ignores them). They are set
  by hand in the web UI. Not set yet.
- `README.md` is published verbatim as the Hub overview: keep it self-contained, no
  repo-relative links that only work on GitHub.

## Conventions & Guardrails

- Never commit `.env` or any token. `.env.example` holds names and placeholders only.
- Never print tokens in output, logs or commit messages. Refer to them as `$TOKEN`.
- **The image runs as root and must.** `ARG USER` is declared before `FROM`, so `USER ${USER}` expands
  to nothing (BuildKit warns `UndefinedVar`). "Fixing" it breaks the build (later `apt-get` and `ln`
  steps need root) and the entrypoint (sendmail, `/etc/hosts`), and `--user www-data` was verified not
  to work. Leave it, and keep README's "Runs as root" note accurate.
- PHP `date.timezone` is deliberately **not** set (stays UTC, decided 2026-10-05: keep PHP
  datetime-agnostic). `TZ=Asia/Jakarta` only affects the OS clock. Do not add `date.timezone`
  without asking.
- Composer is `composer:lts` (2.2.x).
- Keep the Dockerfile close to the upstream image; do not fork its entrypoint.
- Python scripts are stdlib-only and run through `uv`; bash and PowerShell wrappers stay thin and
  behave identically.
- Commit message ends with the attribution trailer configured for the session.
- Pushing to `main` publishes images to Docker Hub. Treat it as a release.

## Validation (before pushing)

```bash
docker build -t franken-test .
docker run --rm franken-test frankenphp version          # 1.x, PHP 8.3.x
docker run --rm franken-test date +%Z                    # WIB (OS)
docker run --rm franken-test php -r 'echo date_default_timezone_get();'   # UTC (by design)
docker run --rm franken-test composer --version          # 2.2.x
uv run scripts/dockerhub_update.py status                # needs .env; read-only
```

Also serve one real request (default site is `https://localhost`, use `curl -k`); the `tester`
skill has the full procedure. Note that a local `docker build` reuses a cached base: use
`docker build --pull` to test against the current upstream tag.

## Agent Skills (`.claude/skills/`)

Adapted from the sibling Docker Hub repos (no issue-tracker UI, no browser).

- **`planner`**: create/track GitHub issues with `gh`; keeps the Tracked Issues table current.
- **`coder`**: implements an issue (Dockerfile, workflow, scripts, README) per these rules.
- **`tester`**: builds the image locally, serves a request, and only then opens/merges a PR.
- **`reviewer`**: post-merge audit of what landed on `main` and on Docker Hub.

Flow: `planner` -> `coder` -> `tester` -> `reviewer`.

## Tracked Issues

| ID | Title | Status | Last Checked |
|----|-------|--------|--------------|

## Change Log Policy

- `AGENTS.md`: current architecture and rules only.
- `CHANGE_HISTORY.md`: one dated entry per notable change, newest first.
- Any agent making a structural change updates both files in the same change.
