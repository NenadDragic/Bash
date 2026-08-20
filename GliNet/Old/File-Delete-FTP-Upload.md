# File Delete & FTP Upload (Old) - File-Delete-FTP-Upload.sh

**Deprecated** — superseded by the cleanup portion of [../File-Count-SSH-Upload.sh](../File-Count-SSH-Upload.md), which moved from plaintext `sshpass -f /root/Adm/pw.txt` FTP-style rsync to the named-pipe password approach over SSH. Kept here for reference.

Runs the old-file cleanup script, logs its output to a timestamped file, and uploads the log folder to the NAS via FTP-style rsync.

## How it works

1. Runs `Delete_10Days_Old_Files.sh`, redirecting its output to `/root/File-Delete/<timestamp>.txt`.
2. Uploads the `/root/File-Delete` folder to the NAS's `Ftp/DashCam` share via `sshpass -f /root/Adm/pw.txt rsync -avz --ignore-existing`.

```shell
#!/bin/bash

sh /root/Scripts/Delete_10Days_Old_Files.sh  > /root/File-Delete/"$(date '+%Y%m%d_%H%M%S').txt"

sshpass -f /root/Adm/pw.txt rsync -avz --ignore-existing /root/File-Delete SFTP@nas.dragic.com:/volume1/Ftp/DashCam
```
