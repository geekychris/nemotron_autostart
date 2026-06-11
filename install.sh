#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="nemotron"
UNIT_FILE="${SERVICE_NAME}.service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="/etc/systemd/system/${UNIT_FILE}"

if [[ $EUID -ne 0 ]]; then
    echo "This installer must be run with sudo." >&2
    echo "Try: sudo $0" >&2
    exit 1
fi

if [[ ! -f "${SCRIPT_DIR}/${UNIT_FILE}" ]]; then
    echo "Cannot find ${UNIT_FILE} next to install.sh" >&2
    exit 1
fi

BIN="/home/chris/code/llama.cpp/build/bin/llama-server"
MODEL="/home/chris/models/nemotron3-gguf/Nemotron-3-Nano-30B-A3B-UD-Q8_K_XL.gguf"
for path in "$BIN" "$MODEL"; do
    if [[ ! -e "$path" ]]; then
        echo "Missing required path: $path" >&2
        exit 1
    fi
done

echo "Installing ${UNIT_FILE} -> ${DEST}"
install -m 0644 "${SCRIPT_DIR}/${UNIT_FILE}" "${DEST}"

echo "Reloading systemd"
systemctl daemon-reload

echo "Enabling ${SERVICE_NAME} to start on boot"
systemctl enable "${SERVICE_NAME}.service"

echo "Starting ${SERVICE_NAME}"
systemctl restart "${SERVICE_NAME}.service"

sleep 2
systemctl --no-pager --full status "${SERVICE_NAME}.service" || true

cat <<EOF

Installed. Useful commands:
  systemctl status ${SERVICE_NAME}
  systemctl restart ${SERVICE_NAME}
  systemctl stop ${SERVICE_NAME}
  journalctl -u ${SERVICE_NAME} -f
EOF
