x!/bin/bash

# Run the ls command and tell the shell to ignore hangups
nohup ls &

# Define the target host
target="nas.dragic.com"

nmap -p 22 -Pn $target | grep -q "22/tcp open"

if [ $? -eq 0 ]; then
  echo "Port 22 is open on $target."
  newest_file=$(ls -t /mnt/sda1/DCIM/Movie/*.MP4 | head -n 1)
  echo $newest_file
  sshpass -p 'TJj2Fy*544ZJ$!Yv2Q77cHzJ' rsync -avzh --ignore-existing $newest_file SFTP@nas.dragic.com:/volume1/Ftp/DashCam/Movie
  mv $newest_file $newest_file.OLD
else
  echo "Port 22 is not open on $target."
fi

# Tell the shell to kill the process when it receives the SIGTERM signal
trap "kill -KILL $$" SIGTERM
