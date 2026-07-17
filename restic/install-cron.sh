#!/usr/bin/env bash
set -euo pipefail

# ── install-cron.sh ────────────────────────────────────────────────────
# Symlinks crontab.txt into /etc/cron.d/ so the backup runs on schedule.
#
# Usage:
#   sudo ./install-cron.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SCRIPT_DIR}/crontab"
DEST="/etc/cron.d/restic-backup"

if [[ ! -f "$SRC" ]]; then
    echo "ERROR: ${SRC} not found." >&2
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root (sudo)." >&2
    exit 1
fi

if [[ -e "$DEST" ]]; then
    echo "→ Removing existing ${DEST}"
    rm -f "$DEST"
fi

ln -s "$SRC" "$DEST"

echo "✓ Symlinked ${SRC} → ${DEST}"
