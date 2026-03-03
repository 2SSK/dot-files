import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Widgets

Dialog {
    id: runImageDialog

    property string imageRepo: ""
    property string imageTag: ""
    property string placeholderPort: ""
    property string errorMessage: ""
    property var pluginApi: null
    property var networksModel: []
    property alias portField: portField

    signal requestRun(string image, string port, string network, string name, var envVars)
    signal requestPortCheck(string port, string network)

    title: "Run Container"
    modal: true
    parent: Overlay.overlay
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    // width: 450 * Style.uiScaleRatio

    // Internal model for env vars
    ListModel {
        id: envVarsModel
    }

    // Helper to reset fields
    function resetFields(repo, tag, port) {
        imageRepo = repo
        imageTag = tag
        errorMessage = ""
        placeholderPort = port
        containerNameField.text = ""
        exposePortCheck.checked = true
        envVarsModel.clear()
        
        // Default network
        var defNet = (pluginApi && pluginApi.pluginSettings && pluginApi.pluginSettings.defaultNetwork) || "bridge"
        var netIdx = 0
        if (networksModel && networksModel.count > 0) {
            for (var i=0; i<networksModel.count; ++i) {
                if (networksModel.get(i).name === defNet) {
                    netIdx = i;
                    break;
                }
            }
        }
        networkCombo.currentIndex = netIdx
        
        if (portField) portField.text = port
    }

    ColumnLayout {
        spacing: Style.marginM
        width: 400 * Style.uiScaleRatio

        Text {
            text: "Run " + runImageDialog.imageRepo + ":" + runImageDialog.imageTag
            font.bold: true
            font.pixelSize: 16
            color: Color.mOnSurface
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Color.mOutline
            opacity: 0.5
        }

        // --- Container Name ---
        Text {
            text: "Container Name (Optional)"
            color: Color.mOnSurfaceVariant
            font.bold: true
        }
        TextField {
            id: containerNameField
            Layout.fillWidth: true
            placeholderText: "e.g. my-redis"
        }

        // --- Network & Port ---
        GridLayout {
            columns: 2
            rowSpacing: Style.marginS
            columnSpacing: Style.marginM
            Layout.fillWidth: true

            // Network Label
            Text {
                text: "Network:"
                color: Color.mOnSurfaceVariant
                font.bold: true
            }

            // Port Label
             Text {
                text: "Host Port:"
                color: Color.mOnSurfaceVariant
                opacity: exposePortCheck.checked ? 1 : 0.5
                font.bold: true
            }

            // Network Input
            ComboBox {
                id: networkCombo
                Layout.fillWidth: true
                textRole: "name"
                model: runImageDialog.networksModel
            }

            // Host Port Input
            TextField {
                id: portField
                Layout.fillWidth: true
                enabled: exposePortCheck.checked
                placeholderText: "Default: " + runImageDialog.placeholderPort
                text: runImageDialog.placeholderPort
                validator: IntValidator { bottom: 1; top: 65535 }
            }
            
            // Port Checkbox (spanning 2 columns effectively, but we put it in a row/item if needed, or just let it float)
             CheckBox {
                id: exposePortCheck
                text: "Expose Port"
                checked: true
                Layout.columnSpan: 2
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Color.mOutline
            opacity: 0.5
        }

        // --- Environment Variables ---
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Environment Variables"
                color: Color.mOnSurfaceVariant
                font.bold: true
                Layout.fillWidth: true
            }
            NButton {
                icon: "plus"
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                onClicked: envVarsModel.append({ key: "", value: "" })
            }
        }

        ListView {
            id: envList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 150) // Max height constraint
            model: envVarsModel
            clip: true
            spacing: 5
            
            delegate: RowLayout {
                width: ListView.view.width
                spacing: 5
                
                TextField {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1 // flexible
                    placeholderText: "KEY"
                    text: model.key
                    onTextEdited: model.key = text
                }
                Text { text: "="; color: Color.mOnSurfaceVariant }
                TextField {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1 // flexible
                    placeholderText: "VALUE"
                    text: model.value
                    onTextEdited: model.value = text
                }
                NButton {
                    icon: "close"
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    onClicked: envVarsModel.remove(index)
                }
            }
        }
        
        // --- Footer / Error ---
        Text {
            text: runImageDialog.errorMessage
            color: Color.mError
            visible: text !== ""
            font.bold: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
    }

    footer: DialogButtonBox {
        Button {
            text: "Cancel"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: runImageDialog.close()
        }

        Button {
            text: "Run"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: {
                var port = portField.text
                var networkToUse = ""
                if (networkCombo.currentIndex >= 0 && networksModel.count > 0) {
                     networkToUse = networksModel.get(networkCombo.currentIndex).name
                } else {
                     networkToUse = "bridge"
                }

                // Collect Env Vars
                var envs = []
                for(var i=0; i<envVarsModel.count; ++i) {
                    var k = envVarsModel.get(i).key.trim()
                    var v = envVarsModel.get(i).value
                    if (k !== "") envs.push(k + "=" + v)
                }

                if (!exposePortCheck.checked || port.trim() === "") {
                    requestRun(runImageDialog.imageRepo + ":" + runImageDialog.imageTag, "", networkToUse, containerNameField.text, envs)
                    runImageDialog.close()
                    return
                }
                
                // Otherwise request port check
                runImageDialog.errorMessage = ""
                // We stash the extra data in properties so we can use them after the port check callback
                runImageDialog.pendingRunData = {
                    name: containerNameField.text,
                    envs: envs,
                    network: networkToUse
                }
                requestPortCheck(port, networkToUse)
            }
        }
    }

    // Temporary storage for pending run data during port check
    property var pendingRunData: ({})
}
