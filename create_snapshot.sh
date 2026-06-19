#!/bin/bash

set -e

PARTITION="/dev/nvme0n1p1"
SAVE_DIR="/home/user/snapshots"

mkdir -p "$SAVE_DIR"

SNAPSHOT_FILE="$SAVE_DIR/snapshot_$(basename "$PARTITION")_$(date +%Y%m%d_%H%M%S).fsa"

echo "Freezing filesystem..."
sudo fsfreeze -f /

echo "Saving snapshot to $SNAPSHOT_FILE ..."
sudo fsarchiver savefs "$SNAPSHOT_FILE" "$PARTITION"

echo "Unfreezing filesystem..."
sudo fsfreeze -u /

echo "Done: $SNAPSHOT_FILE"
