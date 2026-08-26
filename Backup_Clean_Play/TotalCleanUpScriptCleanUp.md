# Total Clean Up Script Clean Up - TotalCleanUpScriptCleanUp.sh

This script performs the actual cleanup: it runs `Dedupe_Against_Primary.sh` with `--apply` on every subfolder of a backup base folder, which deletes/moves duplicate files, and then shows the disk usage afterwards.

## How it works

1. Sets `BASE` to the backup root and `DEDUPE` to the path of the dedupe script, and builds a dated log filename `TotalCleanUpScriptAnalyze_Log_After_<YYYY_MM_DD>.log`.
2. Redirects all subsequent output through `tee` into that log file, so everything is both printed and saved.
3. Loops through every top-level subfolder of `$BASE` (skipping `Log`); for each one that itself contains subfolders, runs:
   `Dedupe_Against_Primary.sh --auto-primary --by-name --cascade --relative --apply` against all of its subfolders — this actually removes or moves duplicate files found in the older subfolders.
4. After the cleanup, prints disk usage for `$BASE` (excluding `Log`) to show the result.
5. Prints a "Færdig" (done) message with the path to the saved log.

## Usage

Run with no arguments. This script modifies/deletes files, so run `TotalCleanUpScriptAnalyze.sh` first to review what would happen with `--report`.

Note: the script's `DEDUPE` variable points to `dedupe_against_primary_new_6.sh`, while `TotalCleanUpScriptAnalyze.sh` points to `Dedupe_Against_Primary.sh` — check that this path matches the actual dedupe script filename before running.

```shell
#!/usr/bin/env bash
#===============================================================================
# TotalCleanUpScriptCleanUp.sh
#
#   1) Kører dedupe_against_primary_new_6.sh med --apply for hver underfolder
#      i /mnt/dragic/Bash (undtagen Log)  -  dette ændrer/fjerner filer.
#   2) Viser pladsforbruget TIL SIDST, efter oprydningen
#      (Log-folderen tælles ikke med).
#
#   Alt output gemmes i:
#   /mnt/dragic/Bash/Log/TotalCleanUpScriptAnalyze_Log_After_YYYY_MM_DD.log
#===============================================================================

shopt -s nullglob

BASE="/home/nenad/Documents/Backup Play/Bash"
DEDUPE="/home/nenad/Documents/Backup Play/dedupe_against_primary_new_6.sh"
LOG="$BASE/Log/TotalCleanUpScriptAnalyze_Log_After_$(date +%Y_%m_%d).log"

mkdir -p "$BASE/Log"
exec > >(tee "$LOG") 2>&1

echo "==============================================================================="
echo " OPRYDNING STARTET  -  $BASE   ($(date '+%F %T'))"
echo "==============================================================================="

for dir in "$BASE"/*/; do
    [[ "$dir" == "$BASE/Log/" ]] && continue

    subs=( "$dir"*/ )
    (( ${#subs[@]} )) || continue

    echo
    echo "==============================================================================="
    echo " DEDUPE --apply  -  $dir"
    echo "==============================================================================="
    bash "$DEDUPE" --auto-primary --by-name --cascade --relative --apply "${subs[@]}"
done

echo
echo "==============================================================================="
echo " PLADSFORBRUG EFTER OPRYDNING  -  $BASE   ($(date '+%F %T'))   [ekskl. $BASE/Log]"
echo "==============================================================================="
du -ha --max-depth=2 --exclude="$BASE/Log" "$BASE/" 2>/dev/null \
    | grep -vE "total$|/mnt/dragic/Bash/$" | sort -k2
echo
du -shc --exclude="$BASE/Log" "$BASE" 2>/dev/null

echo
echo " Færdig. Log gemt: $LOG"
echo "==============================================================================="
```
