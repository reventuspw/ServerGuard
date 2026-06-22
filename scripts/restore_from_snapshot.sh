#!/bin/bash
set -e

source "$(dirname "$0")/../.env"

run_timed() {
    local label="$1"; shift
    echo "$label"
    local start=$SECONDS
    "$@"
    echo "  -> done in $((SECONDS - start))s"
}

echo "Locating latest snapshot..."

LATEST=$(readlink -f "$BACKUP_ROOT/latest")

if [ ! -d "$LATEST" ]; then
    echo "No snapshot found."
    exit 1
fi

echo "Using snapshot:"
echo "$LATEST"

CURRENT_ROOT=$(findmnt -n -o SOURCE /)

if [ "$CURRENT_ROOT" = "$ACTIVE_PARTITION" ]; then
    echo "ERROR: Currently booted from $ACTIVE_PARTITION"
    echo "Refusing to continue."
    exit 1
fi

mkdir -p "$MOUNTPOINT"

echo "Unmounting old mounts..."
umount -l "$MOUNTPOINT/boot/efi" 2>/dev/null || true
umount -l "$MOUNTPOINT/dev"      2>/dev/null || true
umount -l "$MOUNTPOINT/proc"     2>/dev/null || true
umount -l "$MOUNTPOINT/sys"      2>/dev/null || true
umount -l "$MOUNTPOINT"          2>/dev/null || true
umount "$ACTIVE_PARTITION"       2>/dev/null || true

run_timed "Formatting p3..."          mkfs.ext4 -F "$ACTIVE_PARTITION"
run_timed "Mounting p3..."            mount "$ACTIVE_PARTITION" "$MOUNTPOINT"

run_timed "Restoring snapshot to p3..." \
    rsync -aHAX \
        --numeric-ids \
        --delete \
        "$LATEST"/ \
        "$MOUNTPOINT"/

echo "Fixing fstab..."
P3_UUID=$(blkid -s UUID -o value "$ACTIVE_PARTITION")
cp "$MOUNTPOINT/etc/fstab" "$MOUNTPOINT/etc/fstab.bak"
sed -i \
    "s|UUID=[a-zA-Z0-9-]*[[:space:]]*/[[:space:]]*ext4|UUID=$P3_UUID / ext4|" \
    "$MOUNTPOINT/etc/fstab"
echo "  -> done"

echo "Preparing chroot..."
mount --bind /dev "$MOUNTPOINT/dev"
mount --bind /proc "$MOUNTPOINT/proc"
mount --bind /sys "$MOUNTPOINT/sys"
mkdir -p "$MOUNTPOINT/boot/efi"
mount "$EFI_PARTITION" "$MOUNTPOINT/boot/efi"
echo "  -> done"

run_timed "Installing bootloader..."  chroot "$MOUNTPOINT" grub-install /dev/nvme0n1
run_timed "Updating grub..."          chroot "$MOUNTPOINT" update-grub

sync

echo "Cleaning up..."
umount -l "$MOUNTPOINT/boot/efi" || true
umount -l "$MOUNTPOINT/dev"      || true
umount -l "$MOUNTPOINT/proc"     || true
umount -l "$MOUNTPOINT/sys"      || true
umount -l "$MOUNTPOINT"          || true

echo "Restore complete."
echo "Rebooting..."
reboot
