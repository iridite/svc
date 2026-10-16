#!/usr/bin/env bash
# Installer for svc
set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "${INSTALL_DIR}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/bin/svc" ]]; then
  cp "${SCRIPT_DIR}/bin/svc" "${INSTALL_DIR}/svc"
else
  # Curl from github if installed via one-liner
  curl -fsSL https://raw.githubusercontent.com/iridite/svc/main/bin/svc -o "${INSTALL_DIR}/svc"
fi

chmod +x "${INSTALL_DIR}/svc"

echo "✓ Successfully installed svc to ${INSTALL_DIR}/svc"
if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
  echo "⚠️  Note: ${INSTALL_DIR} is not in your PATH. Add it to ~/.zshrc:"
  echo "    export PATH=\"${INSTALL_DIR}:\$PATH\""
fi
echo "Run 'svc --help' to get started!"
