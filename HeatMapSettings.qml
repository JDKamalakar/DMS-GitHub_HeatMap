import QtQuick
import QtQuick.Controls
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

    // Load persisted settings when settings UI opens
    Component.onCompleted: {
        const savedUsername = PluginService.loadPluginData("githubHeatmap", "username", "")
        const savedInterval = PluginService.loadPluginData("githubHeatmap", "refreshInterval", 300)

        console.log("GitHub Heatmap: Settings loaded from disk")

        if (savedUsername) {
            usernameField.text = savedUsername
            PluginService.setGlobalVar("githubHeatmap", "username", savedUsername)
        }

        intervalField.text = savedInterval.toString()
        PluginService.setGlobalVar("githubHeatmap", "refreshInterval", savedInterval)
    }

    Column {
        width: parent.width
        spacing: Theme.spacingL

        // Header
        Column {
            width: parent.width
            spacing: Theme.spacingXS

            StyledText {
                text: "GitHub Heatmap Settings"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            StyledText {
                text: "Visualize your GitHub contribution activity. This plugin fetches public data from your profile."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }
        }

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

        // --- Save Action ---
        DankButton {
            width: parent.width
            text: "Save & Synchronize"
            iconName: "published_with_changes"
            
            scale: pressed ? 0.98 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }

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

                // Persist
                PluginService.savePluginData("githubHeatmapRevive", "username", name)
                PluginService.savePluginData("githubHeatmapRevive", "refreshInterval", interval)

                // Notify Memory
                PluginService.setGlobalVar("githubHeatmapRevive", "username", name)
                PluginService.setGlobalVar("githubHeatmapRevive", "refreshInterval", interval)

                ToastService.showSuccess("Settings updated successfully")
            }
        }
    }
}
