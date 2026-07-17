#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")/.."

# Pass TIMESTAMP/COMMIT explicitly so the produced filenames are known in
# advance instead of guessed from the newest files in firmware/.
TIMESTAMP=$(date -u +"%Y%m%d%H%M")
COMMIT=$(git rev-parse --short HEAD)

make TIMESTAMP="$TIMESTAMP" COMMIT="$COMMIT"

bin/promote.sh "${TIMESTAMP}-${COMMIT}"
