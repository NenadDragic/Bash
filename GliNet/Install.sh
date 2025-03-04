#!/bin/bash

opkg install nano git openssh-sftp-server sshpass rsync nmap
opkg update
opkg list-upgradable | cut -f 1 -d ' ' | xargs opkg upgrade

#scp *  root@192.168.8.1:/root/Scripts/Old

#scp -r * root@192.168.1.1:/root 
