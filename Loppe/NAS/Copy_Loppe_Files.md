# Copy Loppe Files - Copy_Loppe_Files.sh

This script copies the contents of the `/home/admina/Loppe/` directory from a remote server to the local directory `/volume1/Dragic/Rap` and then lists the contents of the copied directory.

## How it works

1. The `scp` command is used to securely copy files from the remote server to the local machine.
   - The `-r` option specifies that the copy should be recursive, meaning it will copy all directories and files within the specified directory.
   - `admina@192.168.1.12:/home/admina/Loppe/` is the source directory on the remote server.
   - `/volume1/Dragic/Rap` is the destination directory on the local machine.

2. The `ls -al` command is used to list the contents of the copied directory.
   - The `-al` options provide a detailed listing, including hidden files and detailed file information.

## Usage

Run this script to copy the contents of the `/home/admina/Loppe/` directory from the remote server to the local directory `/volume1/Dragic/Rap` and then list the contents of the copied directory.

Make sure to replace the remote server address and paths if necessary.

```shell
scp -r admina@192.168.1.12:/home/admina/Loppe/ /volume1/Dragic/Rap
ls -al /volume1/Dragic/Rap/Loppe