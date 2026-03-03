import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

ColumnLayout {
    id: root
    spacing: Style.marginL

    property var pluginApi: null

    property bool editHideInactive:
        pluginApi?.pluginSettings?.hideInactive ??
        pluginApi?.manifest?.metadata?.defaultSettings?.hideInactive ??
        false

    property string editIconColor:
        pluginApi?.pluginSettings?.iconColor ??
        pluginApi?.manifest?.metadata?.defaultSettings?.iconColor ??
        "none"

    property string editDirectory: 
        pluginApi?.pluginSettings?.directory || 
        pluginApi?.manifest?.metadata?.defaultSettings?.directory || 
        ""

    property string editFilenamePattern: 
        pluginApi?.pluginSettings?.filenamePattern || 
        pluginApi?.manifest?.metadata?.defaultSettings?.filenamePattern || 
        "recording_yyyyMMdd_HHmmss"

    property string editFrameRate: 
        pluginApi?.pluginSettings?.frameRate || 
        pluginApi?.manifest?.metadata?.defaultSettings?.frameRate || 
        "60"

    property string editAudioCodec: 
        pluginApi?.pluginSettings?.audioCodec || 
        pluginApi?.manifest?.metadata?.defaultSettings?.audioCodec || 
        "opus"

    property string editVideoCodec: 
        pluginApi?.pluginSettings?.videoCodec || 
        pluginApi?.manifest?.metadata?.defaultSettings?.videoCodec || 
        "h264"

    property string editQuality: 
        pluginApi?.pluginSettings?.quality || 
        pluginApi?.manifest?.metadata?.defaultSettings?.quality || 
        "very_high"

    property string editColorRange: 
        pluginApi?.pluginSettings?.colorRange || 
        pluginApi?.manifest?.metadata?.defaultSettings?.colorRange || 
        "limited"

    property bool editShowCursor: 
        pluginApi?.pluginSettings?.showCursor ?? 
        pluginApi?.manifest?.metadata?.defaultSettings?.showCursor ?? 
        true

    property bool editCopyToClipboard: 
        pluginApi?.pluginSettings?.copyToClipboard ?? 
        pluginApi?.manifest?.metadata?.defaultSettings?.copyToClipboard ?? 
        false

    property string editAudioSource: 
        pluginApi?.pluginSettings?.audioSource || 
        pluginApi?.manifest?.metadata?.defaultSettings?.audioSource || 
        "default_output"

    property string editVideoSource: 
        pluginApi?.pluginSettings?.videoSource || 
        pluginApi?.manifest?.metadata?.defaultSettings?.videoSource || 
        "portal"

    property string editResolution:
        pluginApi?.pluginSettings?.resolution ||
        pluginApi?.manifest?.metadata?.defaultSettings?.resolution ||
        "original"

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("ScreenRecorder", "Cannot save: pluginApi is null")
            return
        }

        pluginApi.pluginSettings.hideInactive = root.editHideInactive
        pluginApi.pluginSettings.iconColor = root.editIconColor
        pluginApi.pluginSettings.directory = root.editDirectory
        pluginApi.pluginSettings.filenamePattern = root.editFilenamePattern
        pluginApi.pluginSettings.frameRate = root.editFrameRate
        pluginApi.pluginSettings.audioCodec = root.editAudioCodec
        pluginApi.pluginSettings.videoCodec = root.editVideoCodec
        pluginApi.pluginSettings.quality = root.editQuality
        pluginApi.pluginSettings.colorRange = root.editColorRange
        pluginApi.pluginSettings.showCursor = root.editShowCursor
        pluginApi.pluginSettings.copyToClipboard = root.editCopyToClipboard
        pluginApi.pluginSettings.audioSource = root.editAudioSource
        pluginApi.pluginSettings.videoSource = root.editVideoSource
        pluginApi.pluginSettings.resolution = root.editResolution

        pluginApi.saveSettings()

        Logger.i("ScreenRecorder", "Settings saved successfully")
    }
    // Icon Color
    NComboBox {
        label: I18n.tr("common.select-icon-color")
        description: I18n.tr("common.select-color-description")
        model: Color.colorKeyModel
        currentKey: root.editIconColor
        onSelected: key => root.editIconColor = key
        minimumWidth: 200
    }

    NTextInputButton {
        label: pluginApi.tr("settings.general.output-folder")
        description: pluginApi.tr("settings.general.output-folder-description")
        placeholderText: Quickshell.env("HOME") + "/Videos"
        text: root.editDirectory
        buttonIcon: "folder-open"
        buttonTooltip: pluginApi.tr("settings.general.output-folder")
        onInputEditingFinished: root.editDirectory = text
        onButtonClicked: folderPicker.openFilePicker()
    }

    // Filename Pattern
    NTextInput {
        label: pluginApi?.tr("settings.filename-pattern.label") || "Filename pattern"
        description: pluginApi?.tr("settings.filename-pattern.description") || "Pattern for generated filenames. Supported: yyyy, yy, MM, M, dd, d, HH, H, mm, m, ss, s (e.g., mycool-recording_yyyyMMdd_HHmmss)"
        placeholderText: "recording_yyyyMMdd_HHmmss"
        text: root.editFilenamePattern
        onTextChanged: root.editFilenamePattern = text
        Layout.fillWidth: true
    }

    NDivider {
        Layout.fillWidth: true
    }

    // Show Cursor
    NToggle {
        label: pluginApi.tr("settings.general.show-cursor")
        description: pluginApi.tr("settings.general.show-cursor-description")
        checked: root.editShowCursor
        onToggled: root.editShowCursor = checked
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.showCursor ?? true
    }

    // Copy to Clipboard
    NToggle {
        label: pluginApi.tr("settings.general.copy-to-clipboard")
        description: pluginApi.tr("settings.general.copy-to-clipboard-description")
        checked: root.editCopyToClipboard
        onToggled: root.editCopyToClipboard = checked
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.copyToClipboard ?? false
    }

    // Hide When Inactive Toggle
    NToggle {
        label: pluginApi.tr("settings.general.hide-when-inactive")
        description: pluginApi.tr("settings.general.hide-when-inactive-description")
        checked: root.editHideInactive
        onToggled: root.editHideInactive = checked
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.hideInactive ?? false
    }

    NDivider {
        Layout.fillWidth: true
    }

    // Video Settings
    ColumnLayout {
        spacing: Style.marginL
        Layout.fillWidth: true

        // Source
        NComboBox {
            label: pluginApi.tr("settings.video.source")
            description: pluginApi.tr("settings.video.source-desc")
            model: [
                {
                    "key": "portal",
                    "name": pluginApi.tr("settings.video.sources-portal")
                },
                {
                    "key": "screen",
                    "name": pluginApi.tr("settings.video.sources-screen")
                }
            ]
            currentKey: root.editVideoSource
            onSelected: key => root.editVideoSource = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.videoSource || "portal"
        }

        // Frame Rate
        NComboBox {
            label: pluginApi.tr("settings.video.frame-rate")
            description: pluginApi.tr("settings.video.frame-rate-desc")
            model: [
                {
                    "key": "5",
                    "name": "5 FPS"
                },
                {
                    "key": "10",
                    "name": "10 FPS"
                },
                {
                    "key": "15",
                    "name": "15 FPS"
                },
                {
                    "key": "20",
                    "name": "20 FPS"
                },
                {
                    "key": "30",
                    "name": "30 FPS"
                },
                {
                    "key": "60",
                    "name": "60 FPS"
                },
                {
                    "key": "100",
                    "name": "100 FPS"
                },
                {
                    "key": "120",
                    "name": "120 FPS"
                },
                {
                    "key": "144",
                    "name": "144 FPS"
                },
                {
                    "key": "165",
                    "name": "165 FPS"
                },
                {
                    "key": "240",
                    "name": "240 FPS"
                }
            ]
            currentKey: root.editFrameRate
            onSelected: key => root.editFrameRate = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.frameRate || "60"
        }

        // Video Quality
        NComboBox {
            label: pluginApi.tr("settings.video.quality")
            description: pluginApi.tr("settings.video.quality-desc")
            model: [
                {
                    "key": "medium",
                    "name": pluginApi.tr("settings.video.quality-medium")
                },
                {
                    "key": "high",
                    "name": pluginApi.tr("settings.video.quality-high")
                },
                {
                    "key": "very_high",
                    "name": pluginApi.tr("settings.video.quality-very-high")
                },
                {
                    "key": "ultra",
                    "name": pluginApi.tr("settings.video.quality-ultra")
                }
            ]
            currentKey: root.editQuality
            onSelected: key => root.editQuality = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.quality || "very_high"
        }

        // Video Codec
        NComboBox {
            label: pluginApi.tr("settings.video.codec")
            description: pluginApi.tr("settings.video.codec-desc")
            model: {
                let options = [
                    {"key": "h264", "name": "H264"},
                    {"key": "hevc", "name": "HEVC"},
                    {"key": "av1", "name": "AV1"},
                    {"key": "vp8", "name": "VP8"},
                    {"key": "vp9", "name": "VP9"}
                ]
                // Only add HDR options if source is 'screen'
                if (root.editVideoSource === "screen") {
                    options.push({"key": "hevc_hdr", "name": "HEVC HDR"})
                    options.push({"key": "av1_hdr", "name": "AV1 HDR"})
                }
                return options
            }
            currentKey: root.editVideoCodec
            onSelected: key => {
                root.editVideoCodec = key
                // If an HDR codec is selected, change the colorRange to full
                if (key.includes("_hdr")) {
                    root.editColorRange = "full"
                }
            }
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.videoCodec || "h264"

            Connections {
                target: root
                function onEditVideoSourceChanged() {
                    if (root.editVideoSource !== "screen" && (root.editVideoCodec === "av1_hdr" || root.editVideoCodec === "hevc_hdr")) {
                        root.editVideoCodec = "h264"
                    }
                }
            }
        }

        // Color Range
        NComboBox {
            label: pluginApi.tr("settings.video.color-range")
            description: pluginApi.tr("settings.video.color-range-desc")
            model: [
                {
                    "key": "limited",
                    "name": pluginApi.tr("settings.video.color-range-limited")
                },
                {
                    "key": "full",
                    "name": pluginApi.tr("settings.video.color-range-full")
                }
            ]
            currentKey: root.editColorRange
            onSelected: key => root.editColorRange = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.colorRange || "limited"
        }

        // Resolution
        NComboBox {
            label: pluginApi.tr("settings.video.resolution")
            description: pluginApi.tr("settings.video.resolution-desc")
            model: [
                {
                    "key": "original",
                    "name": pluginApi.tr("settings.video.resolution-original")
                },
                {
                    "key": "1920x1080",
                    "name": "1920x1080 (Full HD)"
                },
                {
                    "key": "2560x1440",
                    "name": "2560x1440 (QHD)"
                },
                {
                    "key": "3840x2160",
                    "name": "3840x2160 (4K)"
                },
                {
                    "key": "1280x720",
                    "name": "1280x720 (HD)"
                }
            ]
            currentKey: root.editResolution
            onSelected: key => root.editResolution = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.resolution || "original"
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    // Audio Settings
    ColumnLayout {
        spacing: Style.marginL
        Layout.fillWidth: true

        // Audio Source
        NComboBox {
            label: pluginApi.tr("settings.audio.source")
            description: pluginApi.tr("settings.audio.source-desc")
            model: [
                {
                    "key": "none",
                    "name": pluginApi.tr("settings.audio.audio-sources-none")
                },
                {
                    "key": "default_output",
                    "name": pluginApi.tr("settings.audio.audio-sources-system-output")
                },
                {
                    "key": "default_input",
                    "name": pluginApi.tr("settings.audio.audio-sources-microphone-input")
                },
                {
                    "key": "both",
                    "name": pluginApi.tr("settings.audio.audio-sources-both")
                }
            ]
            currentKey: root.editAudioSource
            onSelected: key => root.editAudioSource = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.audioSource || "default_output"
        }

        // Audio Codec
        NComboBox {
            label: pluginApi.tr("settings.audio.codec")
            description: pluginApi.tr("settings.audio.codec-desc")
            model: [
                {
                    "key": "opus",
                    "name": "Opus"
                },
                {
                    "key": "aac",
                    "name": "AAC"
                }
            ]
            currentKey: root.editAudioCodec
            onSelected: key => root.editAudioCodec = key
            defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.audioCodec || "opus"
        }
    }

    Item {
        Layout.fillHeight: true
    }

    NFilePicker {
        id: folderPicker
        selectionMode: "folders"
        title: pluginApi.tr("settings.general.output-folder")
        initialPath: root.editDirectory || Quickshell.env("HOME") + "/Videos"
        onAccepted: paths => {
            if (paths.length > 0) {
                root.editDirectory = paths[0]
            }
        }
    }
}
