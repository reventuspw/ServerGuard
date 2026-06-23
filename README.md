# Server Guard

Server Guard keeps two Linux servers in an Active/Standby pair to ensure uptime. If the Active node goes down, the Standby automatically restores the latest snapshot and takes over.

Both nodes run `active_monitor.py`, which determines the current role and acts accordingly.

---

## Architecture

```
┌─────────────────────────┐         ┌─────────────────────────┐
│        Node A           │         │        Node B           │
│                         │◄───────►│                         │
│  Role: ACTIVE           │   LAN   │  Role: STANDBY          │
│                         │         │                         │
│  • Production services  │         │  • active_monitor.py    │
│  • Heartbeat (1s)       │         │  • rsync snapshots      │
│  • status.json writer   │         │  • status.json writer   │
└─────────────────────────┘         └─────────────────────────┘
          │                                      │
    ┌─────┴──────┐                        ┌──────┴─────┐
    │  P1 (boot) │                        │  P1 (boot) │  ← EFI / GRUB
    │  P2        │                        │  P2        │  ← Standby OS (immutable)
    │  P3        │                        │  P3        │  ← Active OS (snapshot target)
    └────────────┘                        └────────────┘
```

- **Active** boots from P3, runs services, writes a heartbeat every second.
- **Standby** boots from P2, monitors the Active node, pulls remote snapshots on a configurable interval.
- If Active goes down -> Standby formats P3, restores latest snapshot, reboots as Active.
- If both report Active -> both drop to Standby, newest heartbeat wins.
- If both report Standby -> newest heartbeat becomes Active.

---

## Configuration

Copy `.env.example` to `.env` and fill in the values before running.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/create_snapshot.sh` | Snapshot local filesystem |
| `scripts/backup_remote_pc.sh` | Pull snapshot from Active node over SSH |
| `scripts/restore_from_snapshot.sh` | Restore snapshot to P3 and reboot as Active |
| `scripts/switch_to_standby.sh` | Reboot into P2 (Standby partition) |
