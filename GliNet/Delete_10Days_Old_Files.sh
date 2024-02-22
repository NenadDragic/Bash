#!/bin/bash

#find /mnt/sda1/ -type f -mtime +10
#find /mnt/sda1/ -type f -mtime +10  | xargs rm -f
find /mnt/sda1/ -type f -mtime +10 | tee /root/File-Delete/$(date +%y%m%d_%H%M%S).txt | xargs rm -f


