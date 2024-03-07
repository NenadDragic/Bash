#!/bin/bash

# Set the FTP server details
HOST="nas.dragic.com"
USER="sftp"
PASS=""
REMOTE_DIR="/DashCam"
LOCAL_DIR="/mnt/sda1/DCIM/Photo"

# Manually verify and update the host key
#ssh-keygen -R "$HOST"
ssh -o StrictHostKeyChecking=no "$USER@$HOST" exit

# Connect and transfer files using lftp
export LFTP_OPSSH_NO_HOST_VERIFY=1

lftp -u "$USER","$PASS" sftp://"$HOST" <<EOF
set ftp:ssl-allow no
mirror -R "$LOCAL_DIR" "$REMOTE_DIR"
bye
EOF
