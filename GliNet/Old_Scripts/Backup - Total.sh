#!/bin/bash

scp -r -v -d /root/* nenad@192.168.1.194:/home/nenad/Backup-GL-E750/root
scp -r -v -d /etc/* nenad@192.168.1.194:/home/nenad/Backup-GL-E750/etc
scp -r -v -d /Adm/* nenad@192.168.1.194:/home/nenad/Backup-GL-E750/Adm
scp -r -v -d /File-Count/* nenad@192.168.1.194:/home/nenad/Backup-GL-E750/File-Count



