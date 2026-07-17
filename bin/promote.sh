#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>  (e.g. 202607171640-ed3256e)" >&2
    exit 1
fi

for side in left right; do
    if [ ! -f "firmware/${VERSION}-${side}.uf2" ]; then
        echo "firmware/${VERSION}-${side}.uf2 not found — refusing to promote." >&2
        exit 1
    fi
done

echo "$VERSION" > firmware/ACTIVE
echo "Active firmware version: $VERSION"
