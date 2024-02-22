#!/bin/bash

sh /root/Scripts/Count_Files_SD.sh  > /root/File-Count-SD/"$(date '+%Y%m%d_%H%M%S').txt"
sh /root/Scripts/Count_Files_DashCam.sh > /root/File-Count-DashCam/"$(date '+%Y%m%d_%H%M%S').txt"

sshpass -v -f /root/Adm/pw.txt rsync -avz --ignore-existing /root/File-Count-SD SFTP@nas.dragic.com:/volume1/Ftp/DashCam
sshpass -v -f /root/Adm/pw.txt rsync -avz --ignore-existing /root/File-Count-DashCam SFTP@nas.dragic.com:/volume1/Ftp/DashCam
