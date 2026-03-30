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
