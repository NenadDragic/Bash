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
