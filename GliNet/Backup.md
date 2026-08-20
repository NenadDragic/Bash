# Router Home Backup - Backup.sh

This script rsyncs the router's home directory to a date-stamped folder on the NAS backup share.

## How it works

1. Creates a named pipe (`mkfifo`) at `/tmp/pw_pipe` to pass the NAS password to `sshpass` without exposing it as a plain argument.
2. Streams the password file content into the pipe in the background.
3. Runs `rsync -av` over SSH (as user `Debian_Backup`) to copy the home directory (`~`) to the NAS module `NetBackup/Muddi-E750/<today's date>`.
4. Removes the named pipe afterwards.

## Usage

Intended to run periodically (e.g. via cron) on the GL.iNet router to back up its home directory to the NAS.

```shell
#!/bin/bash

# Backup the data
#sudo rsync -av ~ -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/BackupData/Muddi-E750/$(date +%Y-%m-%d)


mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe & 
sudo sshpass -f /tmp/pw_pipe sudo rsync -av ~ -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/Muddi-E750/$(date +%Y-%m-%d)

rm /tmp/pw_pipe

#Exit
exit
```
