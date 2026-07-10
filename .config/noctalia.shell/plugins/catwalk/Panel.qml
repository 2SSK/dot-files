import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

Item {
    id: root
    property var pluginApi: null

    // SmartPanel properties
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 300 * Style.uiScaleRatio
    property real contentPreferredHeight: 300 * Style.uiScaleRatio

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            anchors.margins: Style.marginL
            color: Color.mSurface
            radius: Style.radiusL
            border.color: Color.mOutline
            border.width: Style.borderS

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Style.marginL

                // Big Cat
                Item {
                    id: bigCatItem
                    Layout.preferredWidth: 128 * Style.uiScaleRatio
                    Layout.preferredHeight: 128 * Style.uiScaleRatio
                    Layout.alignment: Qt.AlignHCenter

                    property int frameIndex: 0
                    
                    readonly property bool isRunning: root.pluginApi?.mainInstance?.isRunning ?? false
                    readonly property var icons: root.pluginApi?.mainInstance?.icons || []
                    
                    property int idleFrameIndex: 0
                    readonly property var idleIcons: root.pluginApi?.mainInstance?.idleIcons || []
                    
                    readonly property real cpuUsage: root.pluginApi?.mainInstance?.cpuUsage ?? 0

                    Timer {
                        interval: Math.max(30, 200 - bigCatItem.cpuUsage * 1.7)
                        running: bigCatItem.isRunning
                        repeat: true
                        onTriggered: bigCatItem.frameIndex = (bigCatItem.frameIndex + 1) % bigCatItem.icons.length
                    }
                    
                    Timer {
                        interval: 400
                        running: !bigCatItem.isRunning
                        repeat: true
                        onTriggered: bigCatItem.idleFrameIndex = (bigCatItem.idleFrameIndex + 1) % bigCatItem.idleIcons.length
                    }

                    Image {
                        id: bigCatImage
                        anchors.fill: parent
                        
                        source: (bigCatItem.icons && bigCatItem.icons.length > 0 && bigCatItem.idleIcons && bigCatItem.idleIcons.length > 0)
                                ? (bigCatItem.isRunning
                                    ? Qt.resolvedUrl(bigCatItem.icons[bigCatItem.frameIndex % bigCatItem.icons.length])
                                    : Qt.resolvedUrl(bigCatItem.idleIcons[bigCatItem.idleFrameIndex % bigCatItem.idleIcons.length]))
                                : ""
                        
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true

                        // This handles the programmatic coloring
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: Settings.data.colorSchemes.darkMode ? "white" : "black"
                        }
                    }
                }

                // CPU Stats
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: (pluginApi?.tr("panel.cpuLabel") || "CPU: {usage}%").replace("{usage}", Math.round(root.pluginApi?.mainInstance?.cpuUsage ?? 0))
                    font.pointSize: Style.fontSizeXL
                    font.weight: Font.Bold
                    color: Settings.data.colorSchemes.darkMode ? "white" : "black"
                }
            }
        }
    }
}