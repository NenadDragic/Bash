#!/bin/bash
# --- Dependency check (auto-inserted) ---
_d="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
while [ "$_d" != "/" ] && [ ! -f "$_d/lib/require_tools.sh" ]; do _d="$(dirname "$_d")"; done
if [ ! -f "$_d/lib/require_tools.sh" ]; then
    echo "FEJL: Kunne ikke finde lib/require_tools.sh (delt dependency-checker)." >&2
    exit 1
fi
# shellcheck source=/dev/null
source "$_d/lib/require_tools.sh"
unset _d
require_tools sudo python3

# Run the Python script
sudo python3 ~/Loppe/main.py

# Check if output.csv exists
if [ -f "/home/admina/Loppe/output.csv" ]; then
    # Rename output.csv to a timestamped filename
    # mv /home/admina/Loppe/output.csv "$(date +'%Y-%m-%d_%H-%M-%S').csv"
    mv /home/admina/Loppe/output.csv "/home/admina/Loppe/$(date +'%Y-%m-%d_%H-%M-%S').csv"
    echo "output.csv has been renamed to $(date +'%Y-%m-%d_%H-%M-%S').csv"
else
    echo "output.csv does not exist."
fi

sudo chown admina:admina /home/admina/Loppe/*.csv

# sudo reboot
# find / -type f -name "output.csv" 2>/dev/null

