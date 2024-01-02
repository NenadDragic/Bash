#!/bin/bash

clear
files_count=0

echo '******************************************'
echo '** SD kort - Router ** SD kort - Router **'
files_count=$(ls -l /mnt/sda1/DCIM/Photo | wc -l)
echo "Photos: $files_count"

files_count=$(ls -l /mnt/sda1/DCIM/Movie | wc -l)
echo "Movie: $files_count"

files_count=$(ls -l /mnt/sda1/DCIM/Movie/RO | wc -l)
echo "Movie RO: $files_count" 

files_count=$(ls -l /mnt/sda1/DCIM/Movie/Parking | wc -l)
echo "Movie Parking: $files_count"

echo '** SD kort - Router ** SD kort - Router **'
echo '******************************************'
