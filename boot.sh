#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$DIR/bin"
BOOT_DIR="$DIR/bootchain"

echo "=================================================="
echo "[*] iPhone X (iOS 11.1) Tethered Boot"
echo "=================================================="

echo "[*] Waiting for iPhone in DFU mode..."
while true; do
    MODE=$("$BIN/irecovery" -m 2>/dev/null || /usr/local/bin/irecovery -m 2>/dev/null || true)
    if [ "$MODE" = "DFU Mode" ]; then
        echo "[+] iPhone detected in DFU mode!"
        break
    fi
    sleep 0.5
done

echo "[*] Exploiting checkm8 with gaster..."
"$BIN/gaster" pwn
echo "[*] Resetting USB..."
"$BIN/gaster" reset
sleep 2

echo "[*] Sending iBSS..."
"$BIN/irecovery" -f "$BOOT_DIR/iBSS.img4"
sleep 2

echo "[*] Sending iBEC..."
"$BIN/irecovery" -f "$BOOT_DIR/iBEC.img4"
sleep 2

echo "[*] Jumping to iBEC..."
"$BIN/irecovery" -c go
sleep 3

echo "[*] Sending DeviceTree..."
"$BIN/irecovery" -f "$BOOT_DIR/devicetree.img4"
sleep 1
"$BIN/irecovery" -c devicetree
sleep 1

echo "[*] Sending Kernelcache..."
"$BIN/irecovery" -f "$BOOT_DIR/kernelcache.img4"
sleep 2

echo "[*] Booting kernel (bootx)..."
"$BIN/irecovery" -c bootx
echo "=================================================="
echo "[+] iOS 11.1 successfully booted!"
echo "=================================================="
