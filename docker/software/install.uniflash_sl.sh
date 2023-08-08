#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

UNIFLASH_SL_URL="https://dr-download.ti.com/software-development/software-programming-tool/MD-QeJBJLj8gq/8.3.0/uniflash_sl.8.3.0.4307.run"
wget \
     -nv "$UNIFLASH_SL_URL" \
     -O "/opt/uniflash_sl.run"
chmod +x "/opt/uniflash_sl.run"