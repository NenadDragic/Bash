# Date Sort Files - DatoSortFiles.sh

This script organizes CSV files in the current directory into date-named subfolders, based on a `YYYY-MM-DD_*.csv` filename pattern, while keeping the oldest file for each date in the root.

## How it works

1. Scans the current directory for files matching `????-??-??_*.csv` and extracts the unique dates from their filenames.
2. For each date, lists all matching CSV files sorted alphabetically.
3. Keeps the first (oldest) file for that date in the root directory.
4. Creates a subfolder named after the date (if it doesn't already exist) and moves the remaining files for that date into it.

## Usage

Run this script from the directory containing the dated CSV files.

```shell
#!/bin/bash

# Move all root CSVs to date folders, keeping the oldest per date in root
for date in $(ls ./????-??-??_*.csv 2>/dev/null | grep -oP '\d{4}-\d{2}-\d{2}' | sort -u); do
  files=($(ls ./${date}_*.csv 2>/dev/null | sort))
  # Keep the first (oldest) in root, move the rest
  for f in "${files[@]:1}"; do
    mkdir -p "./$date"
    mv "$f" "./$date/"
  done
done
```
