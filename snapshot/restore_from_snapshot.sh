#!/bin/bash
set -e

ACTIVE_PARTITION="/dev/nvme0n1p3"
EFI_PARTITION="/dev/nvme0n1p1"
BACKUP_ROOT="/home/reventus/backups"

MOUNTPOINT="/mnt/active"

echo "Locating latest snapshot..."

LATEST=$(readlink -f "$BACKUP_ROOT/latest")

if [ ! -d "$LATEST" ]; then
    echo "No snapshot found."
    exit 1
fi

echo "Using snapshot:"
echo "$LATEST"

mkdir -p "$MOUNTPOINT"

echo "Unmounting old mount if necessary..."
umount "$MOUNTPOINT" 2>/dev/null || true

echo "Mounting p3..."
mount "$ACTIVE_PARTITION" "$MOUNTPOINT"

echo "Restoring snapshot to p3..."

rsync -aHAX \
    --numeric-ids \
    --delete \
    "$LATEST"/ \
    "$MOUNTPOINT"/

echo "Fixing fstab..."

P3_UUID=$(blkid -s UUID -o value "$ACTIVE_PARTITION")

cp "$MOUNTPOINT/etc/fstab" \
   "$MOUNTPOINT/etc/fstab.bak"

sed -i \
    "s|UUID=[a-zA-Z0-9-]*[[:space:]]*/[[:space:]]*ext4|UUID=$P3_UUID / ext4|" \
    "$MOUNTPOINT/etc/fstab"

echo "Preparing chroot..."

mount --bind /dev "$MOUNTPOINT/dev"
mount --bind /proc "$MOUNTPOINT/proc"
mount --bind /sys "$MOUNTPOINT/sys"

mkdir -p "$MOUNTPOINT/boot/efi"
mount "$EFI_PARTITION" "$MOUNTPOINT/boot/efi"

echo "Installing bootloader..."

chroot "$MOUNTPOINT" grub-install /dev/nvme0n1
chroot "$MOUNTPOINT" update-grub

echo "Setting p3 as next boot..."

grub-reboot 0 || true

sync

echo "Unmounting..."

umount "$MOUNTPOINT/boot/efi" || true
umount "$MOUNTPOINT/dev" || true
umount "$MOUNTPOINT/proc" || true
umount "$MOUNTPOINT/sys" || true
umount "$MOUNTPOINT" || true

echo "Rebooting..."
reboot