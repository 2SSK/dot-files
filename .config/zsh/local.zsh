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

fl() {
    if [[ -z "$KEY_VAULT" ]]; then
        echo "Error: KEY_VAULT is not set"
        return 1
    fi
    local CSV="$KEY_VAULT/servers.csv"
    if [[ ! -f "$CSV" ]]; then
        echo "Error: servers.csv not found in $KEY_VAULT"
        return 1
    fi

    local GREP_CMD="grep"
    command -v ggrep >/dev/null 2>&1 && GREP_CMD="ggrep"

    local name
    name=$(
        tail -n +2 "$CSV" | while IFS=, read -r n k i u id c; do
            n=$(echo "$n" | xargs)
            [[ -z "$n" ]] && continue
            echo "$n"
        done | sort |
        fzf --prompt="SSH> " \
            --preview="grep -m1 '^{},' \"$CSV\" | awk -F, '{printf \"Name: %s\\nKey:  %s\\nIP:   %s\\nUser: %s\\nId:   %s\\nDesc: %s\\n\", \$1, \$2, \$3, \$4, \$5, \$6}'" \
            --preview-window=right:40%
    )

    if [[ -z "$name" ]]; then
        return 1
    fi

    local server_info
    server_info=$($GREP_CMD -m1 "^$name," "$CSV")
    if [[ -z "$server_info" ]]; then
        echo "Error: Server '$name' not found"
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

    echo "Connecting to $name ($user@$ip)"
    echo "Identifier: $identifier"
    echo "Description: $comment"
    echo "Using key: $key"
    echo

    if ssh-add -l 2>/dev/null | grep -q "$(basename "$key")"; then
        ssh "$user@$ip"
    else
        ssh -i "$key_path" "$user@$ip"
    fi
}

runon () {
	setopt local_options no_monitor

	if [[ $# -lt 2 ]]
	then
		echo "Usage:"
		echo "  runon <server> [server ...] <command>"
		echo "  runon --all <command>"
		echo
		echo "Examples:"
		echo "  runon worker4 'uptime'"
		echo "  runon worker1n worker2n worker3n 'df -h'"
		echo "  runon --all 'hostname'"
		return 1
	fi

	if [[ -z "$KEY_VAULT" ]]
	then
		echo "Error: KEY_VAULT is not set"
		return 1
	fi

	local CSV="$KEY_VAULT/servers.csv"
	local command
	local -a servers_to_run
	local server_info
	local server key ip user key_path

	if [[ ! -f "$CSV" ]]
	then
		echo "Error: servers.csv not found in $KEY_VAULT"
		return 1
	fi

	if [[ "$1" == "--all" ]]
	then
		shift
		command="$*"

		while IFS=, read -r server key ip user identifier comment
		do
			server=$(echo "$server" | xargs)
			[[ -z "$server" ]] && continue
			servers_to_run+=("$server")
		done < <(tail -n +2 "$CSV")
	else
		while [[ $# -gt 1 ]]
		do
			servers_to_run+=("$1")
			shift
		done

		command="$1"
	fi

	for server in "${servers_to_run[@]}"
	do
		server_info=$(grep -m1 "^${server}," "$CSV")

		if [[ -z "$server_info" ]]
		then
			echo "[$server] NOT FOUND"
			continue
		fi

		key=$(echo "$server_info" | cut -d, -f2 | xargs)
		ip=$(echo "$server_info" | cut -d, -f3 | xargs)
		user=$(echo "$server_info" | cut -d, -f4 | xargs)

		key_path="$KEY_VAULT/$key"

		if [[ ! -f "$key_path" ]]
		then
			echo "[$server] KEY NOT FOUND: $key_path"
			continue
		fi

		(
			echo "========== $server =========="

			ssh -n \
				-i "$key_path" \
				-o ConnectTimeout=5 \
				-o BatchMode=yes \
				-o StrictHostKeyChecking=no \
				"$user@$ip" "$command"

			rc=$?

			if [[ $rc -ne 0 ]]
			then
				echo "[$server] FAILED (exit $rc)"
			else
				echo "[$server] SUCCESS"
			fi
		) &
	done

	wait
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
# Usage: rnstart [avd] [expo args...]
# Env: RNSTART_AVD (small_phone), RNSTART_PORT (5554), RNSTART_BOOT_TIMEOUT (180s),
#      RNSTART_GPU (nvidia | host | swiftshader_indirect; default nvidia)
# GPU modes: "nvidia" renders on the dGPU via PRIME offload. "host" uses the Intel
# iGPU, where Mesa 26.2 segfaults in the emulator's GLES renderer. Vulkan is off:
# React Native doesn't need it and it roughly doubles cold boot time.
rnstart() {
  emulate -L zsh

  local avd=${RNSTART_AVD:-small_phone}
  [[ -n $1 && $1 != -* ]] && { avd=$1; shift }
  local port=${RNSTART_PORT:-5554}
  local serial="emulator-$port"
  local timeout=${RNSTART_BOOT_TIMEOUT:-180}
  local gpu=${RNSTART_GPU:-nvidia}
  local log="${TMPDIR:-/tmp}/rnstart-$avd.log"
  local emu_pid= scrcpy_pid= cmd
  local -a gpu_env=()

  if [[ $gpu == nvidia ]]; then
    if [[ -e /dev/nvidia0 ]]; then
      gpu=host
      gpu_env=(
        __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
        __GLX_VENDOR_LIBRARY_NAME=nvidia
        __NV_PRIME_RENDER_OFFLOAD=1
      )
    else
      print -u2 "⚠️  NVIDIA driver not loaded, falling back to software rendering"
      gpu=swiftshader_indirect
    fi
  fi

  for cmd in emulator adb scrcpy npx; do
    (( $+commands[$cmd] )) || { print -u2 "❌ '$cmd' not found in PATH"; return 127 }
  done
  [[ -f package.json ]] || { print -u2 "❌ No package.json here — run from an Expo project"; return 1 }
  if ! emulator -list-avds 2>/dev/null | grep -qx -- "$avd"; then
    print -u2 "❌ AVD '$avd' not found. Available:"
    emulator -list-avds >&2
    return 1
  fi

  {
    if [[ $(adb -s $serial get-state 2>/dev/null) == device ]]; then
      print "♻️  Reusing running emulator $serial"
    else
      print "🚀 Starting headless emulator '$avd' on $serial (log: $log)..."
      env $gpu_env emulator -avd $avd -port $port -no-window -no-audio -no-boot-anim -gpu $gpu -feature -Vulkan >$log 2>&1 &!
      emu_pid=$!
    fi

    print "⏳ Waiting for boot (timeout ${timeout}s)..."
    local start=$SECONDS
    until [[ $(adb -s $serial shell getprop sys.boot_completed 2>/dev/null) == 1 ]]; do
      if [[ -n $emu_pid ]] && ! kill -0 $emu_pid 2>/dev/null; then
        print -u2 "❌ Emulator exited early. Last log lines:"
        tail -n 20 $log >&2
        return 1
      fi
      if (( SECONDS - start > timeout )); then
        print -u2 "❌ Boot timed out after ${timeout}s — see $log"
        return 1
      fi
      sleep 1
    done

    print "📱 Launching scrcpy..."
    scrcpy -s $serial --window-title "$avd" >/dev/null 2>&1 &!
    scrcpy_pid=$!

    print "⚡ Starting Expo..."
    ANDROID_SERIAL=$serial npx expo start --clear "$@"
  } always {
    print "\n🛑 Cleaning up..."
    [[ -n $scrcpy_pid ]] && kill $scrcpy_pid 2>/dev/null
    # Only stop the emulator if we started it
    if [[ -n $emu_pid ]]; then
      adb -s $serial emu kill >/dev/null 2>&1 || kill $emu_pid 2>/dev/null
      print "✅ Emulator and scrcpy stopped"
    else
      print "✅ scrcpy stopped (emulator left running)"
    fi
  }
}



# ==============================
# Waydroid + Expo helper
# ==============================
# Usage: wdstart [expo args...]
# Env: WDSTART_BOOT_TIMEOUT (90s), WDSTART_UI (1 = open the Android window, 0 = headless)
# Waydroid runs Android in an LXC container on the host kernel (binderfs), so it
# boots in seconds and renders on the Intel iGPU via Mesa (NVIDIA is unsupported).
wdstart() {
  emulate -L zsh

  local timeout=${WDSTART_BOOT_TIMEOUT:-90}
  local log="${TMPDIR:-/tmp}/wdstart.log"
  local started=0 ip= serial= cmd
  local start=$SECONDS

  for cmd in waydroid adb npx; do
    (( $+commands[$cmd] )) || { print -u2 "❌ '$cmd' not found in PATH"; return 127 }
  done
  [[ -f package.json ]] || { print -u2 "❌ No package.json here — run from an Expo project"; return 1 }
  [[ -n $WAYLAND_DISPLAY ]] || { print -u2 "❌ Waydroid needs a Wayland session (WAYLAND_DISPLAY is unset)"; return 1 }
  if ! systemctl is-active -q waydroid-container; then
    print -u2 "❌ waydroid-container service is not running. Start it with:"
    print -u2 "   sudo systemctl enable --now waydroid-container"
    return 1
  fi

  {
    if waydroid status 2>/dev/null | grep -q '^Session:[[:space:]]*RUNNING'; then
      print "♻️  Reusing running Waydroid session"
    else
      print "🚀 Starting Waydroid session (log: $log)..."
      waydroid session start >$log 2>&1 &!
      started=1
    fi

    # Open the window before Android boots: without one, Waydroid may freeze the
    # container mid-DHCP and Android never finishes IPv4 setup. Disable that
    # freezing for headless use with: waydroid prop set persist.waydroid.suspend false
    if [[ ${WDSTART_UI:-1} == 1 ]]; then
      print "📱 Opening Waydroid window..."
      waydroid show-full-ui >/dev/null 2>&1 &!
    fi

    print "⏳ Waiting for Android network (timeout ${timeout}s)..."
    until ip=$(waydroid status 2>/dev/null | awk '/^IP address:/{print $3}'); [[ $ip == <->.<->.<->.<-> ]]; do
      if (( SECONDS - start > timeout )); then
        print -u2 "❌ Android never got an IP address — see $log"
        if systemctl is-active -q firewalld &&
           [[ $(firewall-cmd --get-zone-of-interface=waydroid0 2>/dev/null) != trusted ]]; then
          print -u2 "   firewalld is blocking waydroid0 (DHCP/DNS). Fix once with:"
          print -u2 "   sudo firewall-cmd --permanent --zone=trusted --add-interface=waydroid0"
          print -u2 "   sudo firewall-cmd --reload && waydroid session stop"
        fi
        return 1
      fi
      sleep 1
    done
    serial="$ip:5555"

    print "🔌 Connecting adb to $serial..."
    until [[ $(adb -s $serial get-state 2>/dev/null) == device ]]; do
      adb connect $serial >/dev/null 2>&1
      if (( SECONDS - start > timeout )); then
        # `waydroid status` reports the DHCP lease even when Android's network is down
        print -u2 "❌ adb could not connect to $serial — Android's network did not come up."
        print -u2 "   Restart it with the window open: waydroid session stop && waydroid show-full-ui"
        return 1
      fi
      sleep 1
    done
    until [[ $(adb -s $serial shell getprop sys.boot_completed 2>/dev/null) == 1 ]]; do
      (( SECONDS - start > timeout )) && { print -u2 "❌ Android did not finish booting"; return 1 }
      sleep 1
    done
    print "✅ Android ready in $((SECONDS - start))s"

    print "⚡ Starting Expo..."
    ANDROID_SERIAL=$serial npx expo start --clear "$@"
  } always {
    print "\n🛑 Cleaning up..."
    [[ -n $serial ]] && adb disconnect $serial >/dev/null 2>&1
    # Only stop the session if we started it
    if (( started )); then
      waydroid session stop >/dev/null 2>&1
      print "✅ Waydroid session stopped"
    else
      print "✅ adb disconnected (Waydroid session left running)"
    fi
  }
}
