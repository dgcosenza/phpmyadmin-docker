# phpMyAdmin on Debian 13 (trixie) — Hardened Container Image

[![CI](https://github.com/dgcosenza/phpmyadmin-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/phpmyadmin-docker/actions/workflows/daily.yml)
[![Docker Hub Pulls](https://img.shields.io/docker/pulls/dgcosenza/phpmyadmin?label=docker%20pulls)](https://hub.docker.com/r/dgcosenza/phpmyadmin)
[![Image Size](https://img.shields.io/docker/image-size/dgcosenza/phpmyadmin/latest?label=image%20size)](https://hub.docker.com/r/dgcosenza/phpmyadmin)
[![License](https://img.shields.io/github/license/dgcosenza/phpmyadmin-docker)](LICENSE)

A hardened, continuously rebuilt **phpMyAdmin** container image on **Debian 13 (`trixie`)** with **PHP 8.3** and Apache, built from the official SHA-256 and GPG-verified upstream release tarball with Composer vendor dependencies refreshed daily to eliminate fixable CVEs.

Maintained by **Daniel G. Cosenza from FNX Labs**.

## Current Versions

<!-- versions:start -->
_Last verified build: **2026-11-24** (UTC)_

| Component | Resolved Version |
|-----------|------------------|
| phpMyAdmin | `5.2.3` (GPG-verified + Composer security-patched) |
| PHP + Apache | `php:8.3.37-apache-trixie` |
| Base OS | Debian `13` (`trixie`) |
| Fixable Critical/High (Trivy / Grype) | `0` / `0` |

**Recent upstream updates:**
- Initial hardened Debian 13 release for phpMyAdmin 5.2.3 with patched Twig and Symfony vendor packages.
<!-- versions:end -->

## Supported Tags

| Tag | Description |
|-----|-------------|
| `latest` | Moving tag tracking the newest verified daily phpMyAdmin build |
| `<version>` | Latest build for a specific upstream release (e.g. `5.2.3`) |
| `<version>-YYYYMMDD` | Immutable date-stamped build (e.g. `5.2.3-20261124`) |
| `sha-<short>` | Immutable commit-stamped build |

## Quick Start

### Docker CLI

```bash
docker run -d --name phpmyadmin \
  --security-opt no-new-privileges:true \
  -e PMA_HOST=db \
  -e PMA_ARBITRARY=0 \
  -p 127.0.0.1:8080:80 \
  dgcosenza/phpmyadmin:latest
```

### Docker Compose

```yaml
services:
  phpmyadmin:
    image: dgcosenza/phpmyadmin:latest
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    environment:
      - PMA_HOST=db
      - PMA_ARBITRARY=0
    volumes:
      - ./config.user.inc.php:/etc/phpmyadmin/config.user.inc.php:ro
    ports:
      - "127.0.0.1:8080:80"
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://127.0.0.1:80/ >/dev/null || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

See [docker-compose.example.yml](docker-compose.example.yml) for a full example.

## Configuration

### Environment Variables

Full drop-in parity with the official `phpmyadmin` Docker image:

| Variable | Description | Default |
|----------|-------------|---------|
| `PMA_HOST` | Hostname or IP of the MySQL/MariaDB server (`*_FILE` supported) | — |
| `PMA_HOSTS` | Comma-separated list of database hosts (`*_FILE` supported) | — |
| `PMA_PORT` | Database server port | `3306` |
| `PMA_ARBITRARY` | Set to `1` to allow entering an arbitrary server at login | `0` |
| `PMA_USER` / `PMA_PASSWORD` | Fixed login credentials (`*_FILE` supported) | — |
| `PMA_ABSOLUTE_URI` | Public URL when running behind a reverse proxy | — |
| `UPLOAD_LIMIT` | PHP `upload_max_filesize` and `post_max_size` | `2048K` |
| `MEMORY_LIMIT` | PHP memory limit | `512M` |
| `MAX_EXECUTION_TIME` | PHP script timeout in seconds | `600` |
| `TZ` | PHP `date.timezone` | `UTC` |
| `APACHE_PORT` | Override Apache listen port | `80` |
| `PMA_CONFIG_BASE64` / `PMA_USER_CONFIG_BASE64` | Base64-encoded config overrides | — |

### Volumes & Config Paths

| Path | Purpose |
|------|---------|
| `/etc/phpmyadmin/config.user.inc.php` | Custom PHP configuration overrides (mount `:ro` to persist across recreates) |
| `/sessions` | PHP session storage (mode `1777`, owned by `www-data:www-data`) |
| `/etc/phpmyadmin/ssl` | TLS CA/client certificates for encrypted DB connections |

### Ports

- `80/tcp` — Apache HTTP server (bind to `127.0.0.1` or an internal network behind a reverse proxy).

### User, UID, and GID

- Apache starts as `root` solely to bind privileged port `80` (compatible with `security_opt: [no-new-privileges:true]` and drop-in parity with official `phpmyadmin`) and immediately spawns worker processes as non-root `www-data` (**UID 33 / GID 33**).
- Web root `/var/www/html` is mounted read-only (`555` directories / `444` files) except `/var/www/html/tmp` (`1777`).

### Healthcheck

```bash
curl -fsS http://127.0.0.1:80/
```

## Upgrade and Migration from Upstream `phpmyadmin`

This image is a direct drop-in replacement for `phpmyadmin:latest`:

1. Keep your existing `/etc/phpmyadmin/config.user.inc.php` mount and `PMA_*` environment variables unchanged.
2. Tag the outgoing image locally for rollback before switching.
3. Replace `image: phpmyadmin:latest` with `image: dgcosenza/phpmyadmin:latest` (or a pinned digest `@sha256:...`) and run `docker compose up -d phpmyadmin`.

## Security

- **Trivy** (OS + PHP Composer + JS packages): SARIF uploaded to GitHub Code Scanning; table and JSON reports retained for 90 days; **blocking hard gate** on 0 fixable `CRITICAL`/`HIGH` findings.
- **Grype**: **blocking hard gate** (`only-fixed: true`, severity cutoff `high`); table report retained for 90 days.
- **SBOM & Provenance**: SPDX-JSON SBOM (Syft) and provenance JSON retained for 90 days.
- **Hardening**: `expose_php=Off`, `allow_url_fopen=Off`, `session.cookie_httponly=1`, `session.use_strict_mode=1`, read-only web root, and Composer removed from the final runtime stage.

See [SECURITY.md](SECURITY.md) for private disclosure instructions.

## Build Locally

```bash
docker buildx build --platform linux/amd64 --load \
  --build-arg PHP_VERSION=8.3.37 \
  --build-arg PMA_VERSION=5.2.3 \
  -t dgcosenza/phpmyadmin:local .
```

## Update Policy

Every day at **05:02 UTC** (and on push to `main`, pull requests, or manual dispatch), `.github/workflows/daily.yml` runs a 7-step automated pipeline gated by `.github/scripts/public-check.sh`:

1. **Upstream check:** Queries the authenticated GitHub API (`phpmyadmin/phpmyadmin`) and Docker Hub (`library/php` `8.3.x-apache-trixie`) for new releases, diffs against `versions.json`, and saves `upstream-changes.md` as a 90-day artifact.
2. **Clean rebuild:** Rebuilds on `php:8.3.x-apache-trixie` with `--no-cache` on scheduled runs, upgrades Debian 13 packages, verifies the phpMyAdmin tarball via SHA-256 + GPG (`3D06A59ECE730EB71B511C17CE752F178259BD92`), refreshes production Composer dependencies, and generates SBOM + provenance artifacts.
3. **Vulnerability fix & hard gates:** Runs Trivy (table, JSON, SARIF upload, and blocking 0 fixable `CRITICAL`/`HIGH` gate) and Grype (blocking 0 fixable `CRITICAL`/`HIGH` gate), retaining all reports for 90 days.
4. **Functional smoke test:** Runs `tests/smoke.sh` to verify healthy HTTP 200 startup, clean login UI rendering, custom `config.user.inc.php`, hidden PHP header, non-root `www-data` workers, and negative healthcheck failure.
5. **Registry publish:** Pushes `latest`, `<version>`, `<version>-<YYYYMMDD>`, and `sha-<short>` tags when Docker Hub credentials are configured.
6. **Automated documentation sync:** Updates `versions.json`, the `<!-- versions:start -->` block in `README.md`, and `CHANGELOG.md` via `github-actions[bot]` (`[skip ci]`, checked by `public-check.sh`), then syncs README and short description to Docker Hub.
7. **Failure alerting:** Opens or updates a single GitHub issue labeled `ci-failure` on any `main` or scheduled failure, and auto-closes it on the next green run.

## Design Decisions

- **Base `php:8.3.x-apache-trixie`:** Uses the official Debian 13 (`trixie`) PHP 8.3 Apache image — phpMyAdmin 5.2.x officially supports PHP `<8.4` (`>=7.2,<8.4`), and `php:8.3.x-apache-trixie` provides a minimal, Debian 13-native Apache + PHP stack without stale OS layers.
- **Multi-stage Composer vendor patching:** Official phpMyAdmin tarballs bundle frozen vendor packages (such as Twig 3.11.3 and Symfony 5.4.45/46) that carry Critical and High CVEs. Refreshing production dependencies with `composer update --no-dev` inside a build stage patches those libraries within phpMyAdmin's own `composer.json` constraints while keeping Composer out of the final image.

## License

- Repository build files, scripts, and documentation: **MIT License** — see [LICENSE](LICENSE).
- phpMyAdmin: **GPL-2.0-only** — see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).

## Credits

- [phpMyAdmin Team](https://www.phpmyadmin.net/) and [phpmyadmin/docker](https://github.com/phpmyadmin/docker)
- [Docker Official PHP Images](https://hub.docker.com/_/php)
- [Debian Project](https://www.debian.org/)

Maintained by **Daniel G. Cosenza from FNX Labs**.
