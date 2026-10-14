#!/usr/bin/env bash
# Does a fresh machine come out right? A new VM from the distro's cloud image clones the repo from
# GitHub, as anyone would, runs ./setup.sh -y, and is checked; then it's deleted.
#   tests/vm/repro.sh arch|fedora [--keep]
# Slow (packages download): tens of minutes. One VM at a time, 2 CPUs and 3G.
set -uo pipefail

distro=${1:?usage: repro.sh arch|fedora [--keep]}
keep=${2:-}
name="repro-$distro"
work="${XDG_CACHE_HOME:-$HOME/.cache}/repro"
mkdir -p "$work"
key="$work/key"
[[ -f $key ]] || ssh-keygen -q -t ed25519 -N '' -f "$key"
log="$work/$name.log"
: >"$log"

say() { printf '\e[1m%s\e[0m\n' "$*" | tee -a "$log"; }
ip_of() { virsh -c qemu:///system domifaddr "$name" --source lease 2>/dev/null | awk '$3 == "ipv4" { sub(/\/.*/, "", $4); print $4; exit }'; }
in_vm() { ssh -i "$key" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5 "$USER@$ip" "$@"; }

say "== $name: create"
vm rm "$name" >/dev/null 2>&1 <<<y || true
VM_PASSWORD="$(head -c 18 /dev/urandom | base64)" vm create "$name" --image "$distro" --cpus 2 --mem 3G --key "$key.pub" >>"$log" 2>&1 </dev/null ||
	{ say "vm create failed (see $log)"; exit 1; }

say "== waiting for it to boot and finish cloud-init"
ip=""
for _ in $(seq 120); do
	ip="$(ip_of)"
	[[ -n $ip ]] && in_vm true 2>/dev/null && break
	sleep 5
done
[[ -n $ip ]] || { say "no address after 10 min"; exit 1; }
in_vm 'cloud-init status --wait >/dev/null 2>&1; true'
say "   up at $ip"

# Arch: this laptop's mirror list (the image's default mirror can be slow enough to stall a run)
if [[ $distro == arch && -r /etc/pacman.d/mirrorlist ]]; then
	in_vm 'sudo tee /etc/pacman.d/mirrorlist >/dev/null' </etc/pacman.d/mirrorlist
fi

say "== clone from GitHub and run ./setup.sh -y"
in_vm 'git clone -q https://github.com/2SSK/dot-files ~/dot-files || { (command -v pacman && sudo pacman -Sy --noconfirm git || sudo dnf -y install git) >/dev/null && git clone -q https://github.com/2SSK/dot-files ~/dot-files; }' >>"$log" 2>&1
start=$(date +%s)
in_vm 'cd ~/dot-files && ./setup.sh -y' >>"$log" 2>&1
setup_rc=$?
say "   setup.sh exit $setup_rc after $(( ($(date +%s) - start) / 60 )) min"

say "== checks"
in_vm 'bash -s' <<'EOF' | tee -a "$log"
pass=0 fail=0
check() {
	local out
	if out="$(eval "$2" 2>&1)"; then echo "  ok    $1"; pass=$((pass+1)); return; fi
	echo "  FAIL  $1"; fail=$((fail+1))
	printf '%s\n' "$out" | grep -v '^$' | head -6 | sed 's/^/          /'
}
check "configs linked into ~ (sway, i3, shell, nvim)" '[ -L ~/.config/sway/config ] && [ -L ~/.config/i3/config ] && [ -L ~/.config/quickshell/desktop/shell.qml ] && [ -L ~/.config/nvim/init.lua ]'
check "theme rendered" '[ -f ~/.local/state/desktop/theme/palette.json ] && ~/.local/bin/theme current'
for p in sway i3 qs kitty foot nvim tmux zsh fzf fd rg jq stow brightnessctl playerctl swayidle wl-copy; do
	check "installed: $p" "command -v $p"
done
check "login shell is zsh" '[ "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)" ]'
check "sway accepts its config" 'sway -C -c ~/.config/sway/config'
check "i3 accepts its config" 'i3 -C -c ~/.config/i3/config'
check "zsh starts clean" '[ -z "$(zsh -i -c exit 2>&1 | grep -v "^$")" ]'
check "nvim starts clean (plugins install on first start)" '[ -z "$(timeout 300 nvim --headless +qa 2>&1 | grep -i error)" ]'
# the shell, in a hidden headless sway: it loads with no script errors
cat >/tmp/headless.conf <<'CONF'
output HEADLESS-1 resolution 1600x1000
exec env QT_QPA_PLATFORM=wayland qs -c desktop > /tmp/qs.log 2>&1
CONF
(env -u WAYLAND_DISPLAY WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 WLR_RENDERER=pixman sway -c /tmp/headless.conf >/tmp/sway.log 2>&1 &)
sleep 25
check "shell starts in sway" 'grep -q "Configuration Loaded" /tmp/qs.log || { tail -3 /tmp/sway.log; tail -3 /tmp/qs.log; false; }'
check "shell log has no script errors" '! grep -E "TypeError|ReferenceError|is not defined|is not a type|Type .* unavailable" /tmp/qs.log'
pkill -x sway
echo "  -- $pass passed, $fail failed"
[ "$fail" -eq 0 ]
EOF
checks_rc=${PIPESTATUS[0]}

if [[ $keep != --keep ]]; then
	say "== delete the VM"
	vm rm "$name" >>"$log" 2>&1 <<<y || virsh -c qemu:///system undefine "$name" --remove-all-storage >>"$log" 2>&1
fi
if ((setup_rc == 0 && checks_rc == 0)); then
	say "PASS: $distro"
else
	say "FAIL: $distro (log: $log)"
	exit 1
fi
