# Total Clean Up Script Analyze - TotalCleanUpScriptAnalyze.sh

This script is a dry-run report: it shows disk usage for a backup base folder and runs `Dedupe_Against_Primary.sh` with `--report` on every subfolder, without changing any files.

## How it works

1. Sets `BASE` to the backup root and `DEDUPE` to the path of `Dedupe_Against_Primary.sh`, and builds a dated log filename `TotalCleanUpScriptAnalyze_Log_Before_<YYYY_MM_DD>.log`.
2. Redirects all subsequent output through `tee` into that log file, so everything is both printed and saved.
3. Prints disk usage for `$BASE` (excluding the `Log` folder), two levels deep, followed by a total summary.
4. Loops through every top-level subfolder of `$BASE` (skipping `Log`); for each one that itself contains subfolders, runs:
   `Dedupe_Against_Primary.sh --auto-primary --by-name --cascade --relative --report` against all of its subfolders — a dry run that reports duplicate files without deleting or moving anything.
5. Prints a "Færdig" (done) message with the path to the saved log.

## Usage

Run with no arguments. Edit the `BASE` and `DEDUPE` paths at the top of the script if the backup location or the dedupe script's location changes.

```shell
#!/usr/bin/env bash
#===============================================================================
# TotalCleanUpScriptAnalyze.sh
#
#   1) Viser pladsforbrug i /mnt/dragic/Bash (Log-folderen tælles ikke med)
#   2) Kører Dedupe_Against_Primary.sh med --report for hver underfolder
#      (undtagen Log)  -  tørkørsel, der ændres ingenting.
#
#   Alt output gemmes i:
#   /mnt/dragic/Bash/Log/TotalCleanUpScriptAnalyze_Log_Before_YYYY_MM_DD.log
#===============================================================================

shopt -s nullglob

BASE="/home/nenad/Documents/Backup Play/Bash"
DEDUPE="/home/nenad/Documents/Backup Play/Dedupe_Against_Primary.sh"
LOG="$BASE/Log/TotalCleanUpScriptAnalyze_Log_Before_$(date +%Y_%m_%d).log"

mkdir -p "$BASE/Log"
exec > >(tee "$LOG") 2>&1

echo "==============================================================================="
echo " PLADSFORBRUG  -  $BASE   ($(date '+%F %T'))   [ekskl. $BASE/Log]"
echo "==============================================================================="
du -ha --max-depth=2 --exclude="$BASE/Log" "$BASE/" 2>/dev/null \
    | grep -vE "total$|/mnt/dragic/Bash/$" | sort -k2
echo
du -shc --exclude="$BASE/Log" "$BASE" 2>/dev/null

for dir in "$BASE"/*/; do
    [[ "$dir" == "$BASE/Log/" ]] && continue

    subs=( "$dir"*/ )
    (( ${#subs[@]} )) || continue

    echo
    echo "==============================================================================="
    echo " DEDUPE --report  -  $dir"
    echo "==============================================================================="
    bash "$DEDUPE" --auto-primary --by-name --cascade --relative --report "${subs[@]}"
done

echo
echo "==============================================================================="
echo " Færdig. Log gemt: $LOG"
echo "==============================================================================="
```
