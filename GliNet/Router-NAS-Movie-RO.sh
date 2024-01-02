#!/bin/bash

# Run the ls command and tell the shell to ignore hangups
nohup ls &

# Define the target host
target="nas.dragic.com"

nmap -p 22 -Pn $target | grep -q "22/tcp open"

if [ $? -eq 0 ]; then
  echo "Port 22 is open on $target."
  sshpass -f /root/Adm/pw.txt rsync -avz --ignore-existing /mnt/sda1/DCIM/Movie/RO SFTP@nas.dragic.com:/volume1/Ftp/DashCam/Movie
else
  echo "Port 22 is not open on $target."
fi

# Tell the shell to kill the process when it receives the SIGTERM signal
trap "kill -KILL $$" SIGTERM

# Wait for the process to finish
wait

echo "Process finished"
