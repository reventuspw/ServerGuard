### To Do:
- Make `server_monitor.py` run `/scripts/backup_remote_pc.sh` every X minutes.

- Make `server_monitor.py` verify if a server is down based on multiple factors such as unreachable via ping, API request fails, internet connection, etc.

- Make `server_monitor.py` create a status file which logs both of the server's status and last hearbeat timestamp, this is so that when the other server takes over it knows where to carry on from and doesn't rerun already ran processes.

- Make server check if the other server is in active or standby mode before taking over to ensure both servers aren't active.

- If main server is down, `server_monitor.py` rebuilds from latest backup and boots into the rebuilt OS snapshot.
