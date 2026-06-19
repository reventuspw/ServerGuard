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
    echo "  -> done in $((SECONDS - start))s"
}

mkdir -p "$DEST"

run_timed "Backing up $REMOTE_USER@$REMOTE_IP to $DEST ..." \
    rsync -aHAX \
        --numeric-ids \
        --delete \
        -e ssh \
        --exclude=/proc/** \
        --exclude=/sys/** \
        --exclude=/dev/** \
        --exclude=/run/** \
        --exclude=/tmp/** \
        --exclude=/mnt/** \
        --exclude=/media/** \
        --exclude=/lost+found \
        ${REMOTE_USER}@${REMOTE_IP}:/ "$DEST"

ln -sfn "$DEST" "$BACKUP_ROOT/latest"

echo "Backup complete: $DEST"
