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

