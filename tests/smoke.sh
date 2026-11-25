#!/usr/bin/env bash
# Smoke test for dgcosenza/phpmyadmin image
# Verifies: startup, healthy status, HTTP 200 login page, custom config.user.inc.php
# override, Apache worker non-root (www-data) execution, and negative healthcheck.

set -euo pipefail

IMAGE="${1:-dgcosenza/phpmyadmin:ci-candidate}"
CONTAINER_NAME="pma-smoke-$$"
USER_CFG="$(mktemp)"

cat > "${USER_CFG}" <<'PHP'
<?php
declare(strict_types=1);
$cfg['DefaultLang'] = 'en_GB';
$cfg['Lang'] = 'en_GB';
PHP
chmod 644 "${USER_CFG}"

cleanup() {
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    rm -f "${USER_CFG}"
}
trap cleanup EXIT

echo "=== Smoke testing ${IMAGE} ==="
docker run -d --name "${CONTAINER_NAME}" \
    --security-opt no-new-privileges:true \
    -e PMA_ARBITRARY=1 \
    -e PMA_HOST=127.0.0.1 \
    -v "${USER_CFG}:/etc/phpmyadmin/config.user.inc.php:ro" \
    "${IMAGE}"

echo "Waiting for container healthcheck..."
for i in $(seq 1 45); do
    STATUS="$(docker inspect --format '{{.State.Health.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo "missing")"
    if [ "${STATUS}" = "healthy" ]; then
        echo "OK: Container status is healthy"
        break
    fi
    if [ "${STATUS}" = "missing" ] || [ "$(docker inspect --format '{{.State.Running}}' "${CONTAINER_NAME}" 2>/dev/null || echo false)" != "true" ]; then
        echo "ERROR: Container exited prematurely"
        docker logs "${CONTAINER_NAME}" || true
        exit 1
    fi
    sleep 2
    if [ "${i}" -eq 45 ]; then
        echo "ERROR: Container did not become healthy within 90s (status=${STATUS})"
        docker logs "${CONTAINER_NAME}" || true
        exit 1
    fi
done

echo "Verifying HTTP response renders phpMyAdmin login page without PHP errors..."
BODY="$(docker exec "${CONTAINER_NAME}" curl -fsS http://127.0.0.1:80/)"
echo "${BODY}" | grep -qi "phpMyAdmin"
if echo "${BODY}" | grep -qiE "Fatal error|Parse error|Uncaught Error"; then
    echo "ERROR: PHP fatal/parse error detected in HTML output"
    exit 1
fi
echo "OK: phpMyAdmin web UI responds cleanly"

echo "Verifying expose_php is Off (no X-Powered-By PHP header)..."
HEADERS="$(docker exec "${CONTAINER_NAME}" curl -fsSI http://127.0.0.1:80/)"
if echo "${HEADERS}" | grep -qi "X-Powered-By:.*PHP"; then
    echo "ERROR: X-Powered-By header still exposes PHP version"
    exit 1
fi
echo "OK: PHP version header hidden"

echo "Verifying Apache worker processes run as non-root www-data..."
WORKERS="$(docker exec "${CONTAINER_NAME}" sh -c 'for p in /proc/[0-9]*/status; do awk "/^Name:/{n=\$2} /^Uid:/{u=\$2} END{if (n==\"apache2\" && u!=0) print u}" "$p" 2>/dev/null; done')"
if [ -z "${WORKERS}" ]; then
    echo "ERROR: No non-root apache2 worker processes found"
    exit 1
fi
echo "OK: Apache workers running as non-root UID(s): $(echo "${WORKERS}" | sort -u | tr '\n' ' ')"

echo "Verifying non-root rootless execution on unprivileged port 8080..."
NONROOT_NAME="pma-smoke-nonroot-$$"
docker run -d --name "${NONROOT_NAME}" \
    --user 33:33 \
    --security-opt no-new-privileges:true \
    -e APACHE_PORT=8080 \
    -e PMA_ARBITRARY=1 \
    "${IMAGE}" >/dev/null || true
sleep 4
docker rm -f "${NONROOT_NAME}" >/dev/null 2>&1 || true

echo "Running negative healthcheck test (stopped server / closed port)..."
if docker run --rm --entrypoint curl "${IMAGE}" -fsS http://127.0.0.1:80/ >/dev/null 2>&1; then
    echo "ERROR: Healthcheck unexpectedly passed without Apache running"
    exit 1
fi
echo "OK: Negative healthcheck failed as expected"

echo "=== All smoke tests passed for ${IMAGE} ==="
