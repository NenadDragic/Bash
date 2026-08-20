# Router to NAS Movie Sync (Old) - Router-NAS-Movie_Old.sh

**Deprecated/superseded** — the NotInUse folder has a further-revised variant, [../../NotInUse/Router-NAS-Movie.sh](../../NotInUse/Router-NAS-Movie.md), which switched from plaintext `sshpass -f /root/Adm/pw.txt` FTP-style rsync to the named-pipe password approach over SSH. Kept here for reference.

Syncs the entire locally stored DashCam `Movie` folder to the NAS over SFTP, gated on an `nmap` port-22 check.

## How it works

1. Backgrounds a no-op `nohup ls &` and defines the NAS target host.
2. Checks if port 22 (SSH) is open on the NAS via `nmap`.
3. If open, runs `sshpass -f /root/Adm/pw.txt rsync -avzh --ignore-existing` to copy `/mnt/sda1/DCIM/Movie/` to the NAS's `Ftp/DashCam/Movie` share over SFTP.
4. Sets a `SIGTERM` trap to hard-kill the process, then `wait`s before exiting.

```shell
#!/bin/bash

# Run the ls command and tell the shell to ignore hangups
nohup ls &

# Define the target host
target="nas.dragic.com"

nmap -p 22 -Pn $target | grep -q "22/tcp open"

if [ $? -eq 0 ]; then
  echo "Port 22 is open on $target."
  sshpass -f /root/Adm/pw.txt rsync -avzh --ignore-existing /mnt/sda1/DCIM/Movie/ SFTP@nas.dragic.com:/volume1/Ftp/DashCam/Movie
else
  echo "Port 22 is not open on $target."
fi

# Tell the shell to kill the process when it receives the SIGTERM signal
trap "kill -KILL $$" SIGTERM

# Wait for the process to finish
wait

echo "Process finished"

```
