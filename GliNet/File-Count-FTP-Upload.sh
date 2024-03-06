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
