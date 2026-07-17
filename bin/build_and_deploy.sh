#!/usr/bin/env bash

set -euo pipefail
cd "$(dirname "$0")/.."

SKIP_BUILD=false
if [ "${1:-}" = "--skip-build" ]; then
    SKIP_BUILD=true
elif [ -n "${1:-}" ]; then
    echo "Usage: $0 [--skip-build]" >&2
    exit 1
fi

if [ "$SKIP_BUILD" = true ] && [ ! -f firmware/ACTIVE ]; then
    echo "--skip-build needs an active firmware version, but firmware/ACTIVE is missing." >&2
    exit 1
fi

KEYMAP=config/adv360.keymap
if ! grep -q '&bootloader' "$KEYMAP"; then
    echo "WARNING: no &bootloader binding in $KEYMAP — Mod+macro1/3 won't work; use the physical reset buttons instead." >&2
fi
if ! grep -q '&macro_ver' "$KEYMAP"; then
    echo "WARNING: no &macro_ver binding in $KEYMAP — the Mod+V version test won't work." >&2
fi

# Reconstructs the Mod+V string baked in by bin/get_version_local.sh from the
# active version record (TIMESTAMP-COMMIT), so it is also correct with
# --skip-build. Assumes the build was made from the current branch.
expected_version() {
    local active
    active=$(cat firmware/ACTIVE)
    echo "${active:0:8}-$(git rev-parse --abbrev-ref HEAD | cut -c1-4)-${active#*-}-."
}

if [ "$SKIP_BUILD" = true ]; then
    step1="Skip the build and deploy the active firmware ($(cat firmware/ACTIVE))."
else
    step1="Build both firmware halves (make) and promote the build as active."
fi
cat <<EOF
This will:
  1. $step1
  2. Flash the left half  — you'll put it in bootloader mode when prompted.
  3. Flash the right half — same.
The keyboard is unusable while a half is in bootloader mode; the script
advances on its own when the bootloader drive appears and disappears.
EOF
printf 'Press any key to start (Ctrl-C to abort)... '
read -rsn1
echo

if [ "$SKIP_BUILD" != true ]; then
    bin/build_and_promote.sh
fi

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
