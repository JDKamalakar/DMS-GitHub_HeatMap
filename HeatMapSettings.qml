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

    property string currentUsername: loadValue("username", "")
    property string currentInterval: loadValue("refreshInterval", 300).toString()

    // Load persisted settings when settings UI opens
    Component.onCompleted: {
        const savedUsername = loadValue("username", "")
        const savedInterval = loadValue("refreshInterval", 300)

        console.log("GitHub Heatmap: Settings loaded from disk")

        if (savedUsername) {
            PluginService.setGlobalVar(root.pluginId, "username", savedUsername)
        }

        PluginService.setGlobalVar(root.pluginId, "refreshInterval", savedInterval)

        const savedNotify = loadValue("showNotifications", true)
        notifyToggle.checked = (savedNotify === true || savedNotify === "true")
        PluginService.setGlobalVar(root.pluginId, "showNotifications", notifyToggle.checked)
    }

    Component {
        id: settingsCardTemplate
        Rectangle {
            width: parent ? parent.width : 0
            height: Math.max(0, contentCol.implicitHeight + Theme.spacingM * 2)
            color: Theme.surfaceContainer
            radius: Theme.cornerRadius
            border.color: Theme.outline
            border.width: 1

            property string iconName
            property string titleText
            property string subtitleText
            property Component controlContent

            Column {
                id: contentCol
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingM

                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    DankIcon { id: cardIcon; name: iconName; size: 22; anchors.verticalCenter: parent.verticalCenter; opacity: 0.8 }
                    Column {
                        width: Math.max(0, parent.width - cardIcon.width - Theme.spacingM)
                        spacing: Theme.spacingXXS
                        StyledText {
                            text: titleText
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }
                        StyledText {
                            text: subtitleText
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Loader {
                    id: cardContent
                    width: parent.width
                    sourceComponent: controlContent
                    asynchronous: true
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingL

        // --- Account Section ---
        Loader {
            width: parent.width
            asynchronous: true
            sourceComponent: settingsCardTemplate
            onLoaded: {
                item.iconName = "person"
                item.titleText = "GitHub Identity"
                item.subtitleText = "Your GitHub username used to fetch public contribution data."
                item.controlContent = accountControlComponent
            }
        }

        Component {
            id: accountControlComponent
            DankTextField {
                width: parent ? parent.width : 0
                placeholderText: "e.g. josh-overton"
                text: root.currentUsername
                onTextChanged: {
                    if (activeFocus) root.currentUsername = text
                }
            }
        }

        // --- Performance Section ---
        Loader {
            width: parent.width
            asynchronous: true
            sourceComponent: settingsCardTemplate
            onLoaded: {
                item.iconName = "schedule"
                item.titleText = "Refresh Rate"
                item.subtitleText = "Frequency of updates in seconds. Higher values save battery."
                item.controlContent = perfControlComponent
            }
        }

        Component {
            id: perfControlComponent
            DankTextField {
                width: parent ? parent.width : 0
                placeholderText: "300 (5 minutes)"
                text: root.currentInterval
                onTextChanged: {
                    if (activeFocus) root.currentInterval = text
                }
                validator: IntValidator { bottom: 60; top: 86400 }
            }
        }

        // --- Notification Section ---
        Rectangle {
            width: parent.width
            height: Math.max(0, notifyRow.implicitHeight + Theme.spacingM * 2)
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
                    spacing: Theme.spacingXXS
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
                        width: parent.width
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
                    const name = root.currentUsername.trim()
                    if (!name) {
                        ToastService.showError("Please enter a GitHub username")
                        return
                    }

                    const interval = parseInt(root.currentInterval) || 300
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
                color: saveArea.pressed ? Theme.withAlpha(Theme.primary, 0.18) : (saveArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.10) : Theme.withAlpha(Theme.secondary, 0.04))
                border.width: 1
                border.color: saveArea.pressed ? Theme.withAlpha(Theme.primary, 0.60) : (saveArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.40) : Theme.withAlpha(Theme.secondary, 0.15))
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            Row {
                anchors.centerIn: parent
                spacing: Theme.spacingS
                
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
