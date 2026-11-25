#!/usr/bin/env python3
"""Resolve latest official phpMyAdmin 5.2.x release and PHP 8.3.x-apache-trixie tag."""

from __future__ import annotations

import json
import os
import re
import urllib.request
from pathlib import Path


def fetch_json(url: str, github_api: bool = False):
    headers = {"User-Agent": "dgcosenza-phpmyadmin-docker-ci"}
    if github_api:
        headers["Accept"] = "application/vnd.github+json"
        headers["X-GitHub-Api-Version"] = "2022-11-28"
        token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
        if token:
            headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def ver_tuple(v: str) -> tuple[int, ...]:
    return tuple(int(x) for x in re.findall(r"\d+", v))


def resolve_pma(override: str) -> tuple[str, str]:
    if override:
        return override, f"Manual override requested: phpMyAdmin {override}."

    rel = fetch_json("https://api.github.com/repos/phpmyadmin/phpmyadmin/releases/latest", github_api=True)
    tag = (rel.get("tag_name") or "").strip()
    m = re.match(r"^RELEASE_(\d+)_(\d+)_(\d+)$", tag)
    if m:
        ver = f"{m.group(1)}.{m.group(2)}.{m.group(3)}"
        body = (rel.get("body") or "").strip()
        url = rel.get("html_url") or f"https://www.phpmyadmin.net/files/{ver}/"
        notes = f"Official phpMyAdmin {ver} release ({url})."
        if body:
            lines = [ln.strip() for ln in body.splitlines() if ln.strip()][:8]
            notes += "\n\n" + "\n".join(lines)
        return ver, notes

    # Fallback: official phpmyadmin version.json
    vj = fetch_json("https://www.phpmyadmin.net/home_page/version.json")
    ver = vj["version"]
    return ver, f"Official phpMyAdmin {ver} release (from phpmyadmin.net/home_page/version.json)."


def resolve_php(override: str, default_ver: str) -> str:
    if override:
        return override
    try:
        data = fetch_json("https://hub.docker.com/v2/repositories/library/php/tags?name=8.3.&page_size=50")
        cands = []
        for r in data.get("results", []):
            name = r.get("name", "")
            m = re.fullmatch(r"(8\.3\.\d+)-apache-trixie", name)
            if m:
                cands.append(m.group(1))
        if cands:
            cands.sort(key=ver_tuple, reverse=True)
            return cands[0]
    except Exception:
        pass
    return default_ver


def main() -> None:
    pma_ver, notes = resolve_pma(os.environ.get("OVERRIDE_PMA", "").strip())
    php_ver = resolve_php(os.environ.get("OVERRIDE_PHP", "").strip(), os.environ.get("PHP_VERSION_DEFAULT", "8.3.37"))

    prev = {}
    vpath = Path("versions.json")
    if vpath.exists():
        prev = json.loads(vpath.read_text(encoding="utf-8"))
    prev_pma = prev.get("pma_version", "")
    prev_php = prev.get("php_version", "")

    changed = (pma_ver != prev_pma) or (php_ver != prev_php)
    md = [
        "# Upstream changes — phpMyAdmin",
        "",
        f"- **phpMyAdmin:** `{prev_pma or 'none'}` -> `{pma_ver}`",
        f"- **PHP (Debian 13 Apache):** `{prev_php or 'none'}` -> `{php_ver}`",
        f"- **Upstream version changed:** `{'yes' if changed else 'no'}`",
        "",
        "## Release notes",
        "",
        notes,
        "",
    ]
    Path("upstream-changes.md").write_text("\n".join(md), encoding="utf-8")

    outputs = {
        "pma_version": pma_ver,
        "prev_pma_version": prev_pma,
        "php_version": php_ver,
        "upstream_changed": "true" if changed else "false",
    }
    gh_out = os.environ.get("GITHUB_OUTPUT")
    if gh_out:
        with open(gh_out, "a", encoding="utf-8") as fh:
            for k, v in outputs.items():
                fh.write(f"{k}={v}\n")
    for k, v in outputs.items():
        print(f"{k}={v}")


if __name__ == "__main__":
    main()
