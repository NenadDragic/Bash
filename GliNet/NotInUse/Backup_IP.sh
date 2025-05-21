#!/bin/bash

# Backup the data
#sudo rsync -av ~ -e "ssh -l Debian_Backup" 194.255.151.35::NetBackup/BackupData/Muddi-E750/$(date +%Y-%m-%d)


mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe & 
sudo sshpass -f /tmp/pw_pipe sudo rsync -av ~ -e "ssh -l Debian_Backup" 77.33.216.62::NetBackup/Muddi-E750/$(date +%Y-%m-%d)

rm /tmp/pw_pipe

#Exit
exit
