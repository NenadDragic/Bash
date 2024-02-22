#!/bin/bash

# Define the target host
target="http://192.168.1.254"

nmap -p 21 192.168.1.254 | grep -q "21/tcp open"

if [ $? -eq 0 ]; then
    #URL of the HTML file
    html_url="http://192.168.1.254/dcim/Photo"

    # Extract JPG file names from HTML
    jpg_files=$(wget -qO- "$html_url" | grep -oE 'href="/dcim/Photo/[0-9]+_[0-9]+_[0-9]+_[RF]\.JPG"' | sed -E 's/href="\/dcim\/Photo\/([0-9]+_[0-9]+_[0-9]+_[RF]\.JPG)"/\1/')

    # Print the value of jpg_files
    echo "JPG files: $jpg_files"

    # Directory to download files to
    download_dir="/mnt/sda1/DCIM/Photo"

    # Loop through each JPG file and download if not existing
    for jpg_file in $jpg_files; do
        if [ ! -e "$download_dir/$jpg_file" ]; then
            wget -P "$download_dir" "http://192.168.1.254/dcim/Photo/$jpg_file"
        else
            echo "File $jpg_file already exists, skipping download."
        fi
done

else
  echo "Port 21 is not open on $target."
fi
