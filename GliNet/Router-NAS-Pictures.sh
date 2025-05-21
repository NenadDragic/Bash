#!/bin/bash

# Backup the data
#sudo rsync -av ~ -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/BackupData/Muddi-E750/$(date +%Y-%m-%d)


mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe & 
sudo sshpass -f /tmp/pw_pipe sudo rsync -av /mnt/sda1/DCIM/Photo -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/DashCam

rm /tmp/pw_pipe

#Exit
exit
