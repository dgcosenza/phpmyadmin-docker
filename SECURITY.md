# Security Policy

Maintained by **Daniel G. Cosenza from FNX Labs**.

## Supported Versions

Only the latest daily build (`latest`) receives security updates. Immutable date-stamped tags (`<version>-YYYYMMDD`) are frozen for reproducibility.

## Vulnerability Scanning & Gates

- **Trivy** (OS + Composer + JS): SARIF uploaded to GitHub Code Scanning; table and JSON reports retained for 90 days; **blocking hard gate** on any fixable `CRITICAL` or `HIGH` finding.
- **Grype**: **blocking hard gate** (`only-fixed: true`, severity cutoff `high`); table report retained for 90 days.
- **SBOM & Provenance**: SPDX-JSON SBOM via Syft plus provenance JSON retained for 90 days.

## Reporting a Vulnerability

**Do not open a public issue** for security vulnerabilities.

Report privately through GitHub Security Advisories: open the repository's **Security** tab or submit a private advisory directly at [dgcosenza/phpmyadmin-docker Security Advisories](https://github.com/dgcosenza/phpmyadmin-docker/security/advisories/new).

For upstream phpMyAdmin vulnerabilities, follow the [phpMyAdmin Security Policy](https://www.phpmyadmin.net/security/).

We aim to acknowledge reports within 48 hours and ship fixes in the next daily build or an immediate manual dispatch.
