#!/usr/bin/env bash

set -e
set -u

if (($# != 1)); then
  (
    echo "Usage: $0 <board-name>"
    (
      cd @out@/sdk
      printf "  - %s\n" *.conf | sed -e 's/.conf$//' | sort -u
    )
  ) >&2
  exit 1
fi

board="$1"
shift

export FLASHLIGHT=1      # Undocumented flag, used to skip checking for some (effectively unused) operating system files
export NO_ESP_IMG=1      # [undocumented] related to building an ESP filesystem for OS flashing
export NO_RECOVERY_IMG=1 # NO_RECOVERY_IMG -------- Do not create or re-create recovery.img
export NO_ROOTFS=1       # NO_ROOTFS -------------- Do not create or re-create system.img

args=(
  --qspi-only     # Flash QSPI device only
  --no-root-check # Don't check for root (when usb device access is given through uaccess tag)
  --no-systemimg  # Do not create or re-create system.img

  # The board and target device arguments need to be last.
  # This allows passing more arguments like `-G`, `-k` or `--image`.
  "$@"

  # The target board.
  "$board"

  # Operating system flashing location, actually unused here.
  internal
)

exec "@out@/bin/flash" "${args[@]}"
