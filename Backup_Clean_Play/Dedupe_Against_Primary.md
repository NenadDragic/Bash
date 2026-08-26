# Dedupe Against Primary - Dedupe_Against_Primary.sh

This script compares several dated backup folders and removes files in the OLDER folders that already exist in a newer one. The newest folder is treated as a clean reference and is never modified.

## How it works

1. Parses options for matching mode (`hash`, `name`, `both`), action (`report`, `apply`/`trash`, `delete`, `link`), exclusions, logging, and progress display.
2. Determines which folder is the reference (primary) — either the first argument, or automatically the newest folder (by date in the name or by file modification time) when `--auto-primary` is used. The reference is never written to.
3. Sorts the remaining folders newest first and, with `--cascade`, compares each folder against all newer folders instead of only the reference.
4. Indexes the reference folder's files by size, name, and (lazily) SHA-256 hash.
5. Walks each older folder file by file, checking it against the index to detect duplicates according to the chosen matching mode.
6. Depending on the action: only reports duplicates (`--report`, the default), moves them to a trash folder (`--apply`), deletes them permanently (`--apply --purge`), or replaces them with a hardlink to the reference copy (`--link`).
7. Writes a tab-separated log of every action, shows a progress bar on a terminal, and finishes with a summary report, including a check that the reference folder was left untouched.

## Usage

Run against two or more backup folders. Without `--apply`, nothing is changed — it is a dry run that only reports what would happen.

```shell
#!/usr/bin/env bash
#
# dedupe_against_primary.sh
#
# Sammenligner daterede backupmapper og fjerner de filer i de AELDRE
# mapper der allerede findes i en nyere. Den nyeste mappe er ren
# reference og aendres ALDRIG.
#
# Standard er --report: der aendres intet foer --apply gives.
#
set -euo pipefail

VERSION="3.6"
AUTO_PRIMARY=0     # udpeg selv den nyeste mappe som reference
PRIMARY_BY="auto"  # auto | name | mtime
CASCADE=0          # sammenlign hver mappe mod ALLE nyere mapper
FORCE=0
MODE="hash"        # hash | name | both
ACTION="report"    # report | delete | trash | link
APPLY=0
TRASH=""
RM_EMPTY=0
LOGFILE=""
NOLOG=0
PURGE=0
QUIET=0
MIN_SIZE=1
RELATIVE=0
TOPN=10
declare -a EXCLUDES=()

usage() {
    cat <<'EOF'
dedupe_against_primary.sh v3 - ryd op i daterede backupmapper uden
                               nogensinde at roere den nyeste.

BRUG
    dedupe_against_primary.sh [tilvalg] MAPPE MAPPE [MAPPE ...]

SAMMENLIGNING PAA TVAERS AF FLERE MAPPER
        --cascade       Behandl mapperne nyeste foerst, og sammenlign hver
                        mappe mod ALLE nyere mapper samlet. Hver fils
                        nyeste forekomst overlever; aeldre kopier fjernes,
                        ogsaa naar dubletten kun findes mellem to gamle
                        mapper. Anbefales ved flere end to mapper.
                        Uden --cascade sammenlignes alt kun mod den nyeste.

SIKKERHED (den nyeste mappe er ren REFERENCE og roeres aldrig)
        --auto-primary  Udpeg selv den NYESTE mappe som reference, uanset
                        raekkefoelgen paa kommandolinjen.
        --by-name       Bedoem alder ud fra mappenavnet (YYYY-MM-DD).
        --by-mtime      Bedoem alder ud fra filernes tidsstempler.
                        Uden disse: datonavne bruges hvis alle mapper har
                        dem, ellers mtime. Vigtigt, fordi rsync -a bevarer
                        KILDENS mtime - en backup taget i august kan
                        indeholde filer fra sidste aar.
        --force         Tillad en aeldre mappe som reference. Brug kun
                        hvis du ved hvorfor.

HANDLING (standard er --report)
        --report        Kun analyse. AEndrer intet.
        --apply         Ryd op i de aeldre mapper. Flytter til papirkurv,
                        ikke permanent sletning - se --purge.
    -t, --trash DIR     Flyt til DIR. Uden -t bruges automatisk
                        <koerselsmappe>/<jobnavn>_tray
        --purge         Slet permanent i stedet for papirkurv. --apply
                        bruger ellers ALTID papirkurv.
        --link          Erstat dubletten med et hardlink til den nyeste
                        forekomst. Filen kan stadig laeses fra begge
                        mapper, men fylder kun en gang. Samme filsystem.

MATCHNING
    -m, --mode MODE     hash (standard) | name | both
        --relative      Kraev samme relative sti i begge traeer.
        --min-size N    Ignorer filer under N bytes (standard 1).
    -x, --exclude M     Udelad filer der matcher moenstret M. Kan gentages.
                        Moenstret matches mod den relative sti, mod
                        filnavnet alene, og mod en mappe med alt indhold.
                        Udeladte filer indgaar hverken i sammenligningen
                        eller i tallene - som var de ikke der.
                          -x 'root/File-Delete'    hele mappen
                          -x 'root/File-Count-*'   flere mapper
                          -x '*.log'               efter filnavn
        --exclude-from F  Laes moenstre fra fil F, et pr. linje.
                        Tomme linjer og linjer med # springes over.

OEVRIGT
        --rm-empty-dirs Fjern tomme mapper bagefter.
    -l, --log FIL       Tabsepareret log. Uden -l skrives automatisk
                        <koerselsmappe>/<jobnavn>_log_<tidsstempel>.log
                        Jobnavnet er den faelles overmappe for de angivne
                        mapper, f.eks. Muddi-E750.
        --no-log        Skriv ingen log.
        --progress      Vis fremdriftsbjaelke. Slaas automatisk til naar
                        stderr er en terminal, og fra ved omdirigering.
        --no-progress   Slaa bjaelken fra.
        --top N         Antal mapper i overlapsoversigten (standard 10).
    -q, --quiet         Kun opsummering.
    -h, --help          Denne hjaelp.

TYPISK BRUG
    ./dedupe_against_primary.sh --auto-primary --by-name --cascade --report \
        /mnt/dragic/Bash/Admin/*/
EOF
}

die() { printf 'FEJL: %s\n' "$*" >&2; exit 1; }
say() { [[ $QUIET -eq 1 ]] || printf '%s\n' "$*"; }
human() { numfmt --to=iec --suffix=B --format='%.1f' "$1" 2>/dev/null || echo "${1}B"; }

# -- Fremdrift -----------------------------------------------------------
# Skrives til stderr, saa omdirigering af stdout til en fil forbliver ren.
PROGRESS=-1                        # -1 = auto (kun naar stderr er en terminal)
prog_t0=0; prog_last=-1
hms() { printf '%02d:%02d:%02d' $(( $1/3600 )) $(( ($1%3600)/60 )) $(( $1%60 )); }
prog_reset() { prog_t0=$SECONDS; prog_last=-1; }
prog_show() {                      # $1=faerdige $2=i alt $3=etiket
    [[ $PROGRESS -eq 1 ]] || return 0
    local d=$1 t=$2 lbl=$3 now=$SECONDS
    if [[ $t -le 0 ]]; then return 0; fi
    # opdater hoejst en gang i sekundet, men altid paa sidste fil
    if [[ $d -lt $t && $now -eq $prog_last ]]; then return 0; fi
    prog_last=$now
    local pct=$(( d * 100 / t )) w=28
    local filled=$(( pct * w / 100 )) bar rest el=$(( now - prog_t0 )) eta=0
    printf -v bar  '%*s' "$filled"        ''; bar=${bar// /=}
    printf -v rest '%*s' $(( w - filled )) ''; rest=${rest// /.}
    [[ $d -gt 0 ]] && eta=$(( el * (t - d) / d ))
    printf '\r  [%s%s] %3d%%  %d/%d  %-22.22s  gaaet %s  ~%s tilbage  ' \
        "$bar" "$rest" "$pct" "$d" "$t" "$lbl" "$(hms $el)" "$(hms $eta)" >&2
    return 0
}
prog_clear() { [[ $PROGRESS -eq 1 ]] && printf '\r%*s\r' 100 '' >&2; return 0; }
# Vises under skridt der kan tage tid, men ikke kan maales i procent.
prog_note() { [[ $PROGRESS -eq 1 ]] && printf '\r  %s' "$1" >&2; return 0; }

# -- Argumenter ----------------------------------------------------------
declare -a ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--mode)        MODE="${2:-}"; shift 2 ;;
        --report)         ACTION="report"; APPLY=0; shift ;;
        --apply)          APPLY=1; shift ;;
        -t|--trash)       ACTION="trash"; TRASH="${2:-}"; shift 2 ;;
        --link)           ACTION="link"; shift ;;
        --cascade)        CASCADE=1; shift ;;
        --auto-primary)   AUTO_PRIMARY=1; shift ;;
        --by-name)        PRIMARY_BY="name"; shift ;;
        --by-mtime)       PRIMARY_BY="mtime"; shift ;;
        --force)          FORCE=1; shift ;;
        --relative)       RELATIVE=1; shift ;;
        -x|--exclude)     EXCLUDES+=("${2:-}"); shift 2 ;;
        --exclude-from)
            [[ -f ${2:-} ]] || die "--exclude-from: filen findes ikke: ${2:-}"
            while IFS= read -r line; do
                [[ -z $line || $line == \#* ]] && continue
                EXCLUDES+=("$line")
            done < "$2"
            shift 2 ;;
        --min-size)       MIN_SIZE="${2:-}"; shift 2 ;;
        --rm-empty-dirs)  RM_EMPTY=1; shift ;;
        -l|--log)         LOGFILE="${2:-}"; shift 2 ;;
        --no-log)         NOLOG=1; shift ;;
        --progress)       PROGRESS=1; shift ;;
        --no-progress)    PROGRESS=0; shift ;;
        --purge)          PURGE=1; shift ;;
        --top)            TOPN="${2:-}"; shift 2 ;;
        -q|--quiet)       QUIET=1; shift ;;
        -h|--help)        usage; exit 0 ;;
        -V|--version)     echo "$VERSION"; exit 0 ;;
        --)               shift; ARGS+=("$@"); break ;;
        -*)               die "ukendt tilvalg: $1" ;;
        *)                ARGS+=("$1"); shift ;;
    esac
done
set -- "${ARGS[@]:-}"

[[ $# -ge 2 ]] || { usage >&2; exit 2; }
case "$MODE" in hash|name|both) ;; *) die "ugyldig mode: $MODE" ;; esac
[[ $MIN_SIZE =~ ^[0-9]+$ ]] || die "--min-size skal vaere et tal"
[[ $TOPN =~ ^[0-9]+$ ]] || die "--top skal vaere et tal"
command -v sha256sum >/dev/null || die "sha256sum mangler"

if [[ $APPLY -eq 1 && $ACTION == report ]]; then
    [[ $PURGE -eq 1 ]] && ACTION="delete" || ACTION="trash"
fi
[[ $APPLY -eq 0 && $ACTION != report ]] && \
    say "Bemaerk: --apply mangler, saa dette er en toerkoersel af '$ACTION'."
[[ $PROGRESS -eq -1 ]] && { [[ -t 2 && $QUIET -eq 0 ]] && PROGRESS=1 || PROGRESS=0; }
[[ $MODE == name && $ACTION == link ]] && \
    die "--link med -m name er farligt: filer med samme navn men forskelligt indhold ville blive smeltet sammen"

# -- Aldersbedoemmelse ---------------------------------------------------
newest_mtime() {
    # '|| true': head lukker roeret, sort doer af SIGPIPE, og pipefail
    # ville ellers afslutte hele scriptet paa store mappetraeer.
    local m; m="$(find "$1" -type f -printf '%T@\n' 2>/dev/null | sort -rn | head -1 || true)"
    echo "${m%%.*}"
}
name_date() {
    local b; b="$(basename -- "$1")"
    if [[ $b =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
        date -d "${BASH_REMATCH[1]}" +%s 2>/dev/null || true
    fi
}
when() { [[ ${1:-0} -gt 0 ]] && date -d "@$1" '+%Y-%m-%d %H:%M' || echo "ukendt"; }

declare -a ALLDIRS=()
for d in "$@"; do
    [[ -d $d ]] || die "mappe findes ikke: $d"
    ALLDIRS+=("$(realpath -- "$d")")
done

all_dated=1
for d in "${ALLDIRS[@]}"; do [[ -n "$(name_date "$d")" ]] || all_dated=0; done

# -- Jobnavn: den faelles overmappe for de angivne mapper -----------------
JOBNAME="dedupe"
common="$(dirname -- "${ALLDIRS[0]}")"
for d in "${ALLDIRS[@]}"; do
    [[ "$(dirname -- "$d")" == "$common" ]] || { common=""; break; }
done
[[ -n $common ]] && JOBNAME="$(basename -- "$common")"
JOBNAME="${JOBNAME//[^A-Za-z0-9._-]/_}"          # gør navnet sti-sikkert
[[ -z $JOBNAME || $JOBNAME == "/" ]] && JOBNAME="dedupe"

printf -v RUN_TS '%(%Y-%m-%d_%H%M%S)T' -1
RUNDIR="$PWD"                                     # der hvor jobbet startes
[[ -z $LOGFILE && $NOLOG -eq 0 ]] && LOGFILE="$RUNDIR/${JOBNAME}_log_${RUN_TS}.log"
[[ $NOLOG -eq 1 ]] && LOGFILE=""
DEFAULT_TRAY="$RUNDIR/${JOBNAME}_tray"
[[ $PRIMARY_BY == auto ]] && { [[ $all_dated -eq 1 ]] && PRIMARY_BY="name" || PRIMARY_BY="mtime"; }
[[ $PRIMARY_BY == name && $all_dated -eq 0 ]] && \
    die "--by-name kraever at alle mapper starter med YYYY-MM-DD"

rank_of() {
    if [[ $PRIMARY_BY == name ]]; then name_date "$1"
    else local t; t="$(newest_mtime "$1")"; echo "${t:-0}"; fi
}

if [[ $all_dated -eq 1 ]]; then
    nb=""; nb_ts=-1; mb=""; mb_ts=-1
    for d in "${ALLDIRS[@]}"; do
        t="$(name_date "$d")";    [[ ${t:-0} -gt $nb_ts ]] && { nb_ts=$t; nb="$d"; }
        t="$(newest_mtime "$d")"; t="${t:-0}"
        [[ $t -gt $mb_ts ]] && { mb_ts=$t; mb="$d"; }
    done
    if [[ $nb != "$mb" ]]; then
        {
            echo "BEMAERK: mappenavne og filtidsstempler er uenige om hvad der er nyest."
            echo "  Nyest efter navn:  $(basename -- "$nb")"
            echo "  Nyest efter mtime: $(basename -- "$mb")  [$(when "$mb_ts")]"
            echo "  Aarsagen er typisk at backuppen bevarer kildens tidsstempler."
            echo "  Bruger: $PRIMARY_BY. Ret med --by-name eller --by-mtime."
            echo
        } >&2
    fi
fi

# -- Sorter alle mapper nyeste foerst ------------------------------------
declare -a ORDERED=()
while IFS=$'\t' read -r _ p; do ORDERED+=("$p"); done < <(
    for d in "${ALLDIRS[@]}"; do
        r="$(rank_of "$d")"; printf '%s\t%s\n' "${r:-0}" "$d"
    done | sort -rn -k1,1
)

if [[ $AUTO_PRIMARY -eq 1 ]]; then
    PRIMARY="${ORDERED[0]}"
    say "Auto-valgt reference (nyeste efter $PRIMARY_BY): $PRIMARY"
else
    PRIMARY="${ALLDIRS[0]}"
fi

declare -a SECONDARIES=()
for r in "${ORDERED[@]}"; do
    [[ $r == "$PRIMARY" ]] && continue
    [[ $r == "$PRIMARY"/* ]] && die "mappe ligger inde i referencemappen: $r"
    [[ $PRIMARY == "$r"/* ]] && die "referencemappen ligger inde i: $r"
    SECONDARIES+=("$r")
done
[[ ${#SECONDARIES[@]} -gt 0 ]] || die "ingen aeldre mapper tilbage - dublet i argumenterne?"

PRIM_TS="$(rank_of "$PRIMARY")"; PRIM_TS="${PRIM_TS:-0}"
declare -a NEWER=()
for r in "${SECONDARIES[@]}"; do
    ts="$(rank_of "$r")"; ts="${ts:-0}"
    [[ $ts -gt $PRIM_TS ]] && NEWER+=("$r|$ts")
done
if [[ ${#NEWER[@]} -gt 0 ]]; then
    {
        echo "ADVARSEL: referencemappen er ikke den nyeste (bedoemt paa $PRIMARY_BY)."
        echo "  Reference: $PRIMARY  [$(when "$PRIM_TS")]"
        for n in "${NEWER[@]}"; do echo "  Nyere:     ${n%%|*}  [$(when "${n##*|}")]"; done
    } >&2
    if [[ $FORCE -eq 1 ]]; then
        echo "  --force er sat, fortsaetter alligevel." >&2; echo >&2
    else
        {
            echo
            echo "Stoppet. Den nyeste backup maa aldrig behandles som aeldre -"
            echo "det ville slette i din nyeste sikkerhedskopi og beholde den gamle."
            echo "Koer med --auto-primary, eller --force hvis det er bevidst."
        } >&2
        exit 3
    fi
fi

if [[ $ACTION == trash ]]; then
    [[ -n $TRASH ]] || TRASH="$DEFAULT_TRAY"
    mkdir -p -- "$TRASH"; TRASH="$(realpath -- "$TRASH")"
    for d in "$PRIMARY" "${SECONDARIES[@]}"; do
        [[ $TRASH == "$d" || $TRASH == "$d"/* ]] && \
            die "papirkurven maa ikke ligge inde i en backupmappe: $TRASH"
        [[ "$(dirname -- "$TRASH")" == "$(dirname -- "$d")" ]] && \
            die "papirkurven ville ligge som nabo til backupmapperne og blive medtaget af */ ved naeste koersel. Start jobbet fra en anden mappe, eller angiv -t med en sti udenfor."
    done
fi

if [[ $APPLY -eq 1 || $ACTION != report ]]; then
    declare -a RO=()
    for r in "${SECONDARIES[@]}"; do
        [[ -n "$(find "$r" -type d ! -writable -print -quit 2>/dev/null)" ]] && RO+=("$r")
    done
    if [[ ${#RO[@]} -gt 0 && $APPLY -eq 1 ]]; then
        {
            echo "FEJL: aeldre mapper er skrivebeskyttede - intet kan fjernes:"
            for r in "${RO[@]}"; do echo "  $r"; done
            echo
            echo "Saet skrivebit midlertidigt paa de AELDRE mapper - aldrig paa referencen:"
            for r in "${RO[@]}"; do echo "  chmod -R u+w '$r'"; done
            echo
            echo "og tilbage bagefter:"
            for r in "${RO[@]}"; do echo "  chmod -R a-w '$r'"; done
        } >&2
        exit 4
    elif [[ ${#RO[@]} -gt 0 ]]; then
        echo "Bemaerk: ${#RO[@]} aeldre mappe(r) er skrivebeskyttede. --apply vil fejle." >&2
    fi
fi

if [[ -n $LOGFILE ]]; then
    : > "$LOGFILE" || die "kan ikke skrive log: $LOGFILE"
    printf 'tidspunkt\thandling\tbytes\tfil\tmatch\n' >> "$LOGFILE"
fi

# Skriver en linje til loggen med tidsstempel. printf %()T er indbygget i
# bash, saa der startes ingen date-proces pr. fil.
logline() {                        # $1=handling $2=bytes $3=fil $4=match
    [[ -n $LOGFILE ]] || return 0
    local ts; printf -v ts '%(%Y-%m-%d %H:%M:%S)T' -1
    printf '%s\t%s\t%s\t%s\t%s\n' "$ts" "$1" "$2" "$3" "$4" >> "$LOGFILE"
}

PRIM_DEV="$(stat -c%d -- "$PRIMARY")"

# -- Indeks --------------------------------------------------------------
declare -A IDX_BY_SIZE=()
declare -A IDX_BY_NAME=()
declare -A IDX_BY_REL=()
declare -A HASH_CACHE=()
idx_count=0; idx_bytes=0

excluded_total=0
is_excluded() {                    # $1 = relativ sti
    local rel="$1" pat
    [[ ${#EXCLUDES[@]} -eq 0 ]] && return 1
    for pat in "${EXCLUDES[@]}"; do
        pat="${pat%/}"
        [[ $rel == $pat ]]           && return 0   # hele stien
        [[ $rel == $pat/* ]]         && return 0   # mappe med indhold
        [[ $(basename -- "$rel") == $pat ]] && return 0   # filnavn
    done
    return 1
}

declare -A IDX_BY_HASH=()
declare -A BUCKET_DONE=()

index_file() {                     # $1=sti  $2=rod (til relativ sti)
    local f="$1" root="$2" sz
    sz=$(stat -c%s -- "$f")
    IDX_BY_SIZE[$sz]+="${f}"$'\n'
    unset 'BUCKET_DONE[$sz]'       # gruppen skal hashes igen naar den vokser
    IDX_BY_NAME["$(basename -- "$f")"]=1
    [[ $RELATIVE -eq 1 ]] && IDX_BY_REL["${f#"$root"/}"]="$f"
    idx_count=$((idx_count + 1)); idx_bytes=$((idx_bytes + sz))
}

say "REFERENCE (roeres aldrig): $PRIMARY  [nyest efter $PRIMARY_BY: $(when "$PRIM_TS")]"
[[ $CASCADE -eq 1 ]] && say "Kaskade: hver mappe sammenlignes mod alle nyere mapper." \
                     || say "Uden --cascade: alt sammenlignes kun mod referencen."
[[ ${#EXCLUDES[@]} -gt 0 ]] && say "Udelader: ${EXCLUDES[*]}"
say "Indekserer..."
prog_note "taeller filer i referencen ..."
prim_total=$(find "$PRIMARY" -type f -printf '.' | wc -c)
prog_clear
n=0; prog_reset
while IFS= read -r -d '' f; do
    n=$((n + 1)); prog_show "$n" "$prim_total" "indekserer reference"
    if is_excluded "${f#"$PRIMARY"/}"; then excluded_total=$((excluded_total + 1)); continue; fi
    index_file "$f" "$PRIMARY"
done < <(find "$PRIMARY" -type f -print0)
prog_clear
[[ $idx_count -gt 0 ]] || die "referencemappen er tom - stopper for en sikkerheds skyld"
prim_count=$idx_count; prim_bytes=$idx_bytes
say "  $prim_count filer, $(human $prim_bytes)"
say ""

HASH_RESULT=""
hash_of() {
    local p="$1"
    if [[ -n ${HASH_CACHE[$p]+x} ]]; then HASH_RESULT="${HASH_CACHE[$p]}"; return; fi
    HASH_RESULT="$(sha256sum -- "$p" | cut -d' ' -f1)"
    HASH_CACHE[$p]="$HASH_RESULT"
}

# -- Gennemgang, nyeste foerst -------------------------------------------
g_seen=0; g_bytes=0; g_hit=0; g_hitbytes=0
g_done=0; g_fail=0; g_skip_small=0

for sec in "${SECONDARIES[@]}"; do
    sec_seen=0; sec_bytes=0; sec_hit=0; sec_hitbytes=0
    declare -A D_TOT_F=() D_TOT_B=() D_DUP_F=() D_DUP_B=()
    declare -a PENDING=()          # filer der overlever, indekseres til sidst
    sec_dev="$(stat -c%d -- "$sec")"
    prog_note "taeller filer i $(basename -- "$sec") ..."
    sec_total=$(find "$sec" -type f -printf '.' | wc -c)
    prog_clear
    sec_label="$(basename -- "$sec")"
    n=0; prog_reset

    while IFS= read -r -d '' f; do
        n=$((n + 1)); prog_show "$n" "$sec_total" "$sec_label"
        rel="${f#"$sec"/}"
        if is_excluded "$rel"; then excluded_total=$((excluded_total + 1)); continue; fi
        fsize=$(stat -c%s -- "$f")
        reldir="$(dirname -- "$rel")"
        sec_seen=$((sec_seen + 1)); sec_bytes=$((sec_bytes + fsize))
        D_TOT_F["$reldir"]=$(( ${D_TOT_F["$reldir"]:-0} + 1 ))
        D_TOT_B["$reldir"]=$(( ${D_TOT_B["$reldir"]:-0} + fsize ))

        if [[ $fsize -lt $MIN_SIZE ]]; then
            g_skip_small=$((g_skip_small + 1))
            [[ $CASCADE -eq 1 ]] && PENDING+=("$f")
            continue
        fi

        base="$(basename -- "$f")"
        name_match=0; [[ -n ${IDX_BY_NAME[$base]+x} ]] && name_match=1
        content_match=0; matched=""

        if [[ $MODE == hash || $MODE == both ]]; then
            if [[ $RELATIVE -eq 1 ]]; then
                cand="${IDX_BY_REL[$rel]:-}"
                if [[ -n $cand && $(stat -c%s -- "$cand") -eq $fsize ]]; then
                    hash_of "$f"; fh="$HASH_RESULT"; hash_of "$cand"
                    [[ $HASH_RESULT == "$fh" ]] && { content_match=1; matched="$cand"; }
                fi
            elif [[ -n ${IDX_BY_SIZE[$fsize]+x} ]]; then
                # Hash hele stoerrelsesgruppen EN gang, og slaa derefter op
                # direkte. Uden dette gennemloebes gruppen for hver fil.
                if [[ -z ${BUCKET_DONE[$fsize]+x} ]]; then
                    while IFS= read -r cand; do
                        [[ -z $cand ]] && continue
                        hash_of "$cand"
                        [[ -z ${IDX_BY_HASH[$HASH_RESULT]+x} ]] && IDX_BY_HASH[$HASH_RESULT]="$cand"
                    done <<< "${IDX_BY_SIZE[$fsize]}"
                    BUCKET_DONE[$fsize]=1
                fi
                hash_of "$f"
                cand="${IDX_BY_HASH[$HASH_RESULT]:-}"
                [[ -n $cand ]] && { content_match=1; matched="$cand"; }
            fi
        fi
        if [[ $MODE == name && $RELATIVE -eq 1 ]]; then
            if [[ -n ${IDX_BY_REL[$rel]:-} ]]; then matched="${IDX_BY_REL[$rel]}"; else name_match=0; fi
        fi

        case "$MODE" in
            hash) hit=$content_match ;;
            name) hit=$name_match; [[ $hit -eq 1 && -z $matched ]] && matched="(navn: $base)" ;;
            both) hit=$(( name_match && content_match )) ;;
        esac

        if [[ $hit -ne 1 ]]; then
            [[ $CASCADE -eq 1 ]] && PENDING+=("$f")
            continue
        fi

        sec_hit=$((sec_hit + 1)); sec_hitbytes=$((sec_hitbytes + fsize))
        D_DUP_F["$reldir"]=$(( ${D_DUP_F["$reldir"]:-0} + 1 ))
        D_DUP_B["$reldir"]=$(( ${D_DUP_B["$reldir"]:-0} + fsize ))

        if [[ $APPLY -eq 0 ]]; then
            [[ $ACTION != report ]] && say "  [toer] $ACTION: $f"
            logline DRYRUN "$fsize" "$f" "$matched"
            continue
        fi

        case "$ACTION" in
            link)
                if [[ $sec_dev != "$PRIM_DEV" ]]; then
                    say "  SPRUNGET OVER (andet filsystem): $f"
                    logline SKIP_XDEV "$fsize" "$f" "$matched"
                    g_fail=$((g_fail + 1)); continue
                fi
                if [[ "$(stat -c%i -- "$f")" == "$(stat -c%i -- "$matched")" ]]; then
                    logline ALREADY_LINKED "$fsize" "$f" "$matched"
                    continue
                fi
                if ln -f -- "$matched" "$f" 2>/dev/null; then
                    say "  hardlinket: $f"
                    logline LINKED "$fsize" "$f" "$matched"
                    g_done=$((g_done + 1))
                else
                    say "  FEJL ved hardlink: $f"
                    logline ERROR "$fsize" "$f" "$matched"
                    g_fail=$((g_fail + 1))
                fi
                ;;
            trash)
                dest="$TRASH/$(basename -- "$sec")/$rel"
                mkdir -p -- "$(dirname -- "$dest")"
                if mv -n -- "$f" "$dest" 2>/dev/null; then
                    say "  flyttet: $f"
                    logline MOVED "$fsize" "$f" "$matched"
                    g_done=$((g_done + 1))
                else
                    say "  FEJL ved flytning: $f"
                    logline ERROR "$fsize" "$f" "$matched"
                    g_fail=$((g_fail + 1))
                fi
                ;;
            delete)
                if rm -f -- "$f"; then
                    say "  slettet: $f"
                    logline DELETED "$fsize" "$f" "$matched"
                    g_done=$((g_done + 1))
                else
                    say "  FEJL ved sletning: $f"
                    logline ERROR "$fsize" "$f" "$matched"
                    g_fail=$((g_fail + 1))
                fi
                ;;
        esac
    done < <(find "$sec" -type f -print0)

    # Foerst NU udvides indekset - saa dubletter INDE i samme mappe bevares
    if [[ $CASCADE -eq 1 && ${#PENDING[@]} -gt 0 ]]; then
        for p in "${PENDING[@]}"; do
            [[ $ACTION == link || -e $p ]] && index_file "$p" "$sec"
        done
    fi

    [[ $RM_EMPTY -eq 1 && $APPLY -eq 1 && $ACTION != link ]] && \
        find "$sec" -mindepth 1 -type d -empty -delete

    prog_clear
    pct=0; [[ $sec_seen -gt 0 ]] && pct=$(( sec_hit * 100 / sec_seen ))
    label="findes i referencen"
    [[ $CASCADE -eq 1 ]] && label="findes i nyere mappe"
    echo "AELDRE: $sec  [$(when "$(rank_of "$sec")")]"
    printf '  Filer i alt:      %8d   %10s\n' "$sec_seen" "$(human $sec_bytes)"
    printf '  %-17s %8d   %10s   (%d%%)\n' "$label:" "$sec_hit" "$(human $sec_hitbytes)" "$pct"
    printf '  Unikke:           %8d   %10s\n' \
        "$((sec_seen - sec_hit))" "$(human $((sec_bytes - sec_hitbytes)))"

    if [[ $sec_hit -gt 0 && $TOPN -gt 0 ]]; then
        echo "  Stoerste overlap pr. undermappe:"
        for d in "${!D_DUP_B[@]}"; do
            printf '%s\t%s\t%s\t%s\n' "${D_DUP_B[$d]}" "${D_DUP_F[$d]}" "${D_TOT_F[$d]}" "$d"
        done | sort -rn -k1,1 | { head -n "$TOPN" || true; } | \
        while IFS=$'\t' read -r db df tf d; do
            flag=""; [[ $df -eq $tf ]] && flag="  <- helt redundant"
            printf '    %10s  %d/%d filer  %s%s\n' "$(human "$db")" "$df" "$tf" "$d" "$flag"
        done || true
    fi
    echo ""

    g_seen=$((g_seen + sec_seen)); g_bytes=$((g_bytes + sec_bytes))
    g_hit=$((g_hit + sec_hit));    g_hitbytes=$((g_hitbytes + sec_hitbytes))
    unset D_TOT_F D_TOT_B D_DUP_F D_DUP_B PENDING
done

# -- Efterkontrol af referencen ------------------------------------------
post_count=0; post_bytes=0
while IFS= read -r -d '' f; do
    is_excluded "${f#"$PRIMARY"/}" && continue
    post_count=$((post_count + 1)); post_bytes=$((post_bytes + $(stat -c%s -- "$f")))
done < <(find "$PRIMARY" -type f -print0)
if [[ $post_count -eq $prim_count && $post_bytes -eq $prim_bytes ]]; then
    REF_STATUS="UROERT ($post_count filer, $(human $post_bytes))"
else
    REF_STATUS="AENDRET! foer: $prim_count/$(human $prim_bytes) - efter: $post_count/$(human $post_bytes)"
fi

echo "----------------------------------------------"
echo "Reference:         $REF_STATUS"
echo "Handling:          $ACTION$([[ $APPLY -eq 0 && $ACTION != report ]] && echo ' (toerkoersel)')"
echo "Sammenligning:     $([[ $CASCADE -eq 1 ]] && echo 'kaskade (alle nyere)' || echo 'kun mod referencen')"
echo "Matchning:         $MODE$([[ $RELATIVE -eq 1 ]] && echo ' + samme relative sti')"
[[ ${#EXCLUDES[@]} -gt 0 ]] && \
    echo "Udeladt:           $excluded_total filer via ${#EXCLUDES[@]} moenster"
printf 'AEldre mapper:     %d stk, %d filer, %s\n' "${#SECONDARIES[@]}" "$g_seen" "$(human $g_bytes)"
printf 'Overlap:           %d filer, %s\n' "$g_hit" "$(human $g_hitbytes)"
[[ $g_skip_small -gt 0 ]] && echo "Sprunget over:     $g_skip_small filer under $MIN_SIZE bytes"
if [[ $APPLY -eq 1 ]]; then
    echo "Behandlet:         $g_done"
    [[ $g_fail -gt 0 ]] && echo "Fejlede/sprunget:  $g_fail"
else
    echo ""
    [[ $CASCADE -eq 0 && ${#SECONDARIES[@]} -gt 1 ]] && \
        echo "Tip: med flere end to mapper fanger --cascade ogsaa dubletter mellem de aeldre."
    if [[ $ACTION == report ]]; then
        echo "Kun analyse. Brug --apply -t MAPPE for at rydde op med sikkerhedsnet."
    else
        echo "TOERKOERSEL - intet er aendret. Tilfoej --apply for at udfoere."
    fi
fi
[[ $ACTION == trash ]] && echo "Papirkurv:         $TRASH"
[[ -n $LOGFILE ]] && echo "Log:               $LOGFILE"
exit 0
```
