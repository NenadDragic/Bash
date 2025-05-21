#!/bin/bash

# === Konfiguration ===
# IP-adresse eller værtsnavn for enheden, hvorfra filer skal downloades
target_ip="192.168.1.254"

# Basis URL-sti til billederne på enheden
photo_path="/DCIM/Photo"

# Fuld URL til HTML-siden, der lister billederne
html_url="http://${target_ip}${photo_path}"

# Lokal mappe, hvor billederne skal gemmes
download_dir="/mnt/sda1/DCIM/Photo" # Sørg for, at denne mappe findes!

# Sti til PID-filen. Bruges til at sikre, at kun én instans af scriptet kører.
pid_file="/var/run/DashCam-Router-Pictures.pid"
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
    echo "Dræber scriptet hårdt (som per oprindelig SIGTERM trap)."
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

echo "Starter script: $(date)"

# --- Start af PID-fil logik ---
if [ -e "$pid_file" ]; then
    old_pid=$(cat "$pid_file")
    # Tjek om processen med old_pid stadig kører
    if ps -p "$old_pid" > /dev/null 2>&1; then
        # Processen kører. Tjek om det er *dette* script.
        # Dette tjek kræver /proc filsystemet.
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
            # Fortsæt med forsigtighed, fjern den gamle PID-fil.
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

echo "PID-fil tjek bestået. Scriptet fortsætter med PID $$."

# Opret download-mappen, hvis den ikke findes (-p ignorerer fejl hvis den eksisterer, og opretter forældre-mapper)
mkdir -p "$download_dir"
if [ $? -ne 0 ]; then
    echo "Fejl: Kunne ikke oprette download-mappen '$download_dir'. Afslutter."
    exit 1 # EXIT trap vil håndtere cleanup af PID-fil
fi

echo "Forsøger at hente filliste fra: $html_url"

# Hent HTML-indholdet og udtræk JPG-filnavne
# Trin 1: Brug grep -oE til at finde hele href-attributten
# Trin 2: Brug sed til at udtrække selve filnavnet fra attributten
# Bruger | som sed-delimiter for at undgå at skulle escape / i stien
jpg_files=$(wget -qO- "$html_url" | \
            grep -oE "href=\"${photo_path}/[0-9]+_[0-9]+_[0-9]+_[RIF]\.JPG\"" | \
            sed -E "s|href=\"${photo_path}/(.*)\"|\1|")

# Tjek om der blev fundet nogen filnavne
if [[ -z "$jpg_files" ]]; then
    echo "Ingen JPG-filer fundet på siden, eller siden/filnavne kunne ikke udtrækkes korrekt."
    # Tilføj fejlfinding output, hvis wget eller grep/sed fejler:
    # echo "--- Debug Info ---"
    # echo "wget exit code: $?" # Viser exit status for wget (sidste kommando før pipe til grep)
    # echo "--- End Debug ---"
    # Bemærk: Exit koden ovenfor er for wget, ikke hele pipelinen.
else
    echo "Fundne JPG-filer:"
    # Udskriv hver fil på en ny linje for læsbarhed
    echo "$jpg_files"
    echo "---"
    echo "Starter download til: $download_dir"

    # Loop gennem hver fundet JPG-fil
    # IFS=$'\n' sikrer, at filer med spatier (usandsynligt her) håndteres korrekt
    SAVEIFS=$IFS
    IFS=$'\n'
    for jpg_file in $jpg_files; do
        # Fjern eventuelle carriage return tegn (\r) som kan snige sig ind fra wget/sed
        jpg_file_clean=$(echo "$jpg_file" | tr -d '\r')
        if [[ -z "$jpg_file_clean" ]]; then # Spring over hvis linjen blev tom efter rensning
            continue
        fi

        local_file_path="$download_dir/$jpg_file_clean"
        remote_file_url="${html_url}/${jpg_file_clean}" # Byg den fulde URL til filen

        # Tjek om filen allerede eksisterer lokalt
        if [ ! -e "$local_file_path" ]; then
            echo "Downloader: $jpg_file_clean ..."
            # Download filen til den specificerede mappe (-P)
            # -nv (non-verbose) viser kun essentielle beskeder og fejl
            wget -nv -P "$download_dir" "$remote_file_url"
            if [ $? -ne 0 ]; then
                echo "Advarsel: Kunne ikke downloade $jpg_file_clean fra $remote_file_url"
            fi
        else
            # echo "Filen $jpg_file_clean eksisterer allerede, springer over." # Gør denne valgfri/mindre støjende
            : # Gør ingenting hvis filen findes (mindre output)
        fi
    done
    IFS=$SAVEIFS # Gendan IFS
    echo "Download-loop afsluttet."
fi

echo "Script arbejde udført. Forbereder normal afslutning."
# Den sidste "Script afsluttet: $(date)" vil blive håndteret af EXIT trap'en.
exit 0
