#!/bin/bash


echo '**************************************'
echo '** File delete 10 days on SD Router **'
echo '**************************************'

echo ""
find /mnt/sda1/ -type f -mtime +1 | tee /root/File-Delete/$(date +%Y-%m-%d).txt | xargs rm -f

echo ""
echo '**************************************'
echo '** File delete 10 days on SD Router **'
echo '**************************************'

