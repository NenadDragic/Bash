# SD Card File Count - Count_Files_SD.sh

This script prints a status report for the router's SD card: photo/video counts by folder, disk usage, and the WWAN0 network interface's IP address.

## How it works

1. Prints a header and the router's `uptime`.
2. Counts files in `/mnt/sda1/DCIM/Photo`, `/mnt/sda1/DCIM/Movie`, `/mnt/sda1/DCIM/Movie/RO`, and `/mnt/sda1/DCIM/Movie/Parking`, printing each count.
3. Prints disk usage via `df -h`.
4. Prints the `wwan0` interface's IPv4 address via `ip address show`.

## Usage

Run this script on the GL.iNet router to get a quick overview of the DashCam SD card contents and connectivity status.

```shell
#!/bin/bash

files_count=0

echo '*****************************************'
echo '** SD kort - Router ** SD kort - Router **'
echo '*****************************************'
echo ""
echo "Uptime: $(uptime)"
echo ""

files_count=$(ls -l /mnt/sda1/DCIM/Photo | wc -l)
echo "Photos: $files_count"

files_count=$(ls -l /mnt/sda1/DCIM/Movie | wc -l)
echo "Movie: $files_count"

files_count=$(ls -l /mnt/sda1/DCIM/Movie/RO | wc -l)
echo "Movie RO: $files_count" 

files_count=$(ls -l /mnt/sda1/DCIM/Movie/Parking | wc -l)
echo "Movie Parking: $files_count"

echo ""
echo "Disk Info:"
echo $(df -h)
echo ""
echo "WWAN0:"
echo $(ip address show wwan0 | grep 'inet')
echo ""
echo '*****************************************'
echo '** SD kort - Router ** SD kort - Router **'
echo '*****************************************'
```
