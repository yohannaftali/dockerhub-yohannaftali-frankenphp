# yohannaftali/frankenphp

[![Docker Pulls](https://img.shields.io/docker/pulls/yohannaftali/frankenphp)](https://hub.docker.com/r/yohannaftali/frankenphp)
[![Docker Image Size](https://img.shields.io/docker/image-size/yohannaftali/frankenphp/latest)](https://hub.docker.com/r/yohannaftali/frankenphp)

[FrankenPHP](https://frankenphp.dev/) (a modern PHP app server built on Caddy) with PHP 8.3, common extensions, Composer and sendmail. The container clock is set to **Asia/Jakarta (WIB, UTC+7)**; PHP itself stays on UTC (see Overview).

- Docker Hub: <https://hub.docker.com/r/yohannaftali/frankenphp>
- Source code (Dockerfile, build workflow, scripts): <https://github.com/yohannaftali/dockerhub-yohannaftali-frankenphp>
- Issues and feature requests: <https://github.com/yohannaftali/dockerhub-yohannaftali-frankenphp/issues>

## Use this image

No build needed. Pull the prebuilt image straight from Docker Hub:

```bash
docker pull yohannaftali/frankenphp
```

Or reference it in your `docker-compose.yml`:

```yaml
services:
  app:
    image: yohannaftali/frankenphp:latest
```

## Overview

Built `FROM dunglas/frankenphp:builder-php8.3-bookworm` (Debian 12) and adds:

- **Timezone**: `TZ=Asia/Jakarta` for the operating system (`date`, logs, cron). PHP's `date.timezone` is intentionally left at its default, UTC, so applications stay timezone-agnostic. Set `date_default_timezone_set()` or `date.timezone` yourself if you need local time.
- **Extensions**: `bcmath`, `exif`, `gd`, `intl`, `mbstring`, `mysqli`, `opcache`, `pcntl`, `pdo`, `pdo_mysql`, `soap`, `zip`.
- **Composer 2.2** (the `composer:lts` image) at `/usr/local/bin/composer`.
- **Mail**: `sendmail` configured as `sendmail_path`; the entrypoint restarts it on container start.
- **Hosts entry**: the entrypoint appends the container's IP and hostname to `/etc/hosts` (needed by sendmail).
- **Tools**: `nano`, `wget`, `curl`, `zip`, `unzip`, `libnss3-tools`, and `jpegoptim`, `optipng`, `pngquant`, `gifsicle`.
- `WORKDIR /app`: put your app there, with the public entry point in `/app/public`.

Everything else (entrypoint, Caddy, ports 80/443) behaves like the upstream image; see the [FrankenPHP docs](https://frankenphp.dev/docs/).

### Things to know

- **Runs as root, and needs to.** The Dockerfile contains a `USER` step, but its build argument is out of scope there and expands to nothing, so the image runs as root, as it always has. Running it as another user (for example `--user www-data`) is **not supported**: the entrypoint starts sendmail and edits `/etc/hosts`, which need root, and the container then fails to serve. Use the upstream `dunglas/frankenphp` image if you need a non-root setup.
- **Default site.** The default Caddyfile serves `/app/public` as `https://localhost` with an automatic local certificate; plain HTTP on port 80 only redirects. Set `SERVER_NAME` (for example `SERVER_NAME=:80`) or mount your own Caddyfile for other setups.
- **`Caddyfile` and `php.ini` in the repository are examples only.** They are **not** copied into the image. Mount them if you want them: `-v ./Caddyfile:/etc/caddy/Caddyfile` and `-v ./php.ini:/usr/local/etc/php/php.ini`. The example Caddyfile runs worker mode for `public/index.php` with 32 threads.
- **Moving base tag.** The base is the upstream `builder` tag, which follows the newest FrankenPHP release (currently 1.13, PHP 8.3.x), so the weekly rebuild picks up upstream updates.

## Tags

| Tag | Base image |
| --- | --- |
| `latest` | `dunglas/frankenphp:builder-php8.3-bookworm` |

## Quick start

```bash
mkdir -p app/public && echo '<?php echo "Hello from PHP ".PHP_VERSION;' > app/public/index.php
docker run -d --name frankenphp -p 443:443 -v "$PWD/app:/app" yohannaftali/frankenphp:latest
curl -k https://localhost/
```

### docker-compose

```yaml
services:
  app:
    image: yohannaftali/frankenphp:latest
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./app:/app
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
```

Verify the image:

```bash
docker run --rm yohannaftali/frankenphp frankenphp version
docker run --rm yohannaftali/frankenphp date +%Z                                   # WIB (OS)
docker run --rm yohannaftali/frankenphp php -r 'echo date_default_timezone_get();'  # UTC (by design)
docker run --rm yohannaftali/frankenphp composer --version
```

## Build (maintainers)

```bash
docker login

docker build -t yohannaftali/frankenphp:latest .
docker push yohannaftali/frankenphp:latest
```

Build arguments: `PHP_VERSION` (default `8.3`), `FRANKEN_PHP_VERSION` (default `builder`), `OS` (default `bookworm`).

Multi-arch (amd64 + arm64):

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t yohannaftali/frankenphp:latest --push .
```

## Automated publishing

`.github/workflows/docker-publish.yml` builds and pushes the image on every push to `main`, weekly, and on manual dispatch. It also syncs this README to the Docker Hub **overview** and the short **description**.

Required GitHub repository secrets:

| Secret | Value |
| --- | --- |
| `DOCKERHUB_USERNAME` | `yohannaftali` |
| `DOCKERHUB_TOKEN` | Docker Hub access token with *Read, Write, Delete* scope |

## Maintaining the Docker Hub repository

- **Overview**: synced from this `README.md` by the workflow.
- **Short description**: set in the workflow (`short-description`), max 100 characters.
- **Manual sync / status**: see [Maintenance scripts](#maintenance-scripts).
- **Category**: not exposed through the API; set manually in *Repository → Settings → Categories*.

## Maintenance scripts

Helper scripts in `scripts/` manage the Docker Hub repository from your machine. They need [uv](https://docs.astral.sh/uv/) and a `.env` file (copy `.env.example`) with `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`. There are no other dependencies.

| Command | Action |
| --- | --- |
| *(none)* / `sync` | Push `README.md` as the overview and set the short description |
| `status` | Show description, categories, pull and star counts |
| `tags` | List tags with last update and size |
| `delete-tag <tag>` | Delete a tag |

Bash:

```bash
./scripts/dockerhub-update.sh            # sync
./scripts/dockerhub-update.sh status
./scripts/dockerhub-update.sh tags
```

PowerShell:

```powershell
.\scripts\dockerhub-update.ps1            # sync
.\scripts\dockerhub-update.ps1 status
.\scripts\dockerhub-update.ps1 tags
```

Both wrappers call `scripts/dockerhub_update.py` through `uv run`. Set `DOCKERHUB_REPO` to target a repository other than `frankenphp`.

## Source and contributing

The Dockerfile, GitHub Actions workflow and maintenance scripts live at <https://github.com/yohannaftali/dockerhub-yohannaftali-frankenphp>. Open an issue there to report a problem.

## License

The Dockerfile in this repository is provided as-is. FrankenPHP is licensed under the MIT license and PHP under the PHP License; see the [upstream image](https://hub.docker.com/r/dunglas/frankenphp) for details.
