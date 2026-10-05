# CHANGE_HISTORY.md

Newest first. One dated entry per notable change.

## [2026-10-05] — fix + chore: move off the frozen base tag, apply the shared repo setup
- **Base tag fix**: `FRANKEN_PHP_VERSION` default changed from `latest-builder` to `builder`. The `latest-builder-php8.3-bookworm` tag has been frozen upstream since 2024-05-13 (FrankenPHP 1.1.5, Caddy 2.7.6, PHP 8.3.7), so the "rebuilt weekly" image never received updates. `builder-php8.3-bookworm` is current (FrankenPHP 1.13.0, Caddy 2.11.7, PHP 8.3.35 at the time of the change). Verified locally: build, extensions, WIB OS clock, PHP on UTC, Composer 2.2.x, and an HTTPS request served from `/app/public`. This is a large version jump for users of `latest`.
- **Documented, not changed**: the image runs as root because `ARG USER` is declared before `FROM` (out of scope after it), so `USER ${USER}` is empty. Verified that `--user www-data` does not work (entrypoint needs root for sendmail and `/etc/hosts`). `Caddyfile` and `php.ini` are not copied into the image; documented as examples to mount.
- PHP `date.timezone` kept at the default UTC on purpose; only the OS clock uses `TZ=Asia/Jakarta`.
- `Dockerfile`: OCI labels, trailing-whitespace cleanup after line continuations, trailing newline.
- `.github/workflows/docker-publish.yml`: single tag `latest`, amd64+arm64, weekly + on push + manual, then syncs README to the Hub overview. Rebuilds `latest`, last pushed 2025-02-24.
- `readme.md` renamed to `README.md` (case-sensitive path in the workflow) and rewritten.
- Added `scripts/`, `.env.example`, `.gitignore`, `CLAUDE.md`, `AGENTS.md` and `.claude/skills/` adapted from the sibling repos.
- Docker Hub category still to be set manually in the web UI.

## Earlier
- 2025-02-24: published `yohannaftali/frankenphp:latest`.
- Initial Dockerfile on `dunglas/frankenphp:latest-builder-php8.3-bookworm`, with `Caddyfile` and `php.ini` examples.
