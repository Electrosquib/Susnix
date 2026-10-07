#!/usr/bin/env bash
# Read-only, dependency-free snapshot. Process races and permission gaps are normal.
export LC_ALL=C
read -r uptime _ < /proc/uptime
printf 'T\t%s\n' "$uptime"
awk '/^cpu / { t=0; for(i=2;i<=9;i++) t+=$i; printf "C\t%.0f\t%.0f\n",t,$5+$6 }' /proc/stat
awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf "M\t%.0f\t%.0f\n",t*1024,a*1024}' /proc/meminfo
while read -r major minor device reads merged sectors_read time_read writes merged_write sectors_write time_write ongoing busy rest; do
    [[ -e "/sys/block/$device" ]] || continue
    case "$device" in loop*|ram*|dm-*|md*) continue ;; esac
    printf 'D\t%s\t%s\t%s\n' "$device" "$(( (sectors_read + sectors_write) * 512 ))" "$busy"
done < /proc/diskstats
awk -F: 'NR>2 && $1 !~ /^[[:space:]]*lo$/ {split($2,a," "); t+=a[1]+a[9]} END {printf "N\t%.0f\n",t}' /proc/net/dev
page_size="$(getconf PAGESIZE)"
for stat in /proc/[0-9]*/stat; do
    [[ -r "$stat" ]] || continue
    IFS= read -r line < "$stat" 2>/dev/null || continue
    pid="${stat#/proc/}"; pid="${pid%/stat}"
    comm="${line#*(}"; comm="${comm%)*}"
    comm="${comm//$'\t'/ }"; comm="${comm//$'\n'/ }"
    read -r -a fields <<< "${line##*) }"
    (( ${#fields[@]} >= 22 )) || continue
    io_read=-1; io_write=-1
    if [[ -r "/proc/$pid/io" ]]; then
        while read -r key value; do
            case "$key" in read_bytes:) io_read="$value" ;; write_bytes:) io_write="$value" ;; esac
        done < "/proc/$pid/io" 2>/dev/null
    fi
    printf 'P\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$pid" "${fields[19]}" "$comm" "$((fields[11]+fields[12]))" "$((fields[21]*page_size))" "$io_read" "$io_write"
done
# NVIDIA exposes per-process SM activity. Unsupported providers stay unattributed.
if command -v nvidia-smi >/dev/null 2>&1; then
    timeout 2s nvidia-smi pmon -c 1 -s u 2>/dev/null | awk '$1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ && $4 ~ /^[0-9]+$/ {printf "G\t%s\t%s\n",$2,$4}'
fi
