# Welcome message displayed on shell startup

# ==============================
# Welcome Message
# ==============================

if [ -n "$PS1" ]; then
    echo -e "\033[1;34m=== Welcome back, $USER! ===\033[0m"
    echo -e "Date: $(date '+%A, %B %d, %Y - %H:%M:%S')"
    echo -e "Uptime:$(uptime -p | sed 's/up //')"
    echo -e "Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo
fi
