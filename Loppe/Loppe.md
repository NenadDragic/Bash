# Loppe Script - Loppe.sh

This script runs a Python script, checks for the existence of an output file, renames it with a timestamp, and changes the ownership of the resulting files.

## How it works

1. The `sudo python3 ~/Loppe/main.py` command runs the Python script located at `~/Loppe/main.py` with superuser privileges.

2. The script checks if the file `/home/admina/Loppe/output.csv` exists:
   - If the file exists, it renames `output.csv` to a filename with the current timestamp in the format `YYYY-MM-DD_HH-MM-SS.csv`.
   - If the file does not exist, it prints a message indicating that `output.csv` does not exist.

3. The `sudo chown admina:admina /home/admina/Loppe/*.csv` command changes the ownership of all `.csv` files in the `/home/admina/Loppe/` directory to the user `admina` and group `admina`.

## Usage

Run this script to execute the Python script, rename the output file if it exists, and change the ownership of the resulting files.

Make sure to replace paths and filenames if necessary.

```shell
#!/bin/bash

# Run the Python script
sudo python3 ~/Loppe/main.py

# Check if output.csv exists
if [ -f "/home/admina/Loppe/output.csv" ]; then
    # Rename output.csv to a timestamped filename
    mv /home/admina/Loppe/output.csv "/home/admina/Loppe/$(date +'%Y-%m-%d_%H-%M-%S').csv"
    echo "output.csv has been renamed to $(date +'%Y-%m-%d_%H-%M-%S').csv"
else
    echo "output.csv does not exist."
fi

sudo chown admina:admina /home/admina/Loppe/*.csv