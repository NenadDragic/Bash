# Router to NAS Movie Parking Sync (Not In Use) - Router-NAS-Movie-Parking.sh

**Not currently in use** — a revised variant of [../Old/Router-NAS-Movie-Parking_Old.sh](../Old/Router-NAS-Movie-Parking_Old.md) using the named-pipe SSH password approach instead of plaintext `sshpass -f` FTP-style rsync, but not wired into the active [../File-Count-SSH-Upload.sh](../File-Count-SSH-Upload.md) pipeline. Kept for potential future use.

Rsyncs the locally stored DashCam "Parking" mode videos to the NAS.

## How it works

1. Creates a named pipe (`mkfifo`) at `/tmp/pw_pipe` to pass the NAS password to `sshpass` without exposing it as a plain argument.
2. Streams the password file content into the pipe in the background.
3. Runs `rsync -av` over SSH (as user `Debian_Backup`) to copy `/mnt/sda1/DCIM/Movie/Parking` to the NAS module `NetBackup/DashCam/Movie`.
4. Removes the named pipe afterwards.

```shell
#!/bin/bash

# Backup the data
# sudo rsync -av ~ -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/BackupData/Muddi-E750/$(date +%Y-%m-%d)


mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe & 
sudo sshpass -f /tmp/pw_pipe sudo rsync -av /mnt/sda1/DCIM/Movie/Parking -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/DashCam/Movie

rm /tmp/pw_pipe

#Exit
exit
```
