#!/usr/bin/env bash
set -euo pipefail

# Report usage of the filesystem that contains the host's root directory.
disk_usage=$(df -hP / | awk 'NR == 2 { printf "%s / %s (%s used)", $3, $2, $5 }')

curl --fail --silent --show-error \
  --retry 5 --retry-delay 10 --retry-all-errors \
  --connect-timeout 10 --max-time 20 \
  --data-binary "homelab started + ${disk_usage}" \
  https://ntfy.sh/paimoe-homelab-notifications
