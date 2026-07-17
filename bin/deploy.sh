#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")/.."

VOLUME=/Volumes/ADV360PRO

SIDE="${1:-}"
if [ "$SIDE" != "left" ] && [ "$SIDE" != "right" ]; then
    echo "Usage: $0 left|right" >&2
    exit 1
fi

if [ ! -f firmware/ACTIVE ]; then
    echo "No active firmware version (firmware/ACTIVE missing). Run bin/promote.sh or bin/build_and_promote.sh first." >&2
    exit 1
fi
VERSION=$(cat firmware/ACTIVE)
FILE="firmware/${VERSION}-${SIDE}.uf2"
if [ ! -f "$FILE" ]; then
    echo "Active firmware file $FILE not found." >&2
    exit 1
fi

echo "Deploying $FILE to the $SIDE half."
echo "NOTE: the bootloader cannot tell the halves apart — make sure the $SIDE half is the one connected."
if [ ! -d "$VOLUME" ]; then
    echo "Waiting for the bootloader drive at $VOLUME (Ctrl-C to abort)..."
    until [ -d "$VOLUME" ]; do sleep 1; done
fi

if ! grep -q "Model: ADV360PRO" "$VOLUME/INFO_UF2.TXT" 2>/dev/null; then
    echo "$VOLUME does not look like the Adv360 bootloader (INFO_UF2.TXT check failed)." >&2
    exit 1
fi

# Plain sequential write: Finder and cp both trip over the virtual FAT volume
# on macOS (error -50 / fcopyfile EFAULT).
echo "Writing firmware..."
cat "$FILE" > "$VOLUME/NEW.UF2" && sync

# The volume disappearing means the bootloader accepted the image and rebooted.
for _ in $(seq 1 30); do
    if [ ! -d "$VOLUME" ]; then
        echo "Flash accepted — $SIDE half rebooted into $VERSION."
        exit 0
    fi
    sleep 1
done

echo "The bootloader drive is still mounted 30s after writing — the flash may not have completed." >&2
exit 1
