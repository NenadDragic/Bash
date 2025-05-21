#!/bin/bash

# Run the ls command and tell the shell to ignore hangups
nohup ls &

# Define the target host
target="http://192.168.1.254"

    process_count=0
    process_count=$(ps w | grep 'DCIM/Movie/Parking' | wc -l)

    if [[ $process_count -eq 1 ]]; then
        echo "Found no processes matching 'DCIM/Movie/Parking'"

        nmap -p 21 192.168.1.254 | grep -q "21/tcp open"

        if [ $? -eq 0 ]; then
            echo "No process matching 'DCIM/Movie/Parking' found"
            #URL of the HTML file
            html_url="http://192.168.1.254/DCIM/Movie/Parking"

  	    # Extract JPG file names from HTML
            jpg_files=$(wget -qO- "$html_url" | grep -oE 'href="/DCIM/Movie/Parking/[^"]+\.MP4"' | sed -E 's/href="\/DCIM\/Movie\/Parking\/([^"]+\.MP4)"/\1/' | sed 's/^\///')


            # Print the value of jpg_files
            echo "MP4 files: $jpg_files"

            # Directory to download files to
            download_dir="/mnt/sda1/DCIM/Movie/Parking"

            # Loop through each JPG file and download if not existing
            for jpg_file in $jpg_files; do
                if [ ! -e "$download_dir/$jpg_file" ]; then
                    wget -P "$download_dir" "http://192.168.1.254/DCIM/Movie/Parking/$jpg_file"
                else
                    echo "File $jpg_file already exists, skipping download."
                fi
            done
       else
            echo "Port 21 is not open on $target."
        fi
    else
        echo "Found $process_count processes matching 'DCIM/Movie/Parking'"
    fi

# Tell the shell to kill the process when it receives the SIGTERM signal
trap "kill -KILL $$" SIGTERM

# Wait for the process to finish
wait

echo "Process finished"
