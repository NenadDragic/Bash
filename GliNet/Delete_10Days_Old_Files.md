# Delete Old Files - Delete_10Days_Old_Files.sh

This script cleans up old files on the router's SD card and log folders: raw SD card files older than 10 days, and DashCam/log files older than 30 days.

## How it works

1. Finds all files under `/mnt/sda1/` older than 10 days, logs their paths to `/root/File-Delete/<today>.txt`, and deletes them via `xargs rm -f`.
2. Finds all files older than 30 days under `/root/File-Count-DashCam/`, `/root/File-Count-SD/`, and `/root/File-Delete/` (in that order), logging each batch to the same day's log file (each `find` overwrites the previous log via `tee`) before deleting them.

## Usage

Intended to run periodically (e.g. via cron) on the GL.iNet router to keep the SD card and log directories from filling up.

```shell
#!/bin/bash
echo '**************************************'
echo '** File delete 10 days on SD Router **'
echo '**************************************'
echo ""
find /mnt/sda1/ -type f -mtime +10 | tee /root/File-Delete/$(date +%Y-%m-%d).txt | xargs rm -f
echo ""
echo '**************************************'
echo '** File delete 10 days on SD Router **'
echo '**************************************'

echo '**************************************'
echo '** File delete 30 days on SD Router **'
echo '**************************************'
echo ""
find /root/File-Count-DashCam/ -type f -mtime +30 | tee /root/File-Delete/$(date +%Y-%m-%d).txt | xargs rm -f
find /root/File-Count-SD/ -type f -mtime +30 | tee /root/File-Delete/$(date +%Y-%m-%d).txt | xargs rm -f
find /root/File-Delete/ -type f -mtime +30 | tee /root/File-Delete/$(date +%Y-%m-%d).txt | xargs rm -f
echo ""
echo '**************************************'
echo '** File delete 30 days on SD Router **'
echo '**************************************'
```
