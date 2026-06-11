#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="nemotron"
UNIT_FILE="${SERVICE_NAME}.service"
DEST="/etc/systemd/system/${UNIT_FILE}"

if [[ $EUID -ne 0 ]]; then
    echo "This uninstaller must be run with sudo." >&2
    echo "Try: sudo $0" >&2
    exit 1
fi

if systemctl list-unit-files | grep -q "^${UNIT_FILE}"; then
    echo "Stopping ${SERVICE_NAME} (if running)"
    systemctl stop "${SERVICE_NAME}.service" || true

    echo "Disabling ${SERVICE_NAME}"
    systemctl disable "${SERVICE_NAME}.service" || true
else
    echo "${UNIT_FILE} is not installed, skipping stop/disable"
fi

if [[ -f "${DEST}" ]]; then
    echo "Removing ${DEST}"
    rm -f "${DEST}"
fi

echo "Reloading systemd"
systemctl daemon-reload
systemctl reset-failed "${SERVICE_NAME}.service" 2>/dev/null || true

echo "Uninstalled."
