import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets
import qs.Services.System

DraggableDesktopWidget {
    id: root
    property var pluginApi: null

    implicitWidth: 200
    implicitHeight: 80

    showBackground: !(root.pluginApi?.mainInstance?.hideBackground ?? false)

    property int frameIndex: 0
    
    readonly property var icons: root.pluginApi?.mainInstance?.icons || []
    
    property int idleFrameIndex: 0
    readonly property var idleIcons: root.pluginApi?.mainInstance?.idleIcons || []

    readonly property bool isRunning: root.pluginApi?.mainInstance?.isRunning ?? false
    readonly property real cpuUsage: root.pluginApi?.mainInstance?.cpuUsage ?? 0

    Timer {
        interval: Math.max(30, 200 - root.cpuUsage * 1.7)
        running: root.isRunning
        repeat: true
        onTriggered: {
            root.frameIndex = (root.frameIndex + 1) % root.icons.length
        }
    }
    
    Timer {
        interval: 400
        running: !root.isRunning
        repeat: true
        onTriggered: {
            root.idleFrameIndex = (root.idleFrameIndex + 1) % root.idleIcons.length
        }
    }

    property url currentIconSource: (root.icons && root.icons.length > 0 && root.idleIcons && root.idleIcons.length > 0)
                       ? (root.isRunning
                           ? Qt.resolvedUrl(root.icons[root.frameIndex % root.icons.length])
                           : Qt.resolvedUrl(root.idleIcons[root.idleFrameIndex % root.idleIcons.length]))
                       : ""

    RowLayout {
        anchors.fill: parent
        spacing: 5
        
        Image {
            id: iconImage
            source: root.currentIconSource
            Layout.fillHeight: true
            Layout.preferredWidth: height
            
            sourceSize.height: height
            sourceSize.width: width
            
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: false 

            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: Settings.data.colorSchemes.darkMode ? "white" : "black"
            }
        }

        Text {
            text: Math.round(root.cpuUsage) + "%"
            color: Settings.data.colorSchemes.darkMode ? "white" : "black"
            font.bold: true
            font.pixelSize: 40
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
