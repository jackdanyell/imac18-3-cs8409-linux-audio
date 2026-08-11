#!/bin/bash

set -e

echo "=========================================="
echo " iMac18,3 CS8409 Linux Audio Driver"
echo "=========================================="
echo

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this installer with sudo."
    echo
    echo "Usage:"
    echo "  sudo ./install-imac18-3.sh"
    exit 1
fi

MODEL="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
BOARD="$(cat /sys/class/dmi/id/board_name 2>/dev/null || true)"

echo "Detected machine : $MODEL"
echo "Board            : $BOARD"

if [ "$MODEL" != "iMac18,3" ]; then
    echo
    echo "ERROR: This installer is intended for Apple iMac18,3"
    echo "       (iMac Retina 5K, 27-inch, 2017)."
    echo
    echo "Detected: $MODEL"
    exit 1
fi

CODEC_FOUND=0

for codec in /sys/bus/hdaudio/devices/*/chip_name; do
    [ -f "$codec" ] || continue

    CHIP="$(cat "$codec" 2>/dev/null || true)"

    echo "HDA codec        : $CHIP"

    if [[ "$CHIP" == CS8409* ]]; then
        CODEC_FOUND=1
    fi
done

if [ "$CODEC_FOUND" -ne 1 ]; then
    echo
    echo "ERROR: CS8409 HDA codec was not detected."
    echo
    echo "This driver is specifically intended for the CS8409"
    echo "audio hardware used by supported Apple machines."
    exit 1
fi

echo
echo "Hardware check: OK"
echo
echo "Starting DKMS installation..."
echo

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

exec ./install.cirrus.driver.sh -i
