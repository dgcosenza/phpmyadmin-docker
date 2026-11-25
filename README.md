# phpMyAdmin on Debian 13 (trixie) — Hardened Container Image

[![Daily phpMyAdmin image](https://github.com/dgcosenza/phpmyadmin-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/phpmyadmin-docker/actions/workflows/daily.yml)
[![Packaging License: MIT](https://img.shields.io/badge/packaging-MIT-blue.svg)](https://github.com/dgcosenza/phpmyadmin-docker/blob/main/LICENSE)
[![Upstream License: GPL-2.0-only](https://img.shields.io/badge/upstream-GPL--2.0--only-green.svg)](https://github.com/phpmyadmin/phpmyadmin/blob/master/LICENSE)
[![Signed with Cosign](https://img.shields.io/badge/signed-cosign%20OIDC-blueviolet.svg)](#supply-chain-verification)
[![SLSA Level 3](https://img.shields.io/badge/SLSA-Level%203-brightgreen.svg)](#supply-chain-verification)
[![Architectures](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-informational.svg)](#supported-architectures)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/dgcosenza/phpmyadmin-docker/badge)](https://scorecard.dev/viewer/?uri=github.com/dgcosenza/phpmyadmin-docker)
[![Docker Pulls](https://img.shields.io/docker/pulls/dgcosenza/phpmyadmin)](https://hub.docker.com/r/dgcosenza/phpmyadmin)
[![Docker Image Size](https://img.shields.io/docker/image-size/dgcosenza/phpmyadmin/latest)](https://hub.docker.com/r/dgcosenza/phpmyadmin)
[![Latest Release](https://img.shields.io/github/v/release/dgcosenza/phpmyadmin-docker?label=version)](https://github.com/dgcosenza/phpmyadmin-docker/releases)

A hardened, multi-arch **phpMyAdmin** container image on **Debian 13 (`trixie`)** with **PHP 8.3** and Apache, built from the official SHA-256 and GPG-verified upstream release tarball with Composer vendor dependencies refreshed daily to eliminate fixable CVEs, maintained by **Daniel G. Cosenza from FNX Labs**.

- **Docker Hub:** [`dgcosenza/phpmyadmin`](https://hub.docker.com/r/dgcosenza/phpmyadmin)
- **GitHub Container Registry (GHCR):** [`ghcr.io/dgcosenza/phpmyadmin`](https://github.com/dgcosenza/phpmyadmin-docker/pkgs/container/phpmyadmin) (identical signed multi-arch digest)
- **Source Repository:** [`dgcosenza/phpmyadmin-docker`](https://github.com/dgcosenza/phpmyadmin-docker)
- **Upstream Application:** [`phpmyadmin/phpmyadmin`](https://github.com/phpmyadmin/phpmyadmin) (`GPL-2.0-only`)

---

## Current Versions

<!-- versions:start -->
| Component | Resolved Version |
| --- | --- |
| phpMyAdmin | `5.2.3 (GPG-verified + Composer security-patched)` |
| PHP + Apache | `php:8.3.37-apache-trixie` |
| Base OS | `Debian 13.8 (trixie)` |
| Architectures | `linux/amd64, linux/arm64` |
| Uncompressed size (per arch) | `amd64: 194.8 MB, arm64: 592.4 MB` |
| Last verified build (UTC) | `2026-11-25` |
| Published multi-arch digest | `dgcosenza/phpmyadmin@sha256:115c9fda322f311914931d0740e4d6cda14e148ee7d40f4c4e0211fb7a324b02` |
| GHCR mirror | `ghcr.io/dgcosenza/phpmyadmin@sha256:115c9fda322f311914931d0740e4d6cda14e148ee7d40f4c4e0211fb7a324b02` |
| Supply chain | Cosign OIDC signed + SPDX & CycloneDX SBOM attestations + SLSA Build L3 provenance |
| Security gate (Trivy + Grype on SBOM) | **0 fixable Critical/High** (48 upstream-unfixed) |

**Recent upstream changes:**
- **phpMyAdmin:** `5.2.3` -> `5.2.3`
- **PHP (Debian 13 Apache):** `8.3.37` -> `8.3.37`
- **Upstream version changed:** `no`
- Official phpMyAdmin 5.2.3 release (https://github.com/phpmyadmin/phpmyadmin/releases/tag/RELEASE_5_2_3).
- phpMyAdmin release 5.2.3
<!-- versions:end -->

---

## Supported Tags & Tag Policy

Identical multi-arch OCI digests are published to **Docker Hub** (`dgcosenza/phpmyadmin`) and **GHCR** (`ghcr.io/dgcosenza/phpmyadmin`), accompanied by an automated signed [GitHub Release](https://github.com/dgcosenza/phpmyadmin-docker/releases):

| Tag | Policy | Description |
| --- | --- | --- |
| `<version>-<YYYYMMDD>` (e.g. `5.2.3-20261125`) | **Immutable** | Date-stamped daily rebuild pinning phpMyAdmin and UTC build date. |
| `sha-<short>` | **Immutable** | Packaging repository Git commit tag. |
| `<version>` (e.g. `5.2.3`) | Moving | Latest verified Debian 13 security rebuild of that phpMyAdmin release. |
| `latest` | Moving | Latest verified daily phpMyAdmin build. |

**Production pinning:** Pin by immutable registry digest rather than an unpinned moving tag:

```yaml
image: dgcosenza/phpmyadmin:latest@sha256:<digest>
# or via GitHub Container Registry (identical digest):
image: ghcr.io/dgcosenza/phpmyadmin:latest@sha256:<digest>
```

---

## Supported Architectures

| Architecture | Status | Verification |
| --- | --- | --- |
| `linux/amd64` | **Published & natively tested** | Built, smoke-tested (HTTP 200 login UI, `:ro` user config, hidden PHP header, non-root `www-data` workers, rootless port `8080`, negative healthcheck), Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native x86_64 CI runners. |
| `linux/arm64` | **Published & natively tested** | Built, smoke-tested, Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native ARM64 CI runners. |

---

## Quick Start

### Docker CLI (hardened)

```bash
docker run -d --name phpmyadmin \
  --read-only \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --cap-add SETUID \
  --cap-add SETGID \
  --security-opt no-new-privileges:true \
  --tmpfs /sessions:uid=33,gid=33,mode=1777,size=32m \
  --tmpfs /var/www/html/tmp:uid=33,gid=33,mode=1777,size=32m \
  --tmpfs /var/run/apache2:mode=0755,size=8m \
  --tmpfs /tmp:mode=1777,size=32m \
  -e PMA_HOST=db \
  -e PMA_ARBITRARY=0 \
  -p 127.0.0.1:8080:80 \
  dgcosenza/phpmyadmin:latest
```

### Hardened Docker Compose

See [`docker-compose.example.yml`](https://github.com/dgcosenza/phpmyadmin-docker/blob/main/docker-compose.example.yml):

```yaml
services:
  phpmyadmin:
    image: dgcosenza/phpmyadmin:latest
    restart: unless-stopped
    read_only: true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
      - SETUID
      - SETGID
    security_opt:
      - no-new-privileges:true
    tmpfs:
      - /sessions:uid=33,gid=33,mode=1777,size=32m
      - /var/www/html/tmp:uid=33,gid=33,mode=1777,size=32m
      - /var/run/apache2:mode=0755,size=8m
      - /tmp:mode=1777,size=32m
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

---

## Configuration

### Environment Variables

Full drop-in parity with the official `phpmyadmin` Docker image:

| Variable | Description | Default |
| --- | --- | --- |
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
| `APACHE_PORT` | Override Apache listen port (e.g. `8080` for fully rootless `--user 33:33`) | `80` |
| `PMA_CONFIG_BASE64` / `PMA_USER_CONFIG_BASE64` | Base64-encoded config overrides | — |

### Volumes, Ports, and Privileges

| Path / Port | Purpose |
| --- | --- |
| `/etc/phpmyadmin/config.user.inc.php` | Custom PHP configuration overrides (mount `:ro`) |
| `/sessions` | PHP session storage (mode `1777`, `www-data:www-data`) |
| `/etc/phpmyadmin/ssl` | TLS CA/client certificates for encrypted DB connections |
| `80/tcp` | Apache HTTP server (or unprivileged `APACHE_PORT=8080` with `--user 33:33`) |

Apache workers run as non-root `www-data` (**UID/GID `33:33`**). For fully rootless execution (`--user 33:33 --cap-drop ALL`), set `APACHE_PORT=8080`. The web root `/var/www/html` is read-only (`555`/`444`) except `/var/www/html/tmp`.

---

## Healthcheck

```bash
curl -fsS http://127.0.0.1:80/
```

---

## Upgrade and Migration from Upstream `phpmyadmin`

This image is a direct drop-in replacement for `phpmyadmin:latest`:

1. Keep your existing `/etc/phpmyadmin/config.user.inc.php` mount and `PMA_*` environment variables unchanged.
2. Tag the outgoing image locally for rollback before switching.
3. Replace `image: phpmyadmin:latest` with `image: dgcosenza/phpmyadmin:latest@sha256:<digest>` (or GHCR) and run `docker compose up -d --no-deps phpmyadmin`.

---

## Supply-Chain Verification

Every published digest (multi-arch index and per-architecture manifests) on both Docker Hub and GHCR is keyless-signed with **Sigstore Cosign** (GitHub OIDC), attested with **SPDX** and **CycloneDX** SBOMs, and backed by **SLSA Build L3** provenance (`actions/attest-build-provenance`).

### Verify image signature with Cosign

```bash
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/phpmyadmin-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/phpmyadmin:latest

# Or against Docker Hub (identical digest):
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/phpmyadmin-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  dgcosenza/phpmyadmin:latest
```

### Verify SPDX / CycloneDX SBOM attestations

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/phpmyadmin-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/phpmyadmin@sha256:<arch-digest>
```

### Verify SLSA Build Provenance

```bash
gh attestation verify oci://ghcr.io/dgcosenza/phpmyadmin:latest --owner dgcosenza
```

---

## Security

- **Preflight gates:** Every push and PR runs **Hadolint** (blocking on warning+), **Gitleaks** secret scanning across git history, and **public-content/attribution** checks.
- **Vulnerability scan policy:** Every build generates **SPDX** and **CycloneDX** SBOMs with **Syft** per architecture, scans with **Trivy** (OS + PHP Composer + JS: table, JSON, SARIF upload, blocking `--ignore-unfixed` gate) and **Grype** scanning the SPDX SBOM (`--only-fixed --fail-on high`), and enforces a **Dive** efficiency gate (`>= 95%`).
- **Hardening:** `expose_php=Off`, `allow_url_fopen=Off`, `session.cookie_httponly=1`, `session.use_strict_mode=1`, read-only web root, and Composer removed from the final runtime stage.
- **Dependency automation:** Renovate (`renovate.json`) pins base image digests and GitHub Action commit SHAs; Dependabot security alerts and OpenSSF Scorecard monitoring are enabled.
- See [`SECURITY.md`](https://github.com/dgcosenza/phpmyadmin-docker/blob/main/SECURITY.md) for private disclosure instructions.

---

## Build Locally

```bash
docker buildx build --platform linux/amd64 --load \
  --build-arg PHP_VERSION=8.3.37 \
  --build-arg PMA_VERSION=5.2.3 \
  -t dgcosenza/phpmyadmin:local .
```

---

## Update Policy

[`.github/workflows/daily.yml`](https://github.com/dgcosenza/phpmyadmin-docker/blob/main/.github/workflows/daily.yml) runs automatically every day at **05:02 UTC**, on pushes to `main`, on pull requests (verification only), and via `workflow_dispatch`:

1. **Preflight & upstream check:** Runs public-content checks, **Hadolint**, and **Gitleaks**; queries the authenticated GitHub API (`phpmyadmin/phpmyadmin`) and Docker Hub (`library/php` `8.3.x-apache-trixie`, `library/composer`) for digest-pinned base images, emitting `upstream-changes.md`.
2. **Multi-arch no-cache rebuild:** Rebuilds natively on `linux/amd64` and `linux/arm64` runners with `--no-cache` on schedule, upgrades Debian 13 packages, verifies the phpMyAdmin tarball via SHA-256 + GPG (`3D06A59ECE730EB71B511C17CE752F178259BD92`), and refreshes production Composer dependencies in a discarded stage.
3. **Smoke, Dive & vulnerability gates:** Runs [`tests/smoke.sh`](https://github.com/dgcosenza/phpmyadmin-docker/blob/main/tests/smoke.sh) natively on both architectures, enforces the **Dive** efficiency gate (`>= 95%`), generates **Syft** SPDX + CycloneDX SBOMs per arch, and gates publication on **0 fixable Critical/High** in both **Trivy** and **Grype** (scanning the SPDX SBOM).
4. **Dual-registry publish & supply-chain signing:** Assembles the multi-arch OCI manifest index on **GHCR** (`ghcr.io/dgcosenza/phpmyadmin`) and mirrors the identical digest to **Docker Hub** (`dgcosenza/phpmyadmin`) with tags `latest`, `<version>`, `<version>-<YYYYMMDD>`, and `sha-<short>`; signs every digest and attaches SPDX/CycloneDX SBOM attestations via **Cosign** keyless OIDC; emits **SLSA Build L3** provenance; and publishes a signed **GitHub Release** with checksums and SBOMs.
5. **Automated documentation sync:** Commits updated `versions.json`, the README `Current Versions` block, and a dated `CHANGELOG.md` entry via `github-actions[bot]` (`[skip ci]`, validated by `public-check.sh`), then syncs the Docker Hub overview and short description.
6. **Failure alerting:** Opens or updates a single GitHub issue labeled `ci-failure` on any `main` or scheduled failure, and auto-closes it on the next green run.

---

## Design Decisions

- **Base `php:8.3.x-apache-trixie`:** phpMyAdmin 5.2.x officially supports PHP `<8.4` (`>=7.2,<8.4`), and `php:8.3.x-apache-trixie` provides a minimal, Debian 13-native Apache + PHP stack on both `amd64` and `arm64`.
- **Multi-stage Composer vendor patching:** Official phpMyAdmin tarballs bundle frozen vendor packages (such as Twig and Symfony) that carry Critical and High CVEs. Refreshing production dependencies with `composer update --no-dev` inside a build stage patches those libraries while keeping Composer out of the runtime image.
- **Hadolint `DL3008` ignore:** Daily `--no-cache` security rebuilds intentionally pull the newest Debian 13 security updates via `apt-get`.
- **Dive `highestUserWastedPercent: 0.15`:** Overall image efficiency remains strictly gated at `>= 95%`; daily `apt-get -y upgrade` and extension builds update a small fraction of `php:8.3-apache-trixie` base files.

---

## License

This repository follows a clear packaging-vs-upstream license split:

- **Container packaging, configuration helpers, CI workflows, and documentation (`packaging: MIT`):** Licensed under the [MIT License](https://github.com/dgcosenza/phpmyadmin-docker/blob/main/LICENSE) — copyright **Daniel G. Cosenza from FNX Labs**.
- **Bundled upstream software — phpMyAdmin (`upstream: GPL-2.0-only`):** Copyright the phpMyAdmin developers — licensed under the [GNU General Public License v2.0](https://github.com/phpmyadmin/phpmyadmin/blob/master/LICENSE).

Full third-party notices are maintained in [`THIRD-PARTY-NOTICES.md`](https://github.com/dgcosenza/phpmyadmin-docker/blob/main/THIRD-PARTY-NOTICES.md). Release history is maintained in [`CHANGELOG.md`](https://github.com/dgcosenza/phpmyadmin-docker/blob/main/CHANGELOG.md).

## Credits

- [phpMyAdmin Team](https://www.phpmyadmin.net/) and [phpmyadmin/docker](https://github.com/phpmyadmin/docker)
- [Docker Official PHP Images](https://hub.docker.com/_/php)
- [Debian Project](https://www.debian.org/)

Maintained by **Daniel G. Cosenza from FNX Labs**.
