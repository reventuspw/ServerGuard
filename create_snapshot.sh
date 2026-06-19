#!/bin/bash

set -e

BACKUP_ROOT="/home/reventus/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
DEST="$BACKUP_ROOT/$TIMESTAMP"

mkdir -p "$DEST"

echo "Starting backup to $DEST ..."
start=$SECONDS

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

echo "  -> done in $((SECONDS - start))s"
echo "Backup completed: $DEST"
