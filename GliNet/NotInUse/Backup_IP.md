# Router Home Backup by IP (Not In Use) - Backup_IP.sh

**Not currently in use** — a further-revised variant of [../Old/Backup_IP_Old.sh](../Old/Backup_IP_Old.md), targeting a different NAS module path (`NetBackup/Muddi-E750/...` instead of `NetBackup/BackupData/Muddi-E750/...`). Not wired into the active pipeline (which uses [../Backup.sh](../Backup.md), addressed by hostname); kept for potential future use.

Rsyncs the router's home directory to a date-stamped folder on the NAS backup share, addressing the NAS directly by IP instead of hostname.

## How it works

1. Creates a named pipe (`mkfifo`) at `/tmp/pw_pipe` to pass the NAS password to `sshpass` without exposing it as a plain argument.
2. Streams the password file content into the pipe in the background.
3. Runs `rsync -av` over SSH (as user `Debian_Backup`) to copy the home directory (`~`) to `77.33.216.62::NetBackup/Muddi-E750/<today's date>`.
4. Removes the named pipe afterwards.

```shell
#!/bin/bash

# Backup the data
#sudo rsync -av ~ -e "ssh -l Debian_Backup" 194.255.151.35::NetBackup/BackupData/Muddi-E750/$(date +%Y-%m-%d)


mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe & 
sudo sshpass -f /tmp/pw_pipe sudo rsync -av ~ -e "ssh -l Debian_Backup" 77.33.216.62::NetBackup/Muddi-E750/$(date +%Y-%m-%d)

rm /tmp/pw_pipe

#Exit
exit
```
