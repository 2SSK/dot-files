import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "dockerUtils.js" as DockerUtils
import "Components"
import qs.Commons
import qs.Services.System
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true
    property real contentPreferredWidth: 850 * Style.uiScaleRatio
    property real contentPreferredHeight: 600 * Style.uiScaleRatio
    property bool sidebarExpanded: false
    property int currentTabIndex: 0
    property var _cachedContainers: []
    property var _pendingCallback: null

    function refreshAll() {
        containerProcess.running = true;
        volumeProcess.running = true;
        networkProcess.running = true;
    }

    function runCommand(cmdArgs, callback) {
        if (commandRunner.running) {
            console.warn("Command runner busy, ignoring:", cmdArgs);
            return ;
        }
        root._pendingCallback = callback;
        commandRunner.command = cmdArgs;
        commandRunner.running = true;
    }

    function startContainer(id) {
        runCommand(["docker", "start", id], refreshAll);
    }

    function stopContainer(id) {
        runCommand(["docker", "stop", id], refreshAll);
    }

    function restartContainer(id) {
        runCommand(["docker", "restart", id], refreshAll);
    }

    function removeContainer(id) {
        runCommand(["docker", "rm", id], refreshAll);
    }

    function removeImage(id) {
        runCommand(["docker", "rmi", id], refreshAll);
    }

    function removeVolume(name) {
        runCommand(["docker", "volume", "rm", name], refreshAll);
    }

    function removeNetwork(id) {
        runCommand(["docker", "network", "rm", id], refreshAll);
    }

    function attemptRunImage(repo, tag) {
        // Reset dialog and start inspect to get default port
        runImageDialog.resetFields(repo, tag, "8080"); 
        
        inspectProcess.targetImage = repo + ":" + tag;
        inspectProcess.running = true;
    }

    function finalizeRunImage(image, port, network, name, envVars) {
        var cmd = ["docker", "run", "-d"];
        if (name && name.trim() !== "") {
            cmd.push("--name");
            cmd.push(name.trim());
        }
        if (envVars && envVars.length > 0) {
            envVars.forEach(function(e) {
                cmd.push("-e");
                cmd.push(e);
            });
        }
        if (port && port.trim() !== "") {
            cmd.push("-p");
            cmd.push(port + ":" + port);
        }
        if (network && network.trim() !== "" && network !== "bridge") {
            cmd.push("--network");
            cmd.push(network);
        }
        cmd.push(image);
        runCommand(cmd, refreshAll);
    }

    anchors.fill: parent
    Component.onCompleted: refreshAll()

    ListModel { id: containersModel }
    ListModel { id: imagesModel }
    ListModel { id: volumesModel }
    ListModel { id: networksModel }

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
            clip: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Sidebar
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: root.sidebarExpanded ? 200 * Style.uiScaleRatio : 56 * Style.uiScaleRatio
                    color: Color.mSurfaceVariant
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Style.marginS
                        spacing: Style.marginS

                        NButton {
                            icon: root.sidebarExpanded ? "layout-sidebar-right-expand" : "layout-sidebar-left-expand"
                            Layout.preferredWidth: 40 * Style.uiScaleRatio
                            Layout.preferredHeight: 40 * Style.uiScaleRatio
                            onClicked: root.sidebarExpanded = !root.sidebarExpanded
                        }

                        Item { height: Style.marginS; width: 1 }

                        SidebarItem { iconName: "brand-docker"; itemText: "Containers"; idx: 0 }
                        SidebarItem { iconName: "photo"; itemText: "Images"; idx: 1 }
                        SidebarItem { iconName: "database"; itemText: "Volumes"; idx: 2 }
                        SidebarItem { iconName: "network"; itemText: "Networks"; idx: 3 }

                        Item { Layout.fillHeight: true }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: Color.mOutline
                        opacity: 0.5
                    }

                    Behavior on Layout.preferredWidth {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }
                }

                // Main Content
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    // Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60 * Style.uiScaleRatio
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Style.marginL
                            spacing: Style.marginM

                            Text {
                                text: {
                                    if (root.currentTabIndex === 0) return "Containers";
                                    if (root.currentTabIndex === 1) return "Images";
                                    if (root.currentTabIndex === 2) return "Volumes";
                                    return "Networks";
                                }
                                font.bold: true
                                font.pixelSize: 20
                                color: Color.mOnSurface
                            }

                            Item { Layout.fillWidth: true }

                            NButton {
                                icon: "refresh"
                                text: "Refresh"
                                onClicked: refreshAll()
                            }
                        }
                    }

                    StackLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: root.currentTabIndex

                        // Containers Tab
                        Item {
                            ListView {
                                id: containersList
                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                model: containersModel
                                delegate: ContainerDelegate {
                                    width: ListView.view.width - (ListView.view.ScrollBar.vertical ? 10 : 0)
                                    onRequestStart: (id) => startContainer(id)
                                    onRequestStop: (id) => stopContainer(id)
                                    onRequestRestart: (id) => restartContainer(id)
                                    onRequestRemove: (id) => removeContainer(id)
                                }
                                spacing: Style.marginS
                                clip: true
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; active: containersList.moving }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: containersModel.count === 0
                                text: "No containers found"
                                color: Color.mOnSurfaceVariant
                            }
                        }

                        // Images Tab
                        Item {
                            ListView {
                                id: imagesList
                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                model: imagesModel
                                delegate: ImageDelegate {
                                    width: ListView.view.width - (ListView.view.ScrollBar.vertical ? 10 : 0)
                                    onRequestRun: (repo, tag) => attemptRunImage(repo, tag)
                                    onRequestRemove: (id) => removeImage(id)
                                }
                                spacing: Style.marginS
                                clip: true
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; active: imagesList.moving }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: imagesModel.count === 0
                                text: "No images found"
                                color: Color.mOnSurfaceVariant
                            }
                        }

                        // Volumes Tab
                        Item {
                            ListView {
                                id: volumesList
                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                model: volumesModel
                                delegate: VolumeDelegate {
                                    width: ListView.view.width - (ListView.view.ScrollBar.vertical ? 10 : 0)
                                    onRequestRemove: (name) => removeVolume(name)
                                }
                                spacing: Style.marginS
                                clip: true
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; active: volumesList.moving }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: volumesModel.count === 0
                                text: "No volumes found"
                                color: Color.mOnSurfaceVariant
                            }
                        }

                        // Networks Tab
                        Item {
                            ListView {
                                id: networksList
                                anchors.fill: parent
                                anchors.margins: Style.marginM
                                model: networksModel
                                delegate: NetworkDelegate {
                                    width: ListView.view.width - (ListView.view.ScrollBar.vertical ? 10 : 0)
                                    onRequestRemove: (id) => removeNetwork(id)
                                }
                                spacing: Style.marginS
                                clip: true
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; active: networksList.moving }
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: networksModel.count === 0
                                text: "No networks found"
                                color: Color.mOnSurfaceVariant
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: commandRunner
        onExited: {
            if (root._pendingCallback) {
                root._pendingCallback();
                root._pendingCallback = null;
            }
        }
        stdout: StdioCollector {}
    }

    Process {
        id: containerProcess
        command: ["docker", "ps", "-a", "--format", "json"]
        stdout: StdioCollector {
            onStreamFinished: {
                var data = DockerUtils.parseContainers(this.text);
                root._cachedContainers = data;
                containersModel.clear();
                data.forEach(function(c) { containersModel.append(c); });
                imageProcess.running = true;
            }
        }
    }

    Process {
        id: imageProcess
        command: ["docker", "images", "--format", "json"]
        stdout: StdioCollector {
            onStreamFinished: {
                var data = DockerUtils.parseImages(this.text, root._cachedContainers);
                imagesModel.clear();
                data.forEach(function(img) { imagesModel.append(img); });
            }
        }
    }

    Process {
        id: volumeProcess
        command: ["docker", "volume", "ls", "--format", "json"]
        stdout: StdioCollector {
            onStreamFinished: {
                var data = DockerUtils.parseVolumes(this.text);
                volumesModel.clear();
                data.forEach(function(v) { volumesModel.append(v); });
            }
        }
    }

    Process {
        id: networkProcess
        command: ["docker", "network", "ls", "--format", "json"]
        stdout: StdioCollector {
            onStreamFinished: {
                var data = DockerUtils.parseNetworks(this.text);
                networksModel.clear();
                data.forEach(function(n) { networksModel.append(n); });
            }
        }
    }

    Process {
        id: inspectProcess
        property string targetImage
        command: ["docker", "inspect", targetImage]
        stdout: StdioCollector {
            onStreamFinished: {
                var detectedPort = DockerUtils.parseExposedPorts(this.text);
                if (!detectedPort)
                    detectedPort = DockerUtils.guessDefaultPort(runImageDialog.imageRepo);

                if (runImageDialog.portField) runImageDialog.portField.text = detectedPort;
                runImageDialog.placeholderPort = detectedPort;
                runImageDialog.open();
            }
        }
    }

    Process {
        id: portCheckProcess
        property string pendingPort
        property string pendingNetwork
        command: ["bash", "-c", "ss -tln | grep :" + pendingPort]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") {
                    runImageDialog.errorMessage = "Port " + portCheckProcess.pendingPort + " is occupied on host.";
                } else {
                    runImageDialog.close();
                    // Retrieve stashed data
                    var pd = runImageDialog.pendingRunData || {};
                    finalizeRunImage(runImageDialog.imageRepo + ":" + runImageDialog.imageTag, portCheckProcess.pendingPort, portCheckProcess.pendingNetwork, pd.name, pd.envs);
                }
            }
        }
    }

    RunImageDialog {
        id: runImageDialog
        pluginApi: root.pluginApi
        networksModel: root.networksModel
        onRequestRun: (image, port, network, name, envs) => finalizeRunImage(image, port, network, name, envs)
        onRequestPortCheck: (port, network) => {
            portCheckProcess.pendingPort = port;
            portCheckProcess.pendingNetwork = network;
            portCheckProcess.running = true;
        }
    }

    component SidebarItem: Rectangle {
        id: sideItem
        property string iconName
        property string itemText
        property int idx
        Layout.fillWidth: true
        Layout.preferredHeight: 40 * Style.uiScaleRatio
        color: root.currentTabIndex === idx ? Color.mSurface : "transparent"
        radius: Style.radiusS

        Rectangle {
            visible: root.currentTabIndex === idx
            width: 3
            height: 16
            radius: 2
            color: Color.mPrimary
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 4
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            spacing: 12

            NIcon {
                icon: iconName
                color: Color.mOnSurface
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
            }

            Text {
                text: sideItem.itemText
                color: Color.mOnSurface
                font.weight: root.currentTabIndex === idx ? Font.DemiBold : Font.Normal
                opacity: root.sidebarExpanded ? 1 : 0
                Layout.fillWidth: true
                elide: Text.ElideRight
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.currentTabIndex = idx
            onEntered: if (root.currentTabIndex !== idx) parent.color = Qt.rgba(1, 1, 1, 0.05);
            onExited: if (root.currentTabIndex !== idx) parent.color = "transparent";
        }
    }
}
