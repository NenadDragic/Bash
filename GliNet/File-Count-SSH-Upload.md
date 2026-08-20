# File Count & SSH Upload - File-Count-SSH-Upload.sh

This is the router's daily orchestration script: it runs the SD card and DashCam file-count scripts and the old-file cleanup script, logs their output to daily text files, then uploads the resulting log folders to the NAS over SFTP.

## How it works

1. For each of three logs (`File-Count-SD`, `File-Count-DashCam`, `File-Delete`), creates today's log file under `/root/<name>/<today>.txt` if it doesn't exist, or appends a timestamped note if it does.
2. Runs the corresponding script (`Count_Files_SD.sh`, `Count_Files_DashCam.sh`, `Delete_10Days_Old_Files.sh`) and appends its output to that day's log file.
3. Contains a commented-out block showing an earlier `sshpass`/`rsync` approach for uploading the log folders.
4. For each of the three log folders, creates a named pipe (`mkfifo`), streams the NAS password into it in the background, and runs `sshpass`-authenticated `rsync -av` over SSH (as user `Debian_Backup`) to copy the folder to the NAS module `NetBackup/DashCam`, then removes the pipe.

## Usage

Intended to run daily (e.g. via cron) on the GL.iNet router as the main scheduled job that ties together file counting, cleanup logging, and NAS upload.

```shell
#!/bin/bash


#
# SD Card
#

# Get today's date
today=$(date +%Y-%m-%d)

# Define the filename
filename="/root/File-Count-SD/${today}.txt"

# Check if the file already exists
if [ ! -f "$filename" ]; then
    # If the file doesn't exist, create it
    echo "This is a new file created on ${today}" > "$filename"
else
    # If the file does exist, append to it
    echo "Additional data added on $(date)" >> "$filename"
fi

# Run the shell script and get its output
output=$(sh /root/Scripts/Count_Files_SD.sh)

# Append the output of the shell script to the file
echo "Output of the shell script: " >> "$filename"
echo "$output" >> "$filename"

#
# Dashcam
#

# Define the filename
filename="/root/File-Count-DashCam/${today}.txt"

# Check if the file already exists
if [ ! -f "$filename" ]; then
    # If the file doesn't exist, create it
    echo "This is a new file created on ${today}" > "$filename"
else
    # If the file does exist, append to it
    echo "Additional data added on $(date)" >> "$filename"
fi

# Run the shell script and get its output
output=$(sh /root/Scripts/Count_Files_DashCam.sh)

# Append the output of the shell script to the file
echo "Output of the shell script: " >> "$filename"
echo "$output" >> "$filename"


#
# File Delete
#

# Define the filename
filename="/root/File-Delete/${today}.txt"

# Check if the file already exists
if [ ! -f "$filename" ]; then
    # If the file doesn't exist, create it
    echo "This is a new file created on ${today}" > "$filename"
else
    # If the file does exist, append to it
    echo "Additional data added on $(date)" >> "$filename"
fi

# Run the shell script and get its output
output=$(sh /root/Scripts/Delete_10Days_Old_Files.sh)

# Append the output of the shell script to the file
echo "Output of the shell script: " >> "$filename"
echo "$output" >> "$filename"

#
# FTP files
#
#sshpass -v -f /root/Adm/pw.txt rsync -avz /root/File-Count-SD SFTP@nas.dragic.com:/volume1/Ftp/DashCam
#sshpass -v -f /root/Adm/pw.txt rsync -avz /root/File-Count-DashCam SFTP@nas.dragic.com:/volume1/Ftp/DashCam
#sshpass -v -f /root/Adm/pw.txt rsync -avz /root/File-Delete SFTP@nas.dragic.com:/volume1/Ftp/DashCam

mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe & 
sudo sshpass -f /tmp/pw_pipe sudo rsync -av /root/File-Count-SD -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/DashCam

rm /tmp/pw_pipe


mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe & 
sudo sshpass -f /tmp/pw_pipe sudo rsync -av /root/File-Count-DashCam -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/DashCam

rm /tmp/pw_pipe

mkfifo /tmp/pw_pipe
cat ../root/Adm/pw_nas.txt > /tmp/pw_pipe & 
sudo sshpass -f /tmp/pw_pipe sudo rsync -av /root/File-Delete -e "ssh -l Debian_Backup" nas.dragic.com::NetBackup/DashCam

rm /tmp/pw_pipe
```
