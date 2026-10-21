#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"
PATCHES="$DIR/patches"
SSHRD_DIR="/Users/jachuuu/SSHRD_Script"

echo "=================================================="
echo "[*] Re-applying Patches to iPhone X via SSH Ramdisk"
echo "=================================================="

echo "[*] Waiting for SSH on localhost:2222..."
if ! sshpass -p alpine ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -p 2222 root@localhost "uname -a" 2>/dev/null; then
    echo "[!] SSH not connected. Starting iproxy..."
    killall iproxy 2>/dev/null || true
    "$SSHRD_DIR/Darwin/x86_64/iproxy" 2222 22 >/dev/null 2>&1 &
    sleep 3
fi

for i in {1..30}; do
    if sshpass -p alpine ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -p 2222 root@localhost "uname -a" 2>/dev/null; then
        echo "[+] SSH connection established!"
        break
    fi
    sleep 2
done

echo "[*] Mounting partitions..."
sshpass -p alpine ssh -o StrictHostKeyChecking=no -p 2222 root@localhost "
mkdir -p /mnt4 /mnt5
/sbin/mount_apfs /dev/disk1s8 /mnt4 2>/dev/null || /sbin/mount_apfs /dev/disk0s1s8 /mnt4 2>/dev/null
/sbin/mount_apfs /dev/disk1s9 /mnt5 2>/dev/null || /sbin/mount_apfs /dev/disk0s1s9 /mnt5 2>/dev/null
"

echo "[*] Deploying patched SpringBoard..."
sshpass -p alpine scp -o StrictHostKeyChecking=no -P 2222 "$PATCHES/SpringBoard.patched" root@localhost:/mnt4/System/Library/CoreServices/SpringBoard.app/SpringBoard
sshpass -p alpine ssh -o StrictHostKeyChecking=no -p 2222 root@localhost "
chmod 755 /mnt4/System/Library/CoreServices/SpringBoard.app/SpringBoard
/usr/sbin/chown 0:0 /mnt4/System/Library/CoreServices/SpringBoard.app/SpringBoard
rm -rf /mnt4/Applications/Setup.app 2>/dev/null || true
"

echo "[*] Deploying clean plists..."
sshpass -p alpine scp -o StrictHostKeyChecking=no -P 2222 "$PATCHES/com.apple.purplebuddy.plist" root@localhost:/mnt5/mobile/Library/Preferences/com.apple.purplebuddy.plist
sshpass -p alpine scp -o StrictHostKeyChecking=no -P 2222 "$PATCHES/com.apple.springboard.plist" root@localhost:/mnt5/mobile/Library/Preferences/com.apple.springboard.plist
sshpass -p alpine scp -o StrictHostKeyChecking=no -P 2222 "$PATCHES/com.apple.springboard.plist" root@localhost:/mnt5/mobile/Library/Preferences/com.apple.SpringBoard.plist
sshpass -p alpine scp -o StrictHostKeyChecking=no -P 2222 "$PATCHES/.GlobalPreferences.plist" root@localhost:/mnt5/mobile/Library/Preferences/.GlobalPreferences.plist

sshpass -p alpine scp -o StrictHostKeyChecking=no -P 2222 "$PATCHES/com.apple.purplebuddy.plist" root@localhost:/mnt5/preferences/com.apple.purplebuddy.plist
sshpass -p alpine scp -o StrictHostKeyChecking=no -P 2222 "$PATCHES/com.apple.springboard.plist" root@localhost:/mnt5/preferences/com.apple.springboard.plist

sshpass -p alpine scp -o StrictHostKeyChecking=no -P 2222 "$PATCHES/data_ark.plist" root@localhost:/mnt5/root/Library/Lockdown/data_ark.plist
sshpass -p alpine scp -o StrictHostKeyChecking=no -P 2222 "$PATCHES/data_ark.plist" root@localhost:/mnt5/Library/Lockdown/data_ark.plist

sshpass -p alpine ssh -o StrictHostKeyChecking=no -p 2222 root@localhost "
/usr/sbin/chown 501:501 /mnt5/mobile/Library/Preferences/com.apple.* /mnt5/mobile/Library/Preferences/.Global* 2>/dev/null || true
chmod 600 /mnt5/mobile/Library/Preferences/com.apple.* /mnt5/mobile/Library/Preferences/.Global* 2>/dev/null || true
/usr/sbin/chown 0:0 /mnt5/root/Library/Lockdown/data_ark.plist /mnt5/Library/Lockdown/data_ark.plist 2>/dev/null || true
chmod 644 /mnt5/root/Library/Lockdown/data_ark.plist /mnt5/Library/Lockdown/data_ark.plist 2>/dev/null || true
sync
"

echo "[*] Safely unmounting..."
sshpass -p alpine ssh -o StrictHostKeyChecking=no -p 2222 root@localhost "
/sbin/umount -f /mnt4 2>/dev/null || true
/sbin/umount -f /mnt5 2>/dev/null || true
sync
/sbin/reboot -n || true
"
killall iproxy 2>/dev/null || true
echo "[+] Done! Partitions patched and device rebooted."
