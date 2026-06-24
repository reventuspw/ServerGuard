#!/bin/bash
set -e

source "$(dirname "$0")/../.env"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
DEST="$BACKUP_ROOT/$TIMESTAMP"

run_timed() {
    local label="$1"; shift
    echo "$label"
    local start=$SECONDS
    "$@"
    echo " -> done in $((SECONDS - start))s"
}

mkdir -p "$DEST"

run_timed "Backing up $REMOTE_USER@$REMOTE_IP to $DEST ..." \
    rsync -aHAX --info=progress2 \
        --numeric-ids \
        --delete \
        -e "ssh -c aes128-gcm@openssh.com" \
        --rsync-path="sudo rsync" \
        --filter='- /proc/' \
        --filter='- /sys/' \
        --filter='- /dev/' \
        --filter='- /run/' \
        --filter='- /tmp/' \
        --filter='- /mnt/' \
        --filter='- /media/' \
        --filter='- /cdrom/' \
        --filter='- /lost+found' \
        --filter='- /swapfile' \
        --filter='- /snap/' \
        --filter='- /share2/' \
        --filter='- /var/snap/' \
        --filter='- /var/lib/snapd/' \
        --filter='- /var/cache/' \
        --filter='- /var/log/' \
        --filter='- /var/tmp/' \
        ${REMOTE_USER}@${REMOTE_IP}:/ "$DEST"

ln -sfn "$DEST" "$BACKUP_ROOT/latest"

echo "Backup complete: $DEST"
