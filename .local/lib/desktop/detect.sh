# shellcheck shell=bash
# .local/lib/desktop/detect.sh — detect the running session .
# Source log.sh first. Sets and exports DESKTOP_DISPLAY and DESKTOP_WM.

# Idempotent: sourcing twice must not re-detect.
if [[ -n ${DESKTOP_WM:-} && -n ${DESKTOP_DISPLAY:-} ]]; then
    return 0
fi

detect() {
    # Order matters: sway (an i3 fork) sets I3SOCK too — check SWAYSOCK first.
    local wm=''
    if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
        wm=hyprland
    elif [[ -n ${NIRI_SOCKET:-} ]]; then
        wm=niri
    elif [[ -n ${SWAYSOCK:-} ]]; then
        wm=sway
    elif [[ -n ${I3SOCK:-} ]] || i3 --get-socketpath >/dev/null 2>&1; then
        wm=i3
    else
        die no_wm msg='no supported compositor detected'
    fi

    # Wayland first: XWayland sets DISPLAY too.
    local display=''
    if [[ -n ${WAYLAND_DISPLAY:-} ]]; then
        display=wayland
    elif [[ -n ${DISPLAY:-} ]]; then
        display=x11
    else
        die no_display msg='neither WAYLAND_DISPLAY nor DISPLAY is set'
    fi

    DESKTOP_WM=$wm
    DESKTOP_DISPLAY=$display
    export DESKTOP_WM DESKTOP_DISPLAY

    # No kv args needed: log.sh auto-appends backend= and wm= from the env.
    log_info detect
}

detect
