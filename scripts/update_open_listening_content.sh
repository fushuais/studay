#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

python3 scripts/fetch_japanese_listening_content.py
python3 scripts/fetch_eju_oss_listening.py

STAMP_FILE="travel/open_listening_last_update.json"
NOW_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "${STAMP_FILE}" <<EOF
{
  "updatedAtUTC": "${NOW_UTC}",
  "sources": [
    "ManyThings jpn-eng",
    "NHK RSS",
    "JASSO EJU pastpaper sample"
  ]
}
EOF

echo "Updated open listening content at ${NOW_UTC}"
