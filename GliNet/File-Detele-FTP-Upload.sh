#!/bin/bash

sh /root/Scripts/Delete_10Days_Old_Files.sh  > /root/File-Delete/"$(date '+%Y%m%d_%H%M%S').txt"

sshpass -f /root/Adm/pw.txt rsync -avz --ignore-existing /root/File-Delete SFTP@nas.dragic.com:/volume1/Ftp/DashCam
