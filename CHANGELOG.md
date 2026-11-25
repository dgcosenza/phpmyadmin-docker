# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Maintained by **Daniel G. Cosenza from FNX Labs**.

## [Unreleased]


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
