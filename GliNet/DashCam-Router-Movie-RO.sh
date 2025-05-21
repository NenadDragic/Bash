#!/bin/bash

# === Konfiguration ===
# IP-adresse eller værtsnavn for enheden, hvorfra filer skal downloades
target_ip="192.168.1.254"

# Basis URL-sti til videoerne på enheden
video_path="/DCIM/Movie/RO"

# Fuld URL til HTML-siden, der lister videoerne
html_url="http://${target_ip}${video_path}"

# Lokal mappe, hvor videoerne skal gemmes
download_dir="/mnt/sda1/DCIM/Movie/RO" # Sørg for, at denne mappe findes!

# Sti til PID-filen. Bruges til at sikre, at kun én instans af scriptet kører.
# VIGTIGT: Brug et unikt navn for dette video-script for at undgå konflikt med foto-scriptet.
pid_file="/var/run/DashCam-Router-Videos.pid"
# Scriptets eget filnavn (til brug i PID-tjek)
script_filename=$(basename "$0")
# === Konfiguration Slut ===

# --- Start af Trap logik for oprydning ---
_pid_file_cleaned_up=0 # Flag for at undgå multipel oprydning

# Funktion til at fjerne PID-fil
cleanup_pid_file() {
    if [ "$_pid_file_cleaned_up" -eq 0 ]; then
        echo "Rydder op: Fjerner PID-fil ($pid_file)..."
        rm -f "$pid_file"
        if [ $? -eq 0 ]; then
            echo "PID-fil fjernet."
        else
            echo "Advarsel: Kunne ikke fjerne PID-fil ($pid_file)."
        fi
        _pid_file_cleaned_up=1
    fi
}

# Håndtering af EXIT (normal afslutning eller 'exit' kommando)
handle_exit() {
    exit_code=$? # Gem den faktiske exit kode
    # Denne besked vises kun hvis SIGINT/SIGTERM ikke allerede har vist en afslutningsbesked
    if [ "$_pid_file_cleaned_up" -eq 0 ]; then
        echo "" # Ny linje for pænhed
        echo "Scriptet afslutter (EXIT trap)."
    fi
    cleanup_pid_file
    echo "Script endeligt afsluttet: $(date) med status $exit_code"
    # Scriptet vil exite med den oprindelige $exit_code
}

# Håndtering af SIGTERM (typisk pæn anmodning om at afslutte)
handle_sigterm() {
    echo "" # Ny linje
    echo "SIGTERM modtaget! Starter oprydning..."
    cleanup_pid_file
    echo "Dræber scriptet hårdt." # Lidt anderledes end den oprindelige besked, men formålet er det samme
    trap - SIGTERM # Nulstil SIGTERM trap for at undgå rekursion
    kill -KILL $$
}

# Håndtering af SIGINT (Ctrl+C)
handle_sigint() {
    echo "" # Ny linje
    echo "SIGINT (Ctrl+C) modtaget! Starter oprydning..."
    cleanup_pid_file
    echo "Script afbrudt af bruger. Afslutter med status 130."
    trap - SIGINT # Nulstil SIGINT trap
    exit 130 # Standard exit kode for Ctrl+C
}

# Opsæt traps
trap handle_exit EXIT
trap handle_sigterm SIGTERM
trap handle_sigint SIGINT
# --- Slut på Trap logik ---

echo "Starter script: $(date) (PID: $$)" # Tilføjet PID for nemmere identifikation

# --- Start af PID-fil logik ---
if [ -e "$pid_file" ]; then
    old_pid=$(cat "$pid_file")
    # Tjek om processen med old_pid stadig kører
    if ps -p "$old_pid" > /dev/null 2>&1; then
        # Processen kører. Tjek om det er *dette* script.
        cmd_line_content=$(tr -d '\0' < /proc/$old_pid/cmdline 2>/dev/null)
        if echo "$cmd_line_content" | grep -Fq -- "$script_filename"; then
            echo "En anden instans af scriptet ('$script_filename') ser ud til at køre med PID $old_pid."
            echo "Kommando for PID $old_pid: $cmd_line_content"
            echo "Fundet i PID-fil: $pid_file."
            echo "Springer denne kørsel over."
            exit 1 # Afslut, da en anden instans kører
        else
            echo "Advarsel: PID $old_pid (fra $pid_file) kører, men ser ikke ud til at være dette script ('$script_filename')."
            echo "Kommando for PID $old_pid: $cmd_line_content"
            echo "Fjerner forældet PID-fil, da den sandsynligvis ikke tilhører dette script."
            rm -f "$pid_file"
            if [ $? -ne 0 ]; then
                echo "Fejl: Kunne ikke fjerne forældet PID-fil '$pid_file'. Kontroller rettigheder. Afslutter."
                exit 1
            fi
        fi
    else
        # Processen kører ikke længere, men PID-filen findes. Forældet fil.
        echo "Forældet PID-fil fundet ($pid_file) for en ikke-kørende PID $old_pid. Fjerner den."
        rm -f "$pid_file"
        if [ $? -ne 0 ]; then
            echo "Fejl: Kunne ikke fjerne forældet PID-fil '$pid_file'. Kontroller rettigheder. Afslutter."
            exit 1
        fi
    fi
fi

# Opret ny PID-fil med den aktuelle proces' ID
echo $$ > "$pid_file"
if [ $? -ne 0 ]; then
    echo "Fejl: Kunne ikke oprette PID-filen '$pid_file'. Kontroller skriverettigheder. Afslutter."
    exit 1 # Afslut, da PID-fil ikke kunne oprettes
fi
# --- Slut på PID-fil logik ---

echo "PID-fil tjek bestået. Scriptet fortsætter."

# Opret download-mappen, hvis den ikke findes (-p ignorerer fejl hvis den eksisterer, og opretter forældre-mapper)
mkdir -p "$download_dir"
if [ $? -ne 0 ]; then
    echo "Fejl: Kunne ikke oprette download-mappen '$download_dir'. Afslutter."
    exit 1 # EXIT trap vil håndtere cleanup af PID-fil
fi

# Tjek om port 21 er åben
# Bemærk: nmap skal være installeret på systemet.
if command -v nmap >/dev/null 2>&1; then
    echo "Kontrollerer om port 21 (FTP) er åben på $target_ip..."
    if nmap -PN -p 21 "$target_ip" | grep -q "21/tcp open"; then # -PN for at undgå host discovery hvis ICMP er blokeret
        echo "Port 21 er åben på $target_ip. Fortsætter med at hente MP4 filer via HTTP."

        echo "Forsøger at hente filliste fra: $html_url"

        # Hent HTML-indholdet og udtræk MP4-filnavne
        mp4_files=$(wget -qO- "$html_url" | \
                    grep -oE "href=\"${video_path}/[0-9]+_[0-9]+_[0-9]+_[RIF]\.MP4\"" | \
                    sed -E "s|href=\"${video_path}/(.*)\"|\1|")

        # Tjek om der blev fundet nogen filnavne
        if [[ -z "$mp4_files" ]]; then
            echo "Ingen MP4-filer fundet på siden, eller siden/filnavne kunne ikke udtrækkes korrekt."
        else
            echo "Fundne MP4-filer:"
            echo "$mp4_files"
            echo "---"
            echo "Starter download til: $download_dir"

            SAVEIFS=$IFS
            IFS=$'\n'
            for mp4_file in $mp4_files; do
                mp4_file_clean=$(echo "$mp4_file" | tr -d '\r')
                if [[ -z "$mp4_file_clean" ]]; then
                    continue
                fi

                local_file_path="$download_dir/$mp4_file_clean"
                remote_file_url="${html_url}/${mp4_file_clean}"

                if [ ! -e "$local_file_path" ]; then
                    echo "Downloader: $mp4_file_clean ..."
                    wget -nv -P "$download_dir" "$remote_file_url"
                    if [ $? -ne 0 ]; then
                        echo "Advarsel: Kunne ikke downloade $mp4_file_clean fra $remote_file_url"
                    fi
                else
                    : # Gør ingenting hvis filen findes
                fi
            done
            IFS=$SAVEIFS
            echo "Download-loop afsluttet."
        fi
    else
        echo "Port 21 er ikke åben på $target_ip. Selvom dette script downloader via HTTP, indikerer dette, at FTP-adgang (hvis relevant for andre formål) muligvis ikke er tilgængelig."
        # Du kan vælge at afslutte scriptet her, hvis åben port 21 er et krav for at fortsætte,
        # selvom download sker via HTTP.
        # echo "Afslutter scriptet da port 21 ikke er åben."
        # exit 1
        echo "Fortsætter alligevel med HTTP download, da port 21 tjek kun var informativt for dette script."
        # Hvis du vil have scriptet til at fejle hvis port 21 ikke er åben, fjern kommenteringen ovenfor og nedenstående filliste hentning.
        # For nu, gentager vi logikken for fillistehentning, hvis port 21 tjekket ikke skal stoppe HTTP download.
        # Dette er lidt redundant, overvej at strukturere if/else anderledes hvis port 21 er kritisk.
        # For nu antager jeg, at download skal forsøges uanset port 21 status, men med en advarsel.

        echo "Forsøger at hente filliste fra: $html_url (uafhængigt af port 21 status)"
        mp4_files=$(wget -qO- "$html_url" | \
                    grep -oE "href=\"${video_path}/[0-9]+_[0-9]+_[0-9]+_[RF]\.MP4\"" | \
                    sed -E "s|href=\"${video_path}/(.*)\"|\1|")
        if [[ -z "$mp4_files" ]]; then
            echo "Ingen MP4-filer fundet på siden, eller siden/filnavne kunne ikke udtrækkes korrekt."
        else
            echo "Fundne MP4-filer:"
            echo "$mp4_files"
            echo "---"
            echo "Starter download til: $download_dir"
            SAVEIFS=$IFS
            IFS=$'\n'
            for mp4_file in $mp4_files; do
                mp4_file_clean=$(echo "$mp4_file" | tr -d '\r')
                if [[ -z "$mp4_file_clean" ]]; then
                    continue
                fi
                local_file_path="$download_dir/$mp4_file_clean"
                remote_file_url="${html_url}/${mp4_file_clean}"
                if [ ! -e "$local_file_path" ]; then
                    echo "Downloader: $mp4_file_clean ..."
                    wget -nv -P "$download_dir" "$remote_file_url"
                    if [ $? -ne 0 ]; then
                        echo "Advarsel: Kunne ikke downloade $mp4_file_clean fra $remote_file_url"
                    fi
                else
                    : 
                fi
            done
            IFS=$SAVEIFS
            echo "Download-loop afsluttet."
        fi
    fi
else
    echo "Advarsel: 'nmap' kommandoen blev ikke fundet. Kan ikke tjekke port 21 status."
    echo "Fortsætter med at hente MP4 filer via HTTP."
    # Da nmap ikke findes, springer vi porttjek over og går direkte til download logik
    echo "Forsøger at hente filliste fra: $html_url"
    mp4_files=$(wget -qO- "$html_url" | \
                grep -oE "href=\"${video_path}/[0-9]+_[0-9]+_[0-9]+_[RF]\.MP4\"" | \
                sed -E "s|href=\"${video_path}/(.*)\"|\1|")
    if [[ -z "$mp4_files" ]]; then
        echo "Ingen MP4-filer fundet på siden, eller siden/filnavne kunne ikke udtrækkes korrekt."
    else
        echo "Fundne MP4-filer:"
        echo "$mp4_files"
        echo "---"
        echo "Starter download til: $download_dir"
        SAVEIFS=$IFS
        IFS=$'\n'
        for mp4_file in $mp4_files; do
            mp4_file_clean=$(echo "$mp4_file" | tr -d '\r')
            if [[ -z "$mp4_file_clean" ]]; then
                continue
            fi
            local_file_path="$download_dir/$mp4_file_clean"
            remote_file_url="${html_url}/${mp4_file_clean}"
            if [ ! -e "$local_file_path" ]; then
                echo "Downloader: $mp4_file_clean ..."
                wget -nv -P "$download_dir" "$remote_file_url"
                if [ $? -ne 0 ]; then
                    echo "Advarsel: Kunne ikke downloade $mp4_file_clean fra $remote_file_url"
                fi
            else
                : 
            fi
        done
        IFS=$SAVEIFS
        echo "Download-loop afsluttet."
    fi
fi

echo "Script arbejde udført. Forbereder normal afslutning."
# Den sidste "Script afsluttet: $(date)" vil blive håndteret af EXIT trap'en.
exit 0
