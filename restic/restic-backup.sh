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
    
    if output=$(restic -r "$path" backup --skip-if-unchanged --files-from "$HOME/automation/restic/includes.txt" --json --quiet); then
    	summary=$(jq -c 'select(.message_type == "summary")' <<< "$output" | tail -n 1)

    	if [[ -z "$summary" ]]; then
            echo "[$name] Backup succeeded: unchanged; no snapshot created, completed: $(date --iso-8601=seconds)"
    	else
            printf '%s\n' "$output" |
        	jq -r --arg NAME "${name}" '
            	select(.message_type == "summary") |
            	"[\(.backup_end | sub("\\.[0-9]+"; "")) | \($NAME)] Backup succeeded (\(.snapshot_id // "unchanged" | .[0:8])): " +
            	"[\(.files_new)n, \(.files_changed)c] files, " +
            	"[\(.dirs_new)n, \(.dirs_changed)c] dirs, " +
            	"size: \((.total_bytes_processed / 1000000000 * 100 | round) / 100)GB, " +
            	"duration: \(.total_duration | floor)s"
        	'
        fi
    else
        status=$?
        echo "Backup FAILED with status $status: $(date --iso-8601=seconds)"
        exit "$status"
    fi
done

