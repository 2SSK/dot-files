#!/bin/bash
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Path to store previous CPU stat
CPU_STAT_FILE="/tmp/.cpu_stat"

# Read current CPU stat
read -r cpu_line < /proc/stat

# Extract idle and total CPU time
cpu_idle=$(echo "$cpu_line" | awk '{print $5}')
cpu_total=$(echo "$cpu_line" | awk '{sum=0; for(i=2;i<=10;i++) sum+=$i; print sum}')

# Read previous CPU values
if [ -f "$CPU_STAT_FILE" ]; then
    read -r prev_idle prev_total < "$CPU_STAT_FILE"
else
    prev_idle=0
    prev_total=0
fi

# Save current CPU values for next run
echo "$cpu_idle $cpu_total" > "$CPU_STAT_FILE"

# Calculate CPU usage percentage
diff_idle=$((cpu_idle - prev_idle))
diff_total=$((cpu_total - prev_total))
if [ "$diff_total" -gt 0 ]; then
    cpu_usage=$(( (100 * (diff_total - diff_idle)) / diff_total ))
else
    cpu_usage=0
fi

# Get memory usage
# total and free memory in kB
mem_info=$(grep -E 'MemTotal|MemAvailable' /proc/meminfo)
mem_total=$(echo "$mem_info" | grep MemTotal | awk '{print $2}')
mem_available=$(echo "$mem_info" | grep MemAvailable | awk '{print $2}')

# Calculate used memory and percentage
mem_used=$((mem_total - mem_available))
mem_pct=$((mem_used * 100 / mem_total))

# Get battery info: percentage and status
battery_info=$(acpi -b 2>/dev/null)

if [ -n "$battery_info" ]; then
    # Extract battery with the highest percentage
    batt_pct=$(echo "$battery_info" | awk -F', ' '{gsub(/%/, "", $2); if ($2 > max) {max=$2; status=$1; percent=$2}} END {print percent}')
    batt_status=$(echo "$battery_info" | awk -F', ' -v target="$batt_pct" '{gsub(/%/, "", $2); if ($2 == target) {split($1, a, ": "); print a[2]}}')

    # Fallbacks
    batt_pct=${batt_pct:-0}
    batt_status=${batt_status:-"Unknown"}
else
    batt_pct=0
    batt_status="N/A"
fi

# Wi-Fi status
wifi=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)
[ -z "$wifi" ] && wifi="Dis"

# Volume
volume=$(amixer get Master | grep -o '[0-9]*%' | head -1)

# Brightness
b=$(brightnessctl get 2>/dev/null)
max_b=$(brightnessctl max 2>/dev/null)
if [ -n "$b" ] && [ -n "$max_b" ]; then
    b_pct=$((b * 100 / max_b))
else
    b_pct="N/A"
fi

# Date/Time/Days/Months
date_time=$(date '+%A, %B %d, %Y %H:%M')

# Combine all info into a single line
echo "CPU: ${cpu_usage}% | MEM: ${mem_pct}% | WiFi: ${wifi} | Vol: ${volume} | Brt: ${b_pct}% | Batt: ${batt_pct}% (${batt_status}) | ${date_time}"
