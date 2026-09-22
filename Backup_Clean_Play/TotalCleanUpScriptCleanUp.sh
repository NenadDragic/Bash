#!/usr/bin/env bash
#===============================================================================
# TotalCleanUpScriptCleanUp.sh
#
#   1) Kører Dedupe_Against_Primary.sh med --apply for hver underfolder
#      i /mnt/dragic/Bash (undtagen Log)  -  dette ændrer/fjerner filer.
#   2) Viser pladsforbruget TIL SIDST, efter oprydningen
#      (Log-folderen tælles ikke med).
#
#   Alt output gemmes i:
#   /mnt/dragic/Bash/Log/TotalCleanUpScriptAnalyze_Log_After_YYYY_MM_DD.log
#===============================================================================

shopt -s nullglob

BASE="/home/nenad/Documents/Backup Play/Bash"
DEDUPE="/home/nenad/Documents/Backup Play/Dedupe_Against_Primary.sh"
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
