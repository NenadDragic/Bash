Kan du implementer samme i dette script:



!/bin/bash



# === Konfiguration ===

# IP-adresse eller værtsnavn for enheden, hvorfra filer skal downloades

target_ip="192.168.1.254"



# Basis URL-sti til videoerne på enheden

video_path="/DCIM/Movie/RO"



# Fuld URL til HTML-siden, der lister videoerne

html_url="http://${target_ip}${video_path}"



# Lokal mappe, hvor videoerne skal gemmes

download_dir="/mnt/sda1/DCIM/Movie/RO" # Sørg for, at denne mappe findes!



# Mønster til at identificere kørende processer relateret til denne opgave

# Vi bruger '[D]CIM/Movie/RO' for at undgå, at grep-kommandoen matcher sig selv.

process_grep_pattern='[D]CIM/Movie/RO'

# === Konfiguration Slut ===



echo "Starter script: $(date)"

echo "Kontrollerer for eksisterende processer, der matcher '${process_grep_pattern}'..."



# Tæl antallet af processer (undtagen denne scripts egen grep), der matcher mønsteret

# Brug 'ps w' som understøttes af BusyBox ps

process_count=$(ps w | grep "${process_grep_pattern}" | wc -l)



# Tjek om der allerede kører en relevant proces

if [[ $process_count -eq 0 ]]; then

    echo "Ingen matchende processer fundet. Fortsætter..."



    # Opret download-mappen, hvis den ikke findes (-p ignorerer fejl hvis den eksisterer, og opretter forældre-mapper)

    mkdir -p "$download_dir"

    if [ $? -ne 0 ]; then

        echo "Fejl: Kunne ikke oprette download-mappen '$download_dir'. Afslutter."

        exit 1

    fi



    # Tjek om port 21 er åben

    nmap -p 21 "$target_ip" | grep -q "21/tcp open"

    if [ $? -eq 0 ]; then

        echo "Port 21 er åben på $target_ip. Fortsætter med at hente MP4 filer."



        echo "Forsøger at hente filliste fra: $html_url"



        # Hent HTML-indholdet og udtræk MP4-filnavne

        # Trin 1: Brug grep -oE til at finde hele href-attributten for MP4 filer

        # Trin 2: Brug sed til at udtrække selve filnavnet fra attributten

        # Bruger | som sed-delimiter for at undgå at skulle escape / i stien

       mp4_files=$(wget -qO- "$html_url" | \

                      grep -oE "href=\"${video_path}/[0-9]+_[0-9]+_[0-9]+_[RF]\.MP4\"" | \

                      sed -E "s|href=\"${video_path}/(.*)\"|\1|")



        # Tjek om der blev fundet nogen filnavne

        if [[ -z "$mp4_files" ]]; then

            echo "Ingen MP4-filer fundet på siden, eller siden/filnavne kunne ikke udtrækkes korrekt."

            # Tilføj fejlfinding output, hvis wget eller grep/sed fejler:

            # echo "--- Debug Info ---"

            # echo "wget exit code: $?" # Viser exit status for wget (sidste kommando før pipe til grep)

            # echo "--- End Debug ---"

            # Bemærk: Exit koden ovenfor er for wget, ikke hele pipelinen.

        else

            echo "Fundne MP4-filer:"

            # Udskriv hver fil på en ny linje for læsbarhed

            echo "$mp4_files"

            echo "---"

            echo "Starter download til: $download_dir"



            # Loop gennem hver fundet MP4-fil

            # IFS=$'\n' sikrer, at filer med spatier (usandsynligt her) håndteres korrekt

            SAVEIFS=$IFS

            IFS=$'\n'

            for mp4_file in $mp4_files; do

                # Fjern eventuelle carriage return tegn (\r) som kan snige sig ind fra wget/sed

                mp4_file_clean=$(echo "$mp4_file" | tr -d '\r')

                if [[ -z "$mp4_file_clean" ]]; then # Spring over hvis linjen blev tom efter rensning

                    continue

                fi



                local_file_path="$download_dir/$mp4_file_clean"

                remote_file_url="${html_url}/${mp4_file_clean}" # Byg den fulde URL til filen



                # Tjek om filen allerede eksisterer lokalt

                if [ ! -e "$local_file_path" ]; then

                    echo "Downloader: $mp4_file_clean ..."

                    # Download filen til den specificerede mappe (-P)

                    # -nv (non-verbose) viser kun essentielle beskeder og fejl

                    wget -nv -P "$download_dir" "$remote_file_url"

                    if [ $? -ne 0 ]; then

                        echo "Advarsel: Kunne ikke downloade $mp4_file_clean fra $remote_file_url"

                    fi

                else

                    # echo "Filen $mp4_file_clean eksisterer allerede, springer over." # Gør denne valgfri/mindre støjende

                    : # Gør ingenting hvis filen findes (mindre output)

                fi

            done

            IFS=$SAVEIFS # Gendan IFS

            echo "Download-loop afsluttet."

        fi

    else

        echo "Port 21 er ikke åben på $target_ip. FTP er muligvis ikke tilgængelig."

    fi

else

    # Dette sker, hvis process_count var > 0

    echo "Fundet $process_count process(er), der matcher '${process_grep_pattern}'. Antager, at en anden instans kører."

    echo "Springer denne kørsel over for at undgå konflikter."

fi



# Opsæt en fælde for at dræbe scriptet hårdt, hvis det modtager SIGTERM

# Dette var i det oprindelige script, beholdes for nu.

trap "echo 'SIGTERM modtaget, dræber scriptet hårdt.'; kill -KILL $$" SIGTERM



echo "Script afsluttet: $(date)"

exit 0
