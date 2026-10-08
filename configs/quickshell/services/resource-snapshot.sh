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
# Aggregate history stays live while the panel is closed; skip expensive per-PID scans.
[[ "${1:-full}" == light ]] && exit 0
page_size="$(getconf PAGESIZE)"
# One awk process reads every PID; avoid hundreds of Bash parsing/redirection operations.
awk -v page_size="$page_size" '
BEGIN {
    for (i=1;i<ARGC;i++) {
        file=ARGV[i];
        if ((getline line < file)<=0) { close(file);continue }
        close(file);
        pid=file;sub(/^\/proc\//,"",pid);sub(/\/stat$/,"",pid);
        tail=line;sub(/^.*\) /,"",tail);
        name=substr(line,length(pid)+3,length(line)-length(tail)-length(pid)-4);
        gsub(/[\t\r\n]/," ",name);
        if (split(tail,f," ")<22) continue;
        read_bytes=-1;write_bytes=-1;
        io=file;sub(/stat$/,"io",io);
        while ((getline entry < io)>0) {
            split(entry,v," ");
            if (v[1]=="read_bytes:") read_bytes=v[2];
            if (v[1]=="write_bytes:") write_bytes=v[2];
        }
        close(io);
        printf "P\t%s\t%s\t%s\t%.0f\t%.0f\t%s\t%s\n",pid,f[20],name,f[12]+f[13],f[22]*page_size,read_bytes,write_bytes;
    }
    exit;
}' /proc/[0-9]*/stat
# NVIDIA exposes per-process SM activity. Unsupported providers stay unattributed.
if command -v nvidia-smi >/dev/null 2>&1; then
    timeout 2s nvidia-smi pmon -c 1 -s u 2>/dev/null | awk '$1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ && $4 ~ /^[0-9]+$/ {printf "G\t%s\t%s\n",$2,$4}'
fi
