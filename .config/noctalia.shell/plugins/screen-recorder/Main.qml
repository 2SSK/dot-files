import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Services.System
import qs.Services.Compositor

Item {
    id: root

    property var pluginApi: null

    property bool isRecording: false
    property bool isPending: false
    property bool hasActiveRecording: false
    property string outputPath: ""
    property bool isAvailable: false
    property string detectedMonitor: ""
    property bool usePrimeRun: false

    // Replay state
    property bool isReplaying: false
    property bool isReplayPending: false

    // Single reusable Process object
    Process {
        id: checker
        running: true
        command: ["sh", "-c", "command -v gpu-screen-recorder >/dev/null 2>&1 || (command -v flatpak >/dev/null 2>&1 && flatpak list --app | grep -q 'com.dec05eba.gpu_screen_recorder')"]

        onExited: function (exitCode) {
            isAvailable = (exitCode === 0);
            running = false;
        }

        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    IpcHandler {
        target: "plugin:screen-recorder"

        function toggle() {
            if (root.isAvailable) {
                root.toggleRecording();
            }
        }

        function start() {
            if (root.isAvailable && !root.isRecording && !root.isPending) {
                root.startRecording();
            }
        }

        function stop() {
            if (root.isRecording || root.isPending) {
                root.stopRecording();
            }
        }

        function toggleReplay() {
            if (root.isAvailable) {
                root.toggleReplay();
            }
        }

        function startReplay() {
            if (root.isAvailable && !root.isReplaying && !root.isReplayPending) {
                root.startReplay();
            }
        }

        function stopReplay() {
            if (root.isReplaying || root.isReplayPending) {
                root.stopReplay();
            }
        }

        function saveReplay() {
            if (root.isReplaying) {
                root.saveReplay();
            }
        }
    }

    // Settings shortcuts
    readonly property bool hideInactive: pluginApi?.pluginSettings?.hideInactive ?? false
    readonly property string directory: pluginApi?.pluginSettings?.directory || ""
    readonly property string filenamePattern: pluginApi?.pluginSettings?.filenamePattern || "recording_yyyyMMdd_HHmmss"
    readonly property string frameRate: pluginApi?.pluginSettings?.frameRate || "60"
    readonly property string customFrameRate: pluginApi?.pluginSettings?.customFrameRate || "60"
    readonly property string audioCodec: pluginApi?.pluginSettings?.audioCodec || "opus"
    readonly property string videoCodec: pluginApi?.pluginSettings?.videoCodec || "h264"
    readonly property string quality: pluginApi?.pluginSettings?.quality || "very_high"
    readonly property string colorRange: pluginApi?.pluginSettings?.colorRange || "limited"
    readonly property bool showCursor: pluginApi?.pluginSettings?.showCursor ?? true
    readonly property bool copyToClipboard: pluginApi?.pluginSettings?.copyToClipboard ?? false
    readonly property string audioSource: pluginApi?.pluginSettings?.audioSource || "default_output"
    readonly property string videoSource: pluginApi?.pluginSettings?.videoSource || "portal"
    readonly property string resolution: pluginApi?.pluginSettings?.resolution || "original"
    readonly property bool restorePortalSession: pluginApi?.pluginSettings?.restorePortalSession ?? false

    // Replay settings shortcuts
    readonly property bool replayEnabled: pluginApi?.pluginSettings?.replayEnabled ?? false
    readonly property string replayDuration: pluginApi?.pluginSettings?.replayDuration || "30"
    readonly property string customReplayDuration: pluginApi?.pluginSettings?.customReplayDuration || "30"
    readonly property string replayStorage: pluginApi?.pluginSettings?.replayStorage || "ram"

    readonly property var codecResolutionLimits: ({
            "h264": "4096x4096"
        })

    function buildResolutionFlag() {
        if (resolution !== "original") {
            return `-s ${resolution}`;
        }

        var maxResolution = codecResolutionLimits[videoCodec];
        return maxResolution ? `-s ${maxResolution}` : "";
    }

    function buildTooltip() {
        if (!isAvailable) {
            return pluginApi.tr("messages.not-installed");
        }

        if (isPending) {
            pluginApi.tr("messages.started");
        }

        if (isRecording) {
            return pluginApi.tr("messages.stop-recording");
        }

        if (isReplaying) {
            return pluginApi.tr("messages.replay-active");
        }

        return pluginApi.tr("messages.start-recording");
    }

    // Start or Stop recording
    function toggleRecording() {
        (isRecording || isPending) ? stopRecording() : startRecording();
    }

    // Open recording file
    function openFile(path) {
        if (!path) {
            return;
        }
        Quickshell.execDetached(["xdg-open", path]);
    }

    // Copy file to clipboard as file reference
    function copyFileToClipboard(filePath) {
        if (!filePath) {
            return;
        }
        // Convert path to file:// URI format for copying as file reference
        const fileUri = "file://" + filePath.replace(/ /g, "%20").replace(/'/g, "%27").replace(/"/g, "%22");
        const escapedUri = fileUri.replace(/'/g, "'\\''");
        const command = "printf '%s' '" + escapedUri + "' | wl-copy --type text/uri-list";
        copyToClipboardProcess.exec({
            "command": ["sh", "-c", command]
        });
    }

    // Start screen recording
    function startRecording() {
        if (!isAvailable) {
            return;
        }
        if (isRecording || isPending) {
            return;
        }
        isPending = true;
        hasActiveRecording = false;

        // Close any opened panel
        if ((PanelService.openedPanel !== null) && !PanelService.openedPanel.isClosing) {
            PanelService.openedPanel.close();
        }

        // First, ensure xdg-desktop-portal and a compositor portal are running
        portalCheckProcess.exec({
            "command": ["sh", "-c", "pidof xdg-desktop-portal >/dev/null 2>&1 && (pidof xdg-desktop-portal-wlr >/dev/null 2>&1 || pidof xdg-desktop-portal-hyprland >/dev/null 2>&1 || pidof xdg-desktop-portal-gnome >/dev/null 2>&1 || pidof xdg-desktop-portal-kde >/dev/null 2>&1)"]
        });
    }

    function expandFilenamePattern(pattern) {
        var now = new Date();

        // Known Qt date/time format tokens sorted by length (longest first to match greedily)
        var tokens = ['unix', 'MMMM', 'dddd', 'yyyy', 'MMM', 'ddd', 'zzz', 'HH', 'hh', 'mm', 'ss', 'yy', 'MM', 'dd', 'AP', 'ap', 'M', 'd', 'H', 'h', 'm', 's', 'z', 'A', 'a', 't'];

        // Escape literal text by wrapping non-token sequences in single quotes
        var escaped = "";
        var i = 0;
        var literalBuffer = "";

        while (i < pattern.length) {
            var matched = false;

            // Try to match each token at current position (longest first)
            for (var j = 0; j < tokens.length; j++) {
                var token = tokens[j];
                if (pattern.substr(i, token.length) === token) {
                    // Check if this is a single-letter token that might be part of a word
                    // Only match single letters if they're preceded/followed by non-letter or another token
                    if (token.length === 1) {
                        var prevChar = i > 0 ? pattern[i - 1] : "";
                        var nextChar = i + 1 < pattern.length ? pattern[i + 1] : "";
                        // If surrounded by letters, it's probably part of a word, not a token
                        if ((prevChar.match(/[a-zA-Z]/) || nextChar.match(/[a-zA-Z]/))) {
                            continue; // Skip this token match, treat as literal
                        }
                    }

                    // Flush any accumulated literal text
                    if (literalBuffer) {
                        escaped += "'" + literalBuffer + "'";
                        literalBuffer = "";
                    }

                    if (token === 'unix') {
                        // Replace 'unix' token with the actual timestamp literal
                        // Do not wrap in quotes to avoid creating '' sequences which are interpreted as escaped quotes
                        escaped += Math.floor(now.getTime() / 1000);
                    } else {
                        // Add other tokens as-is
                        escaped += token;
                    }

                    i += token.length;
                    matched = true;
                    break;
                }
            }

            if (!matched) {
                // Character is not part of a token, add to literal buffer
                literalBuffer += pattern[i];
                i++;
            }
        }

        // Flush any remaining literal text
        if (literalBuffer) {
            escaped += "'" + literalBuffer + "'";
        }

        // Use Qt's I18n.locale.toString for proper date/time formatting
        var expanded = I18n.locale.toString(now, escaped);
        return expanded + ".mp4";
    }

    function launchRecorder() {
        // If focused-monitor is selected, detect monitor first
        if (videoSource === "focused-monitor" && CompositorService.isHyprland) {
            var script = 'set -euo pipefail\n' + 'pos=$(hyprctl cursorpos)\n' + 'cx=${pos%,*}; cy=${pos#*,}\n' + 'mon=$(hyprctl monitors -j | jq -r --argjson cx "$cx" --argjson cy "$cy" ' + "'.[] | select(($cx>=.x) and ($cx<(.x+.width)) and ($cy>=.y) and ($cy<(.y+.height))) | .name' " + '| head -n1)\n' + '[ -n "${mon:-}" ] || { echo "MONITOR_NOT_FOUND"; exit 1; }\n' + 'use_prime=0\n' + 'for v in /sys/class/drm/card*/device/vendor; do\n' + '  [ -f "$v" ] || continue\n' + '  if grep -qi "0x10de" "$v"; then\n' + '    card="$(basename "$(dirname "$(dirname "$v")")")"\n' + '    [ -e "/sys/class/drm/${card}-${mon}" ] && use_prime=1 && break\n' + '  fi\n' + 'done\n' + 'echo "${mon}:${use_prime}"';
            monitorDetectProcess.exec({
                "command": ["sh", "-c", script]
            });
            return;
        }

        launchRecorderWithSource(videoSource, false);
    }

    function launchRecorderWithSource(source, primeRun) {
        var pattern = filenamePattern || "recording_yyyyMMdd_HHmmss";
        var filename = expandFilenamePattern(pattern);
        var videoDir = Settings.preprocessPath(directory);
        if (!videoDir) {
            videoDir = Quickshell.env("HOME") + "/Videos";
        }
        if (videoDir && !videoDir.endsWith("/")) {
            videoDir += "/";
        }
        outputPath = videoDir + filename;

        const audioFlags = (() => {
                if (audioSource === "none") {
                    return "";
                }
                if (audioSource === "both") {
                    return `-ac ${audioCodec} -a "default_output|default_input"`;
                }
                return `-ac ${audioCodec} -a ${audioSource}`;
            })();

        var actualFrameRate = (frameRate === "custom") ? customFrameRate : frameRate;
        var resolutionFlag = buildResolutionFlag();
        var restoreFlag = restorePortalSession ? "-restore-portal-session yes" : "";
        var flags = `-w ${source} -f ${actualFrameRate} -k ${videoCodec} ${audioFlags} -q ${quality} -cursor ${showCursor ? "yes" : "no"} -cr ${colorRange} ${resolutionFlag} ${restoreFlag} -o "${outputPath}"`;
        var primePrefix = primeRun ? "prime-run " : "";
        var command = `
    _gpuscreenrecorder_flatpak_installed() {
    flatpak list --app | grep -q "com.dec05eba.gpu_screen_recorder"
    }
    if command -v gpu-screen-recorder >/dev/null 2>&1; then
    ${primePrefix}gpu-screen-recorder ${flags}
    elif command -v flatpak >/dev/null 2>&1 && _gpuscreenrecorder_flatpak_installed; then
    ${primePrefix}flatpak run --command=gpu-screen-recorder --file-forwarding com.dec05eba.gpu_screen_recorder ${flags}
    else
    echo "GPU_SCREEN_RECORDER_NOT_INSTALLED"
    fi`;

        // Use Process to monitor it and read stderr
        recorderProcess.exec({
            "command": ["sh", "-c", command]
        });

        // Start monitoring - if process ends quickly, it was likely cancelled
        pendingTimer.running = true;
    }

    // Stop recording
    function stopRecording() {
        if (!isRecording && !isPending) {
            return;
        }

        ToastService.showNotice(pluginApi.tr("messages.stopping"), outputPath, "video");

        Quickshell.execDetached(["sh", "-c", "pkill -SIGINT -f '^(/nix/store/.*-gpu-screen-recorder|gpu-screen-recorder)' || pkill -SIGINT -f '^com.dec05eba.gpu_screen_recorder'"]);

        isRecording = false;
        isPending = false;
        pendingTimer.running = false;
        monitorTimer.running = false;
        hasActiveRecording = false;

        // Just in case, force kill after 3 seconds
        killTimer.running = true;
    }

    // Helper function to truncate text for toast display
    function truncateForToast(text, maxLength = 128) {
        if (text.length <= maxLength)
            return text;
        return text.substring(0, maxLength) + "…";
    }

    // Helper function to check if output indicates user cancellation
    function isCancelledByUser(stdoutText, stderrText) {
        const stdout = String(stdoutText || "").toLowerCase();
        const stderr = String(stderrText || "").toLowerCase();
        const combined = stdout + " " + stderr;
        return combined.includes("canceled by") || combined.includes("cancelled by") || combined.includes("canceled by user") || combined.includes("cancelled by user") || combined.includes("canceled by the user") || combined.includes("cancelled by the user");
    }

    // Process to run and monitor gpu-screen-recorder
    Process {
        id: recorderProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function (exitCode, exitStatus) {
            const stdout = String(recorderProcess.stdout.text || "").trim();
            const stderr = String(recorderProcess.stderr.text || "").trim();
            const wasCancelled = isCancelledByUser(stdout, stderr);

            if (isPending) {
                // Process ended while we were pending - likely cancelled or error
                isPending = false;
                pendingTimer.running = false;

                // Check if gpu-screen-recorder is not installed
                if (stdout === "GPU_SCREEN_RECORDER_NOT_INSTALLED") {
                    ToastService.showError(pluginApi.tr("messages.not-installed"), pluginApi.tr("messages.not-installed-desc"));
                    return;
                }

                // If it failed to start, show a clear error toast with stderr
                // But don't show error if user intentionally cancelled via portal
                if (exitCode !== 0) {
                    const filteredError = filterStderr(stderr);
                    if (filteredError.length > 0 && !wasCancelled) {
                        ToastService.showError(pluginApi.tr("messages.failed-start"), truncateForToast(filteredError));
                        Logger.e("ScreenRecorder", filteredError);
                    }
                }
            } else if (isRecording || hasActiveRecording) {
                // Process ended normally while recording
                isRecording = false;
                monitorTimer.running = false;
                if (exitCode === 0) {
                    // ToastService.showNotice(pluginApi.tr("messages.saved"), outputPath, "video")
                    ToastService.showNotice(pluginApi.tr("messages.saved"), outputPath, "video", 3000, pluginApi.tr("messages.open-file"), () => openFile(outputPath));

                    if (copyToClipboard) {
                        copyFileToClipboard(outputPath);
                    }
                } else {
                    // Don't show error if user intentionally cancelled
                    const filteredError = filterStderr(stderr);
                    if (!wasCancelled) {
                        if (filteredError.length > 0) {
                            ToastService.showError(pluginApi.tr("messages.failed-start"), truncateForToast(filteredError));
                            Logger.e("ScreenRecorder", filteredError);
                        } else if (exitCode !== 0) {
                            ToastService.showError(pluginApi.tr("messages.failed-start"), pluginApi.tr("messages.failed-general"));
                        }
                    }
                }
                hasActiveRecording = false;
            } else if (!isPending && exitCode === 0 && outputPath) {
                // Fallback: if process exited successfully with an outputPath, handle it
                // ToastService.showNotice(pluginApi.tr("messages.saved"), outputPath, "video")
                ToastService.showNotice(pluginApi.tr("messages.saved"), outputPath, "video", 3000, pluginApi.tr("messages.open-file"), () => openFile(outputPath));

                if (copyToClipboard) {
                    copyFileToClipboard(outputPath);
                }
            }
        }
    }

    // Pre-flight check for xdg-desktop-portal
    Process {
        id: portalCheckProcess
        onExited: function (exitCode, exitStatus) {
            if (exitCode === 0) {
                // Portals available, proceed to launch
                launchRecorder();
            } else {
                isPending = false;
                hasActiveRecording = false;
                ToastService.showError(pluginApi.tr("messages.no-portals"), pluginApi.tr("messages.no-portals-desc"));
            }
        }
    }

    // Detect focused monitor on Hyprland
    Process {
        id: monitorDetectProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function (exitCode, exitStatus) {
            const output = String(monitorDetectProcess.stdout.text || "").trim();

            if (exitCode !== 0 || output === "MONITOR_NOT_FOUND" || !output) {
                isPending = false;
                hasActiveRecording = false;
                ToastService.showError(pluginApi.tr("messages.failed-start"), pluginApi.tr("messages.monitor-not-found"));
                return;
            }

            // Parse "MONITOR_NAME:USE_PRIME" format
            const parts = output.split(":");
            const monitorName = parts[0];
            const primeRun = parts.length > 1 && parts[1] === "1";

            detectedMonitor = monitorName;
            usePrimeRun = primeRun;

            Logger.i("ScreenRecorder", "Detected monitor: " + monitorName + (primeRun ? " (prime-run)" : ""));
            launchRecorderWithSource(monitorName, primeRun);
        }
    }

    // Process to copy file to clipboard
    Process {
        id: copyToClipboardProcess
        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0) {
                Logger.e("ScreenRecorder", "Failed to copy file to clipboard, exit code:", exitCode);
            }
        }
    }

    Timer {
        id: pendingTimer
        interval: 2000 // Wait 2 seconds to see if process stays alive
        running: false
        repeat: false
        onTriggered: {
            if (isPending && recorderProcess.running) {
                // Process is still running after 2 seconds - assume recording started successfully
                isPending = false;
                isRecording = true;
                hasActiveRecording = true;
                monitorTimer.running = true;
            } else if (isPending) {
                // Process not running anymore - was cancelled or failed
                isPending = false;
            }
        }
    }

    // Monitor timer to periodically check if we're still recording
    Timer {
        id: monitorTimer
        interval: 2000
        running: false
        repeat: true
        onTriggered: {
            if (!recorderProcess.running && isRecording) {
                isRecording = false;
                running = false;
            }
        }
    }

    Timer {
        id: killTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["sh", "-c", "pkill -9 -f '^(/nix/store/.*-gpu-screen-recorder|gpu-screen-recorder)' 2>/dev/null || pkill -9 -f '^com.dec05eba.gpu_screen_recorder' 2>/dev/null || true"]);
        }
    }

    // ─── Replay Buffer ───────────────────────────────────────────────────

    function toggleReplay() {
        (isReplaying || isReplayPending) ? stopReplay() : startReplay();
    }

    function startReplay() {
        if (!isAvailable) return;
        if (isReplaying || isReplayPending) return;
        if (!replayEnabled) return;

        isReplayPending = true;

        replayPortalCheckProcess.exec({
            "command": ["sh", "-c", "pidof xdg-desktop-portal >/dev/null 2>&1 && (pidof xdg-desktop-portal-wlr >/dev/null 2>&1 || pidof xdg-desktop-portal-hyprland >/dev/null 2>&1 || pidof xdg-desktop-portal-gnome >/dev/null 2>&1 || pidof xdg-desktop-portal-kde >/dev/null 2>&1)"]
        });
    }

    function launchReplay() {
        // If focused-monitor is selected, detect monitor first
        if (videoSource === "focused-monitor" && CompositorService.isHyprland) {
            var script = 'set -euo pipefail\n' + 'pos=$(hyprctl cursorpos)\n' + 'cx=${pos%,*}; cy=${pos#*,}\n' + 'mon=$(hyprctl monitors -j | jq -r --argjson cx "$cx" --argjson cy "$cy" ' + "'.[] | select(($cx>=.x) and ($cx<(.x+.width)) and ($cy>=.y) and ($cy<(.y+.height))) | .name' " + '| head -n1)\n' + '[ -n "${mon:-}" ] || { echo "MONITOR_NOT_FOUND"; exit 1; }\n' + 'use_prime=0\n' + 'for v in /sys/class/drm/card*/device/vendor; do\n' + '  [ -f "$v" ] || continue\n' + '  if grep -qi "0x10de" "$v"; then\n' + '    card="$(basename "$(dirname "$(dirname "$v")")")"\n' + '    [ -e "/sys/class/drm/${card}-${mon}" ] && use_prime=1 && break\n' + '  fi\n' + 'done\n' + 'echo "${mon}:${use_prime}"';
            replayMonitorDetectProcess.exec({
                "command": ["sh", "-c", script]
            });
            return;
        }

        launchReplayWithSource(videoSource, false);
    }

    function launchReplayWithSource(source, primeRun) {
        var videoDir = Settings.preprocessPath(directory);
        if (!videoDir) {
            videoDir = Quickshell.env("HOME") + "/Videos";
        }
        // Ensure directory ends with / for gpu-screen-recorder
        if (videoDir && !videoDir.endsWith("/")) {
            videoDir += "/";
        }

        var actualDuration = (replayDuration === "custom") ? customReplayDuration : replayDuration;
        var actualFrameRate = (frameRate === "custom") ? customFrameRate : frameRate;
        var resolutionFlag = buildResolutionFlag();

        const audioFlags = (() => {
                if (audioSource === "none") {
                    return "";
                }
                if (audioSource === "both") {
                    return `-ac ${audioCodec} -a "default_output|default_input"`;
                }
                return `-ac ${audioCodec} -a ${audioSource}`;
            })();

        var restoreFlag = restorePortalSession ? "-restore-portal-session yes" : "";
        var flags = `-w ${source} -c mp4 -f ${actualFrameRate} -k ${videoCodec} ${audioFlags} -q ${quality} -cursor ${showCursor ? "yes" : "no"} -cr ${colorRange} ${resolutionFlag} -r ${actualDuration} -replay-storage ${replayStorage} ${restoreFlag} -o "${videoDir}"`;
        var primePrefix = primeRun ? "prime-run " : "";
        var command = `
    _gpuscreenrecorder_flatpak_installed() {
    flatpak list --app | grep -q "com.dec05eba.gpu_screen_recorder"
    }
    if command -v gpu-screen-recorder >/dev/null 2>&1; then
    ${primePrefix}gpu-screen-recorder ${flags}
    elif command -v flatpak >/dev/null 2>&1 && _gpuscreenrecorder_flatpak_installed; then
    ${primePrefix}flatpak run --command=gpu-screen-recorder --file-forwarding com.dec05eba.gpu_screen_recorder ${flags}
    else
    echo "GPU_SCREEN_RECORDER_NOT_INSTALLED"
    fi`;

        replayProcess.exec({
            "command": ["sh", "-c", command]
        });

        replayPendingTimer.running = true;
    }

    function stopReplay() {
        if (!isReplaying && !isReplayPending) return;

        // Send SIGINT to stop the replay daemon
        Quickshell.execDetached(["sh", "-c", "pkill -SIGINT -f '^(/nix/store/.*-gpu-screen-recorder|gpu-screen-recorder).*-r ' || pkill -SIGINT -f '^com.dec05eba.gpu_screen_recorder.*-r '"]);

        isReplaying = false;
        isReplayPending = false;
        replayPendingTimer.running = false;
        replayMonitorTimer.running = false;

        ToastService.showNotice(pluginApi.tr("messages.replay-stopped"), "", "info");

        // Force kill after 3 seconds, just in case
        replayKillTimer.running = true;
    }

    function saveReplay() {
        if (!isReplaying) return;

        // Send SIGUSR1 to save the replay buffer
        Quickshell.execDetached(["sh", "-c", "pkill -SIGUSR1 -f '^(/nix/store/.*-gpu-screen-recorder|gpu-screen-recorder).*-r ' || pkill -SIGUSR1 -f '^com.dec05eba.gpu_screen_recorder.*-r '"]);
    }

    // Replay Process
    Process {
        id: replayProcess
        stdout: SplitParser {
            onRead: data => {
                // gpu-screen-recorder outputs the saved file path to stdout on each SIGUSR1 save
                var savedPath = String(data).trim();
                if (savedPath && savedPath.length > 0 && !savedPath.startsWith("GPU_SCREEN_RECORDER")) {
                    ToastService.showNotice(
                        pluginApi.tr("messages.replay-saved"),
                        savedPath, "video", 3000,
                        pluginApi.tr("messages.open-file"),
                        () => openFile(savedPath)
                    );

                    if (copyToClipboard) {
                        copyFileToClipboard(savedPath);
                    }
                }
            }
        }
        stderr: StdioCollector {}
        onExited: function(exitCode, exitStatus) {
            const stderr = String(replayProcess.stderr.text || "").trim();
            const wasCancelled = isCancelledByUser("", stderr);
            const filteredError = filterStderr(stderr);

            if (isReplayPending) {
                isReplayPending = false;
                replayPendingTimer.running = false;

                if (exitCode !== 0 && filteredError.length > 0 && !wasCancelled) {
                    ToastService.showError(pluginApi.tr("messages.replay-failed"), truncateForToast(filteredError));
                    Logger.e("ScreenRecorder", "Replay: " + filteredError);
                }
            } else if (isReplaying) {
                isReplaying = false;
                replayMonitorTimer.running = false;

                if (exitCode !== 0 && !wasCancelled) {
                    if (filteredError.length > 0) {
                        ToastService.showError(pluginApi.tr("messages.replay-failed"), truncateForToast(filteredError));
                        Logger.e("ScreenRecorder", "Replay: " + filteredError);
                    }
                }
            }
        }
    }

    // Filter stderr to only include actual errors (starting with gsr error: or gsr fatal:)
    function filterStderr(text) {
        if (!text) return "";
        const lines = text.split("\n");
        const errorLines = lines.filter(line => {
            const lower = line.toLowerCase();
            if (lower.includes("gsr info:") || lower.includes("gsr notice:") || lower.includes("(error: none)")) return false;
            return lower.includes("gsr error:") || lower.includes("gsr fatal:") || lower.includes("failed to") || lower.includes("error:");
        });
        if (errorLines.length === 0) return "";
        return errorLines.join("\n").trim();
    }

    // Portal check for replay
    Process {
        id: replayPortalCheckProcess
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                launchReplay();
            } else {
                isReplayPending = false;
                ToastService.showError(pluginApi.tr("messages.no-portals"), pluginApi.tr("messages.no-portals-desc"));
            }
        }
    }

    // Monitor detection for replay on Hyprland
    Process {
        id: replayMonitorDetectProcess
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(exitCode, exitStatus) {
            const output = String(replayMonitorDetectProcess.stdout.text || "").trim();

            if (exitCode !== 0 || output === "MONITOR_NOT_FOUND" || !output) {
                isReplayPending = false;
                ToastService.showError(pluginApi.tr("messages.replay-failed"), pluginApi.tr("messages.monitor-not-found"));
                return;
            }

            const parts = output.split(":");
            const monitorName = parts[0];
            const primeRun = parts.length > 1 && parts[1] === "1";

            Logger.i("ScreenRecorder", "Replay: Detected monitor: " + monitorName + (primeRun ? " (prime-run)" : ""));
            launchReplayWithSource(monitorName, primeRun);
        }
    }

    Timer {
        id: replayPendingTimer
        interval: 2000
        running: false
        repeat: false
        onTriggered: {
            if (root.isReplayPending && replayProcess.running) {
                root.isReplayPending = false;
                root.isReplaying = true;
                replayMonitorTimer.running = true;
                ToastService.showNotice(pluginApi.tr("messages.replay-started"), "", "info");
            } else if (root.isReplayPending) {
                root.isReplayPending = false;
            }
        }
    }

    Timer {
        id: replayMonitorTimer
        interval: 2000
        running: false
        repeat: true
        onTriggered: {
            if (!replayProcess.running && root.isReplaying) {
                root.isReplaying = false;
                running = false;
            }
        }
    }

    Timer {
        id: replayKillTimer
        interval: 3000
        running: false
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["sh", "-c", "pkill -9 -f '^(/nix/store/.*-gpu-screen-recorder|gpu-screen-recorder).*-r ' 2>/dev/null || pkill -9 -f '^com.dec05eba.gpu_screen_recorder.*-r ' 2>/dev/null || true"]);
        }
    }

}
