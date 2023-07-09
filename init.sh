#!/usr/bin/env bash
set -euo pipefail

ROOT="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

cd "$ROOT"
west init -l ./app
west update
west zephyr-export
