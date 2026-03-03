import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services.System
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property real baseSize: Style.capsuleHeight
    property bool applyUiScale: false
    property string tooltipText: dockerAvailable ? (pluginApi ? pluginApi.tr("tooltip.running_containers").arg(runningCount) : "Containers: " + runningCount) : (pluginApi ? pluginApi.tr("tooltip.docker_not_available") : "Docker not available")
    property string tooltipDirection: BarService.getTooltipDirection()
    property string density: Settings.data.bar.density
    property bool enabled: true
    property bool allowClickWhenDisabled: false
    property bool hovering: false
    property color colorBg: Color.mSurfaceVariant
    property color colorFg: Color.mPrimary
    property color colorBgHover: Color.mHover
    property color colorFgHover: Color.mOnHover
    property color colorBorder: Color.mOutline
    property color colorBorderHover: Color.mOutline
    property real customRadius: Style.radiusL
    property bool dockerAvailable: false
    property int runningCount: 0

    signal entered()
    signal exited()
    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal wheel(int angleDelta)

    readonly property real contentWidth: applyUiScale ? Math.round(baseSize * Style.uiScaleRatio) : Math.round(baseSize)
    readonly property real contentHeight: applyUiScale ? Math.round(baseSize * Style.uiScaleRatio) : Math.round(baseSize)

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Component.onCompleted: dockerCheckProcess.running = true

    Process {
        id: dockerCountProcess

        command: ["docker", "ps", "-q"]

        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text.trim();
                runningCount = output === "" ? 0 : output.split('\n').length;
            }
        }
    }

    Timer {
        interval: (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.refreshInterval) || 5000
        running: true
        repeat: true
        onTriggered: {
            if (dockerAvailable)
                dockerCountProcess.running = true;
        }
    }

    Process {
        id: dockerCheckProcess

        running: false
        command: ["docker", "--version"]
        onExited: (code, status) => {
            dockerAvailable = (code === 0);
            if (dockerAvailable)
                dockerCountProcess.running = true;
        }
    }

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        opacity: root.enabled ? (dockerAvailable ? Style.opacityFull : Style.opacityMedium) : Style.opacityMedium
        color: hovering ? colorBgHover : colorBg
        radius: Math.min((customRadius >= 0 ? customRadius : Style.iRadiusL), width / 2)
        border.color: hovering ? colorBorderHover : colorBorder
        border.width: Style.borderS

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }

        NIcon {
            id: icon

            anchors.centerIn: parent
            icon: "brand-docker"
            color: dockerAvailable ? (hovering ? colorFgHover : colorFg) : Color.mOnSurfaceVariant
        }

        Rectangle {
            z: 1
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 3
            anchors.rightMargin: 3
            width: 6
            height: 6
            radius: 3
            color: runningCount > 0 ? "#4caf50" : "#f44336"
            visible: dockerAvailable
            border.width: 1
            border.color: visualCapsule.color
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            root.hovering = true;
            root.entered();
        }
        onExited: {
            root.hovering = false;
            root.exited();
        }
        onClicked: {
            if (pluginApi && dockerAvailable)
                pluginApi.openPanel(root.screen);
        }
        onPressAndHold: root.rightClicked()
        onWheel: (wheel) => {
            return root.wheel(wheel.angleDelta.y);
        }
    }
}
