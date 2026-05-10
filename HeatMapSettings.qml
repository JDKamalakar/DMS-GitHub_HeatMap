import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services

PluginSettings {
    id: root
    pluginId: "githubHeatmapRevive"

    PluginGlobalVar {
        id: usernameSetting
        varName: "username"
        defaultValue: ""
    }

    PluginGlobalVar {
        id: refreshIntervalSetting
        varName: "refreshInterval"
        defaultValue: 300
    }

    function loadValue(key, def) {
        return PluginService.loadPluginData(root.pluginId, key, def);
    }

    function saveValue(key, val) {
        PluginService.savePluginData(root.pluginId, key, val);
        PluginService.setGlobalVar(root.pluginId, key, val);
    }

    // Load persisted settings when settings UI opens
    Component.onCompleted: {
        const savedUsername = loadValue("username", "")
        const savedInterval = loadValue("refreshInterval", 300)

        console.log("GitHub Heatmap: Settings loaded from disk")

        if (savedUsername) {
            usernameField.text = savedUsername
            PluginService.setGlobalVar(root.pluginId, "username", savedUsername)
        }

        intervalField.text = savedInterval.toString()
        PluginService.setGlobalVar(root.pluginId, "refreshInterval", savedInterval)

        const savedNotify = loadValue("showNotifications", true)
        notifyToggle.checked = (savedNotify === true || savedNotify === "true")
        PluginService.setGlobalVar(root.pluginId, "showNotifications", notifyToggle.checked)
    }

    Column {
        width: parent.width
        spacing: Theme.spacingL



        // --- Account Section ---
        Rectangle {
            width: parent.width
            height: accountGroup.implicitHeight + Theme.spacingM * 2
            color: Theme.surfaceContainer
            radius: Theme.cornerRadius
            border.color: Theme.outline
            border.width: 1

            Column {
                id: accountGroup
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    DankIcon { name: "person"; size: 22; anchors.verticalCenter: parent.verticalCenter; opacity: 0.8 }
                    Column {
                        width: parent.width - 22 - Theme.spacingM
                        spacing: Theme.spacingXXS
                        StyledText {
                            text: "GitHub Identity"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }
                        StyledText {
                            text: "Your GitHub username used to fetch public contribution data."
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                DankTextField {
                    id: usernameField
                    width: parent.width
                    placeholderText: "e.g. josh-overton"
                    text: ""
                    onTextChanged: if (activeFocus) Qt.callLater(() => {
                        // Optional real-time feedback
                    })
                }
            }
        }

        // --- Performance Section ---
        Rectangle {
            width: parent.width
            height: perfGroup.implicitHeight + Theme.spacingM * 2
            color: Theme.surfaceContainer
            radius: Theme.cornerRadius
            border.color: Theme.outline
            border.width: 1

            Column {
                id: perfGroup
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    DankIcon { name: "schedule"; size: 22; anchors.verticalCenter: parent.verticalCenter; opacity: 0.8 }
                    Column {
                        width: parent.width - 22 - Theme.spacingM
                        spacing: Theme.spacingXXS
                        StyledText {
                            text: "Refresh Rate"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }
                        StyledText {
                            text: "Frequency of updates in seconds. Higher values save battery."
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                DankTextField {
                    id: intervalField
                    width: parent.width
                    placeholderText: "300 (5 minutes)"
                    text: "300"
                    validator: IntValidator { bottom: 60; top: 86400 }
                }
            }
        }

        // --- Notification Section ---
        Rectangle {
            width: parent.width
            height: notifyRow.implicitHeight + Theme.spacingM * 2
            color: Theme.surfaceContainer
            radius: Theme.cornerRadius
            border.color: Theme.outline
            border.width: 1
            opacity: 0.8

            RowLayout {
                id: notifyRow
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingM

                DankIcon { 
                    name: "notifications"
                    size: 22
                    opacity: 0.8
                    Layout.alignment: Qt.AlignVCenter 
                }
                
                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter
                    StyledText {
                        text: "System Alerts"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }
                    StyledText {
                        text: "Show desktop notifications for sync status."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        width: parent.width * 0.7 // Avoid overlapping toggle
                        wrapMode: Text.WordWrap
                    }
                }

                DankToggle {
                    id: notifyToggle
                    Layout.alignment: Qt.AlignVCenter
                    checked: true
                    onClicked: {
                        checked = !checked
                    }
                }
            }
        }

        // --- Save Action ---
        Item {
            id: saveBtn
            width: parent.width
            height: 44
            
            scale: saveArea.pressed ? 0.96 : (saveArea.containsMouse ? 1.02 : 1.0)
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

            MouseArea {
                id: saveArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => saveRipple.trigger(mouse.x, mouse.y)
                onClicked: {
                    const name = usernameField.text.trim()
                    if (!name) {
                        ToastService.showError("Please enter a GitHub username")
                        return
                    }

                    const interval = parseInt(intervalField.text) || 300
                    if (interval < 60) {
                        ToastService.showError("Interval must be at least 60 seconds")
                        return
                    }

                    const notify = notifyToggle.checked

                    // Persist & Notify
                    root.saveValue("username", name)
                    root.saveValue("refreshInterval", interval)
                    root.saveValue("showNotifications", notify)

                    ToastService.showSuccess("Settings updated successfully")
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.cornerRadius
                color: saveArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.4)
                border.width: 1
                border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, saveArea.containsMouse ? 0.3 : 0.15)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            Row {
                anchors.centerIn: parent
                spacing: 8
                
                DankIcon {
                    id: saveIcon
                    name: "published_with_changes"
                    size: 20
                    color: Theme.primary
                    
                    SequentialAnimation {
                        running: saveArea.containsMouse
                        loops: Animation.Infinite
                        onStopped: saveIcon.rotation = 0
                        NumberAnimation { target: saveIcon; property: "rotation"; to: -8; duration: 150; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: saveIcon; property: "rotation"; to: 8; duration: 150; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: saveIcon; property: "rotation"; to: 0; duration: 150; easing.type: Easing.InOutQuad }
                        PauseAnimation { duration: 400 }
                    }
                }
                
                StyledText {
                    text: "Save & Synchronize"
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    verticalAlignment: Text.AlignVCenter
                }
            }

            DankRipple {
                id: saveRipple
                rippleColor: Theme.surfaceText
                cornerRadius: Theme.cornerRadius
                anchors.fill: parent
            }
        }
    }
}
