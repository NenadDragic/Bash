#!/bin/bash

process_count=0
process_count=$(ps w | grep 'DCIM/Movie' | wc -l)

if [[ $process_count -eq 0 ]]; then
    echo "No process matching 'DCIM/Movie' found"

	# Define the target host
	target="http://192.168.1.254"

	nmap -p 21 192.168.1.254 | grep -q "21/tcp open"

	if [ $? -eq 0 ]; then
	    #URL of the HTML file
	    html_url="http://192.168.1.254/DCIM/Movie"

	    # Extract JPG file names from HTML
	    jpg_files=$(wget -qO- "$html_url" | grep -oE 'href="/DCIM/Movie/[0-9]+_[0-9]+_[0-9]+_[RF]\.MP4"' | sed -E 's/href="\/DCIM\/Movie\/([0-9]+_[0-9]+_[0-9]+_[RF]\.MP4)"/\1/')

	    # Print the value of jpg_files
	    echo "MP4 files: $jpg_files"

	    # Directory to download files to
	    download_dir="/mnt/sda1/DCIM/Movie"

	    # Loop through each JPG file and download if not existing
	    for jpg_file in $jpg_files; do
	        if [ ! -e "$download_dir/$jpg_file" ]; then
	            wget -P "$download_dir" "http://192.168.1.254/DCIM/Movie/$jpg_file"
	        else
	            echo "File $jpg_file already exists, skipping download."
	        fi
	    done


	else
	  echo "Port 21 is not open on $target."
	fi
else
    echo "Found $process_count processes matching 'DCIM/Movie'"
fi

