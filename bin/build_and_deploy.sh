#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")/.."

KEYMAP=config/adv360.keymap
if ! grep -q '&bootloader' "$KEYMAP"; then
    echo "WARNING: no &bootloader binding in $KEYMAP — Mod+macro1/3 won't work; use the physical reset buttons instead." >&2
fi
if ! grep -q '&macro_ver' "$KEYMAP"; then
    echo "WARNING: no &macro_ver binding in $KEYMAP — the Mod+V version test won't work." >&2
fi

# Mirrors what bin/get_version_local.sh (run by make) bakes into the firmware.
expected_version() {
    echo "$(date -u +"%Y%m%d")-$(git rev-parse --abbrev-ref HEAD | cut -c1-4)-$(git rev-parse --short HEAD)-."
}

cat <<'EOF'
This will:
  1. Build both firmware halves (make) and promote the build as active.
  2. Flash the left half  — you'll put it in bootloader mode when prompted.
  3. Flash the right half — same.
The keyboard is unusable while a half is in bootloader mode; the script
advances on its own when the bootloader drive appears and disappears.
EOF
printf 'Press any key to start (Ctrl-C to abort)... '
read -rsn1
echo

bin/build_and_promote.sh

cat <<'EOF'

=== Left half ===
  1. Connect ONLY the left half via USB (right half's power switch off).
  2. Press Mod+macro1 (or the left physical reset button) to enter bootloader mode.
EOF
bin/deploy.sh left

cat <<'EOF'

=== Right half ===
  1. Unplug the left half; make sure both power switches are off.
  2. Switch the LEFT half back on (power switch only, no USB).
  3. Connect the RIGHT half via USB.
  4. Press Mod+macro3 (or the right physical reset button) to enter bootloader mode.
EOF
bin/deploy.sh right

cat <<EOF

SUCCESS. Unplug the right half and switch it on.
Test: press Mod+V — the keyboard should type: $(expected_version)
EOF
