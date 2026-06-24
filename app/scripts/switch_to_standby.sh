#!/bin/bash
set -e

source "$(dirname "$0")/../.env"

CURRENT_ROOT=$(findmnt -n -o SOURCE /)
if [ "$CURRENT_ROOT" = "$STANDBY_PARTITION" ]; then
    echo "ERROR: Already booted from $STANDBY_PARTITION"
    exit 1
fi

run_timed() {
    local label="$1"; shift
    echo "$label"
    local start=$SECONDS
    "$@"
    echo " -> done in $((SECONDS - start))s"
}

TARGET_UUID=$(blkid -s UUID -o value "$STANDBY_PARTITION")

echo "Unmounting p2 if mounted..."
umount "$STANDBY_PARTITION" 2>/dev/null || true

echo "Reading kernel from p2..."
start=$SECONDS
TMPMT=$(mktemp -d)
mount -o ro "$STANDBY_PARTITION" "$TMPMT"
KERNEL=$(ls "$TMPMT/boot/vmlinuz-"* 2>/dev/null | sort -V | tail -1 | sed "s|$TMPMT||")
INITRD=$(ls "$TMPMT/boot/initrd.img-"* 2>/dev/null | sort -V | tail -1 | sed "s|$TMPMT||")
umount "$TMPMT"
rmdir "$TMPMT"
echo " -> done in $((SECONDS - start))s"

if [ -z "$KERNEL" ] || [ -z "$INITRD" ]; then
    echo "ERROR: Could not find kernel or initrd on $STANDBY_PARTITION"
    exit 1
fi

echo "  kernel: $KERNEL"
echo "  initrd: $INITRD"

CUSTOM="/etc/grub.d/40_custom"
if ! grep -q "$TARGET_UUID" "$CUSTOM" 2>/dev/null; then
    echo "Adding GRUB entry for p2..."
    cat >> "$CUSTOM" <<EOF

menuentry '$STANDBY_ENTRY_TITLE' {
    search --no-floppy --fs-uuid --set=root $TARGET_UUID
    linux $KERNEL root=UUID=$TARGET_UUID ro quiet splash
    initrd $INITRD
}
EOF
    run_timed "Updating GRUB..." update-grub
fi

echo "Switching to: $STANDBY_ENTRY_TITLE"
grub-reboot "$STANDBY_ENTRY_TITLE"

echo "Rebooting into p2..."
reboot
