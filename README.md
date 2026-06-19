- Move all scripts from `snapshot/` to `/usr/local/bin/`

- Make `create_snapshot.sh` executable: sudo chmod +x /usr/local/bin/create_snapshot.sh
- Make `restore_from_snapshot` executable: sudo chmod +x /usr/local/bin/restore_from_snapshot.sh

- sshfs package will be needed for accessing files on the other PC: `sudo apt istall sshfs`