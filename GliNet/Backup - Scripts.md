Backup Scripts Script
This script (backup_scripts.sh) uses the scp command to securely copy files from the "/root/Scripts" and "/root/Scripts/Old_Scripts" directories to a remote server (192.168.1.194) in the specified destination directories ("/home/nenad/Scripts-GL-E750" and "/home/nenad/Scripts-GL-E750/Old_Scripts").

## Usage
1. Ensure you have permission to execute the script. If not, grant permission by running:

chmod +x backup_scripts.sh

2. Execute the script by running:
./backup_scripts.sh

The script will securely copy files from the specified local directories to the corresponding remote directories on the server.

## Explanation

The script utilizes the scp command to copy files from the local "/root/Scripts" and "/root/Scripts/Old_Scripts" directories to the remote server at IP address 192.168.1.194.

scp -r -v /root/Scripts/*.* nenad@192.168.1.194:/home/nenad/Scripts-GL-E750
scp -r -v /root/Scripts/Old_Scripts/*.* nenad@192.168.1.194:/home/nenad/Scripts-GL-E750/Old_Scripts

* The first line copies all files from "/root/Scripts" to "/home/nenad/Scripts-GL-E750" on the remote server.
* The second line copies all files from "/root/Scripts/Old_Scripts" to "/home/nenad/Scripts-GL-E750/Old_Scripts" on the remote server.