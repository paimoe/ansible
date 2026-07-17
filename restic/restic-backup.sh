#!/usr/bin/env bash
set -euo pipefail

# ── restic backup wrapper ────────────────────────────────────────────
# Usage:
#   ./restic-backup.sh --repo home
#   ./restic-backup.sh --repo 2tb --repo blaze
#
# At least one --repo flag is required.  Valid repo names are declared
# in the REPOS associative array below; each maps to a restic -r path.

# ── Configuration ────────────────────────────────────────────────────
# Edit these paths to match your environment.
declare -A REPOS=(
    [home]="/home/paimoe/restic-repo/"
    [2tb]="/media/paimoe/2TB Media/restic-repo/"
    #[blaze]="/mnt/restic-blaze"
)

# ── Load .env from script directory ────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
if [[ -f "$ENV_FILE" ]]; then
    set -a
    source "$ENV_FILE"
    set +a
fi


# ── Guard: RESTIC_PASSWORD must be set ──────────────────────────────
if [[ -z "${RESTIC_PASSWORD:-}" ]]; then
    echo "ERROR: RESTIC_PASSWORD is not set or is empty." >&2
    echo "Load it first, e.g.:  export RESTIC_PASSWORD='your-password'" >&2
    exit 1
fi

# ── Parse arguments ──────────────────────────────────────────────────
TARGETS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            if [[ -z "${2:-}" ]]; then
                echo "ERROR: --repo requires a name (home, 2tb, blaze)." >&2
                exit 1
            fi
            TARGETS+=("$2")
            shift 2
            ;;
        *)
            echo "ERROR: Unknown argument: $1" >&2
            echo "Usage: $0 --repo <name> [--repo <name> ...]" >&2
            exit 1
            ;;
    esac
done

# ── Guard: at least one repo was requested ──────────────────────────
if [[ ${#TARGETS[@]} -eq 0 ]]; then
    echo "ERROR: At least one --repo argument is required." >&2
    echo "Valid names: ${!REPOS[*]}" >&2
    exit 1
fi

# ── Run restic for each target repo ──────────────────────────────────
for name in "${TARGETS[@]}"; do
    path="${REPOS[$name]:-}"

    if [[ -z "$path" ]]; then
        echo "ERROR: Unknown repo name '$name'. Valid names: ${!REPOS[*]}" >&2
        exit 1
    fi

    echo "──> restic -r \"$path\" backup --skip-if-unchanged --files-from ~/automation/restic/includes.txt"
    restic -r "$path" backup --skip-if-unchanged --files-from ~/automation/restic/includes.txt
done

echo "──> All backups complete."
