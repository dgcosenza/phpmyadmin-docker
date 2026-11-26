# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Maintained by **Daniel G. Cosenza from FNX Labs**.

## [Unreleased]

<!-- changelog:auto -->

## [5.2.3] — 2026-11-26

### Automated Daily Build
- Verified components: phpMyAdmin `5.2.3 (GPG-verified + Composer security-patched)`, PHP + Apache `php:8.3.37-apache-trixie`, Base OS `Debian 13.8 (trixie)`.
- Architectures verified: `linux/amd64, linux/arm64` (native smoke tests + Dive efficiency gate).
- Upstream changes:
  - **phpMyAdmin:** `5.2.3` -> `5.2.3`
  - **PHP (Debian 13 Apache):** `8.3.37` -> `8.3.37`
  - **Upstream version changed:** `no`
  - Official phpMyAdmin 5.2.3 release (https://github.com/phpmyadmin/phpmyadmin/releases/tag/RELEASE_5_2_3).
  - phpMyAdmin release 5.2.3
- Vulnerability gate: **0 fixable findings of any severity** in Trivy and Grype (SBOM scan) (48 upstream-unfixed).
- Published multi-arch digest (Docker Hub + GHCR): `dgcosenza/phpmyadmin@sha256:c499f18f32572a06eb5c59ec3b02695c8069cf24ad87e6ef8b5514e7dd932bfb` (Cosign OIDC signed + SPDX/CycloneDX SBOM + SLSA L3 provenance).
---

## [5.2.3] — 2026-11-25

### Automated Daily Build
- Verified components: phpMyAdmin `5.2.3 (GPG-verified + Composer security-patched)`, PHP + Apache `php:8.3.37-apache-trixie`, Base OS `Debian 13.8 (trixie)`.
- Architectures verified: `linux/amd64, linux/arm64` (native smoke tests + Dive efficiency gate).
- Upstream changes:
  - **phpMyAdmin:** `5.2.3` -> `5.2.3`
  - **PHP (Debian 13 Apache):** `8.3.37` -> `8.3.37`
  - **Upstream version changed:** `no`
  - Official phpMyAdmin 5.2.3 release (https://github.com/phpmyadmin/phpmyadmin/releases/tag/RELEASE_5_2_3).
  - phpMyAdmin release 5.2.3
- Vulnerability gate: **0 fixable Critical/High** in Trivy and Grype (SBOM scan) (48 upstream-unfixed).
- Published multi-arch digest (Docker Hub + GHCR): `dgcosenza/phpmyadmin@sha256:7a591c05be41af820867000a3f45c26d3dc6852a6c36ffddfc9946a27d975c41` (Cosign OIDC signed + SPDX/CycloneDX SBOM + SLSA L3 provenance).
---

---

## [2026-11-25]

### Changed
- Rebuilt phpMyAdmin `5.2.3` on `php:8.3.37-apache-trixie` (Debian `13.8`) (`dgcosenza/phpmyadmin@sha256:a2bc893e1eb065b0540ab1b2a51b7c102390d79208f9ef60f8bb835ae60fd455`)

### Security
- Trivy and Grype gates verified: 0 fixable Critical/High vulnerabilities.

## [2026-11-24]

### Added
- Initial hardened phpMyAdmin `5.2.3` image on `php:8.3.37-apache-trixie` (Debian 13) with SHA-256 and GPG signature verification (`3D06A59ECE730EB71B511C17CE752F178259BD92`).
- Multi-stage Composer dependency refresh to patch Twig and Symfony vendor vulnerabilities while keeping Composer out of the runtime image.
- Full drop-in compatibility with upstream `phpmyadmin` env vars, `/etc/phpmyadmin/config.user.inc.php`, healthcheck, and 7-step automated daily CI pipeline.

### Security
- Eliminated 86 fixable Critical/High vulnerabilities (6 Critical, 80 High) present in upstream `phpmyadmin:latest` (75 stale Debian packages + 11 Composer vendor CVEs in Twig and Symfony).
- Verified 0 fixable Critical/High findings in both Trivy and Grype.
