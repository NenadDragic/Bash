#!/bin/bash

# Variables
USER='SFTP'
HOST='nas.dragic.com'
PASSWORD='TJj2Fy*544ZJ$!Yv2Q77cHzJ'
LOCAL_DIR='/mnt/sda1/DCIM/Photo'
REMOTE_DIR='/DashCam/Photo'

# Create a temporary file
TMPFILE=$(mktemp sftp-commands.XXXXXX)

# Put the SFTP commands into the temporary file
echo "lcd $LOCAL_DIR" >> $TMPFILE
echo "cd $REMOTE_DIR" >> $TMPFILE
echo "mput *.*" >> $TMPFILE

# Use sshpass to run the SFTP commands from the temporary file
sshpass -p $PASSWORD -v sftp -oBatchMode=no -b $TMPFILE $USER@$HOST

# Delete the temporary file
rm -f $TMPFILE
