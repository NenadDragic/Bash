#!/bin/bash

mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe & 
sudo sshpass -f /tmp/pw_pipe sudo rsync -av /mnt/sda1/DCIM/Movie -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/DashCam/Movie

rm /tmp/pw_pipe

#Exit
exit
