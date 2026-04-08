
import QtQuick
import Quickshell
import qs.Widgets
import qs.Commons

NIconButton {
    property ShellScreen screen
    property var pluginApi: null
    readonly property var mainInstance: pluginApi?.mainInstance

    enabled: mainInstance?.isAvailable ?? false
    icon: "camera-video"
    tooltipText: mainInstance?.buildTooltip()
    colorFg: mainInstance?.isRecording ? Color.mOnPrimary : (mainInstance?.isReplaying ? Color.mSecondary : Color.mPrimary)
    colorBg: mainInstance?.isRecording ? Color.mPrimary : (mainInstance?.isReplaying ? Qt.alpha(Color.mSecondary, 0.25) : Style.capsuleColor)
    onClicked: {
        if (pluginApi && pluginApi.mainInstance) {
            pluginApi.mainInstance.toggleRecording();
        }
    }
}
