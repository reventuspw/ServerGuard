#!/bin/bash
set -e

BACKUP_ROOT="/home/reventus/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
DEST="$BACKUP_ROOT/$TIMESTAMP"

mkdir -p "$DEST"

echo "Creating snapshot..."

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