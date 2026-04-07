# ==============================
# SSH Login Helper
# ==============================

export KEY_VAULT="$HOME/Documents/keys"

login() {
  if [[ -z "$1" ]]; then
    echo "Usage: login <server-name>"
    return 1
  fi

  # Prefer ggrep (macOS/Homebrew), fallback to grep
  local GREP_CMD="grep"
  command -v ggrep >/dev/null 2>&1 && GREP_CMD="ggrep"

  if [[ -z "$KEY_VAULT" ]]; then
    echo "Error: KEY_VAULT is not set"
    return 1
  fi

  local CSV="$KEY_VAULT/servers.csv"

  if [[ ! -f "$CSV" ]]; then
    echo "Error: servers.csv not found in $KEY_VAULT"
    return 1
  fi

  local server_info
  server_info=$($GREP_CMD -m1 "^$1," "$CSV")

  if [[ -z "$server_info" ]]; then
    echo "No machine found with name: $1"
    echo
    echo "Available servers:"
    tail -n +2 "$CSV" | awk -F, '{gsub(/^[ \t]+|[ \t]+$/, "", $1); gsub(/^[ \t]+|[ \t]+$/, "", $5); printf "  %-20s - %s\n", $1, $5}' | sort
    return 1
  fi

  local key ip user identifier comment
  key=$(echo "$server_info" | cut -d, -f2 | xargs)
  ip=$(echo "$server_info" | cut -d, -f3 | xargs)
  user=$(echo "$server_info" | cut -d, -f4 | xargs)
  identifier=$(echo "$server_info" | cut -d, -f5 | xargs)
  comment=$(echo "$server_info" | cut -d, -f6 | xargs)

  local key_path="$KEY_VAULT/$key"

  if [[ ! -f "$key_path" ]]; then
    echo "Error: SSH key not found: $key_path"
    return 1
  fi

  echo "Connecting to $1 ($user@$ip)"
  echo "Identifier: $identifier"
  echo "Description: $comment"
  echo "Using key: $key"
  echo

  # If key already loaded in agent, don't force -i
  if ssh-add -l 2>/dev/null | grep -q "$(basename "$key")"; then
    ssh "$user@$ip"
  else
    ssh -i "$key_path" "$user@$ip"
  fi
}

servers() {
    # Validate KEY_VAULT environment variable
    if [[ -z "$KEY_VAULT" ]]; then
        echo "Error: KEY_VAULT is not set"
        return 1
    fi

    local CSV="$KEY_VAULT/servers.csv"
    
    if [[ ! -f "$CSV" ]]; then
        echo "Error: servers.csv not found in $KEY_VAULT"
        return 1
    fi

    # Colors
    local CYAN='\033[0;36m'
    local YELLOW='\033[0;33m'
    local GRAY='\033[0;90m'
    local RESET='\033[0m'

    # Display header
    echo
    echo -e "${CYAN}Name                 Key                  IP Address         User            Identifier           Comments${RESET}"
    echo -e "${GRAY}──────────────────────────────────────────────────────────────────────────────────────────────────────────────────${RESET}"

    # Prefer ggrep (macOS/Homebrew), fallback to grep
    local GREP_CMD="grep"
    command -v ggrep >/dev/null 2>&1 && GREP_CMD="ggrep"

    # Process and display servers
    tail -n +2 "$CSV" | while IFS=, read -r name key ip user identifier comment; do
        # Trim whitespace
        name=$(echo "$name" | xargs)
        key=$(echo "$key" | xargs)
        ip=$(echo "$ip" | xargs)
        user=$(echo "$user" | xargs)
        identifier=$(echo "$identifier" | xargs)
        comment=$(echo "$comment" | xargs)
        
        [[ -z "$name" ]] && continue
        
        printf "%-20s ${YELLOW}%-20s${RESET} %-18s %-15s %-20s %s\n" \
            "$name" "$key" "$ip" "$user" "$identifier" "$comment"
    done | sort
    
    echo
}

# ==============================
# Rsync Deployment Helper
# ==============================
deploy() {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: sync <server-name> <local-path> [remote-path]"
    echo "Example: sync amoga.dev ./superdash/"
    return 1
  fi

  local SERVER="$1"
  local LOCAL_PATH="$2"
  local REMOTE_PATH="$3"

  local GREP_CMD="grep"
  command -v ggrep >/dev/null 2>&1 && GREP_CMD="ggrep"

  local CSV="$KEY_VAULT/servers.csv"

  if [[ ! -f "$CSV" ]]; then
    echo "Error: servers.csv not found in $KEY_VAULT"
    return 1
  fi

  local server_info
  server_info=$($GREP_CMD -m1 "^$SERVER," "$CSV")

  if [[ -z "$server_info" ]]; then
    echo "Server not found: $SERVER"
    return 1
  fi

  local key ip user
  key=$(echo "$server_info" | cut -d, -f2 | xargs)
  ip=$(echo "$server_info" | cut -d, -f3 | xargs)
  user=$(echo "$server_info" | cut -d, -f4 | xargs)

  local key_path="$KEY_VAULT/$key"

  if [[ ! -f "$key_path" ]]; then
    echo "SSH key not found: $key_path"
    return 1
  fi

  # default remote path
  if [[ -z "$REMOTE_PATH" ]]; then
    REMOTE_PATH="/home/$user/$(basename "$LOCAL_PATH")"
  fi

  echo "Syncing $LOCAL_PATH → $SERVER:$REMOTE_PATH"
  echo "Using key: $key"
  echo

  rsync -avzP \
    -e "ssh -i $key_path" \
    --filter=':- .gitignore' \
    "$LOCAL_PATH" \
    "$user@$ip:$REMOTE_PATH"
}

# ==============================
# Server fetching helper
# ==============================
fetch() {
  if [[ -z "$1" || -z "$2" ]]
  then
    echo "Usage: fetch <server-name> <remote-path> [local-path]"
    echo "Example: fetch amoga.dev /home/azureuser/superset_backup.sql ./"
    return 1
  fi

    local SERVER="$1"
    local REMOTE_PATH="$2"
    local LOCAL_PATH="$3"
    local GREP_CMD="grep"

    command -v ggrep > /dev/null 2>&1 && GREP_CMD="ggrep"

    local CSV="$KEY_VAULT/servers.csv"
    if [[ ! -f "$CSV" ]]
    then
        echo "Error: servers.csv not found in $KEY_VAULT"
        return 1
    fi

    local server_info
    server_info=$($GREP_CMD -m1 "^$SERVER," "$CSV")
    if [[ -z "$server_info" ]]
    then
        echo "Server not found: $SERVER"
        return 1
    fi

    local key ip user
    key=$(echo "$server_info" | cut -d, -f2 | xargs)
    ip=$(echo "$server_info" | cut -d, -f3 | xargs)
    user=$(echo "$server_info" | cut -d, -f4 | xargs)

    local key_path="$KEY_VAULT/$key"
    if [[ ! -f "$key_path" ]]
    then
        echo "SSH key not found: $key_path"
        return 1
    fi

    if [[ -z "$LOCAL_PATH" ]]
    then
        LOCAL_PATH="./$(basename "$REMOTE_PATH")"
    fi

    echo "Fetching $SERVER:$REMOTE_PATH → $LOCAL_PATH"
    echo "Using key: $key"
    echo

    rsync -avzP -e "ssh -i $key_path" --filter=':- .gitignore' "$user@$ip:$REMOTE_PATH" "$LOCAL_PATH"
}


# ==============================
# Android Studio and Scrcpy helper
# ==============================
rnstart() {
  AVD="Pixel_9a"

  cleanup() {
    echo "\n🛑 Cleaning up..."
    pkill -f "emulator.*$AVD"
    pkill -f scrcpy
    adb emu kill >/dev/null 2>&1
    echo "✅ Emulator and scrcpy stopped"
    exit
  }

  trap cleanup INT TERM

  echo "🚀 Starting headless emulator..."
  emulator -avd "$AVD" -no-window -gpu host >/dev/null 2>&1 &

  echo "⏳ Waiting for device..."
  adb wait-for-device

  until [[ "$(adb shell getprop sys.boot_completed 2>/dev/null)" == "1" ]]; do
    sleep 1
  done

  echo "📱 Launching scrcpy..."
  scrcpy >/dev/null 2>&1 &

  echo "⚡ Starting Expo..."
  npx expo start --clear
}
