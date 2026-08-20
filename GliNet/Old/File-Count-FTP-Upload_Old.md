# File Count & FTP Upload (Old) - File-Count-FTP-Upload_Old.sh

**Deprecated** — superseded by [../File-Count-SSH-Upload.sh](../File-Count-SSH-Upload.md), which switched from plaintext `sshpass -f /root/Adm/pw.txt` FTP-style rsync to the named-pipe password approach over SSH. Kept here for reference.

Earlier version of the daily orchestration script: runs the SD card and DashCam file-count scripts and the old-file cleanup script, logs their output to daily text files, then uploads the resulting log folders to the NAS over FTP-style rsync.

## How it works

1. For each of three logs (`File-Count-SD`, `File-Count-DashCam`, `File-Delete`), creates today's log file under `/root/<name>/<today>.txt` if it doesn't exist, or appends a timestamped note if it does.
2. Runs the corresponding script (`Count_Files_SD.sh`, `Count_Files_DashCam.sh`, `Delete_10Days_Old_Files.sh`) and appends its output to that day's log file.
3. Uploads all three log folders to the NAS's `Ftp/DashCam` share via `sshpass -v -f /root/Adm/pw.txt rsync -avz`.

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
sshpass -v -f /root/Adm/pw.txt rsync -avz /root/File-Count-SD SFTP@nas.dragic.com:/volume1/Ftp/DashCam
sshpass -v -f /root/Adm/pw.txt rsync -avz /root/File-Count-DashCam SFTP@nas.dragic.com:/volume1/Ftp/DashCam
sshpass -v -f /root/Adm/pw.txt rsync -avz /root/File-Delete SFTP@nas.dragic.com:/volume1/Ftp/DashCam

```
