# Router to NAS Movie RO Sync - Router-NAS-Movie-RO.sh

This script rsyncs the locally stored "RO" (protected/locked) DashCam video files from the router's SD card to the NAS backup share.

## How it works

1. Creates a named pipe (`mkfifo`) at `/tmp/pw_pipe` to pass the NAS password to `sshpass` without exposing it as a plain argument.
2. Streams the password file content into the pipe in the background.
3. Runs `rsync -av` over SSH (as user `Debian_Backup`) to copy `/mnt/sda1/DCIM/Movie/RO` to the NAS module `NetBackup/DashCam/Movie`.
4. Removes the named pipe afterwards.

## Usage

Intended to run periodically (e.g. via cron) on the GL.iNet router to back up protected DashCam clips to the NAS.

```shell
#!/bin/bash

mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe & 
sudo sshpass -f /tmp/pw_pipe sudo rsync -av /mnt/sda1/DCIM/Movie/RO -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/DashCam/Movie

rm /tmp/pw_pipe

#Exit
exit
```
