### To Do:

- Create bash script that saves a snapshot of the running OS.                           [DONE]

- Create a bash script that rebuilds a snapshot on another partition and boots into it. [DONE]

- Create a bash script that switches to the old partition.                              [DONE]

- Create a bash script that creates a snapshot of a remote server to later rebuild.     [DONE]

- Create a Python script that monitors the state of a remote server.                    [DONE]

- Make `server_monitor.py` run `/scripts/backup_remote_pc.sh` every X minutes.

- Make `server_monitor.py` verify if a server is down based on multiple factors such as unreachable via ping, API request fails, internet connection, etc.

- Make `server_monitor.py` create a status file which logs both of the server's status and last hearbeat timestamp, this is so that when the other server takes over, it knows where to carry on from and doesn't rerun already ran processes.

- Make server check if the other server is in active or standby mode before taking over to ensure both servers aren't active.

- If main server is down, `server_monitor.py` runs `/scripts/restore_from_snapshot.sh`.

- Make `server_monitor.py` monitor the status of the 2nd PC and run `/scripts/switch_to_standby.sh` or `/scripts/restore_from_snapshot.sh`.
