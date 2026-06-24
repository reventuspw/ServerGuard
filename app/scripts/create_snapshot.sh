#!/bin/bash
set -e

source "$(dirname "$0")/../.env"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
DEST="$BACKUP_ROOT/$TIMESTAMP"

mkdir -p "$DEST"

run_timed() {
    local label="$1"; shift
    echo "$label"
    local start=$SECONDS
    "$@"
    echo " -> done in $((SECONDS - start))s"
}

run_timed "Creating snapshot..." \
    rsync -aHAX \
        --numeric-ids \
        --delete \
        --exclude=/proc/** \
        --exclude=/sys/** \
        --exclude=/dev/** \
        --exclude=/run/** \
        --exclude=/tmp/** \
        --exclude=/mnt/** \
        --exclude=/media/** \
        --exclude=/lost+found \
        --exclude="$BACKUP_ROOT/**" \
        / "$DEST"

ln -sfn "$DEST" "$BACKUP_ROOT/latest"

echo "Snapshot complete: $DEST"
