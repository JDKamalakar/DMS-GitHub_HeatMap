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

    readonly property real outerR: Theme.cornerRadius || 12
    readonly property real innerR: 4

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

    PluginGlobalVar {
        id: followThemeColorSetting
        varName: "followThemeColor"
        defaultValue: true
    }

    PluginGlobalVar {
        id: displayModeSetting
        varName: "displayMode"
        defaultValue: "2 Month"
    }

    PluginGlobalVar {
        id: startDaySetting
        varName: "startDay"
        defaultValue: "Sunday"
    }

    PluginGlobalVar {
        id: hideDaysInitialsSetting
        varName: "hideDaysInitials"
        defaultValue: false
    }

    PluginGlobalVar {
        id: desktopBackgroundOpacitySetting
        varName: "desktopBackgroundOpacity"
        defaultValue: 80
    }

    PluginGlobalVar {
        id: desktopSquareSizeSetting
        varName: "desktopSquareSize"
        defaultValue: 24
    }

    PluginGlobalVar {
        id: desktopSquareSpacingSetting
        varName: "desktopSquareSpacing"
        defaultValue: 4
    }

    readonly property bool isInstanceSettings: root.pluginService && root.pluginService.savePluginState === undefined

    function loadValue(key, def) {
        if (root.pluginService && root.pluginService.loadPluginData) {
            return root.pluginService.loadPluginData(root.pluginId, key, def);
        }
        return SettingsData.getPluginSetting(root.pluginId, key, def);
    }

    function saveValue(key, val) {
        if (root.pluginService && root.pluginService.savePluginData) {
            root.pluginService.savePluginData(root.pluginId, key, val);
        } else {
            SettingsData.setPluginSetting(root.pluginId, key, val);
        }
        PluginService.setGlobalVar(root.pluginId, key, val);
        root.settingChanged()
    }

    // Baseline state to check for pending changes
    property string savedUsername: ""
    property int savedInterval: 300
    property bool savedNotify: true
    property bool savedFollowTheme: true
    property string savedDisplayMode: "2 Month"
    property string savedStartDay: "Sunday"
    property bool savedHideDays: false

    property int savedDesktopOpacity: 80
    property int savedDesktopSquareSize: 24
    property int savedDesktopSquareSpacing: 4
    property string savedDesktopDisplayMode: "2 Month"
    property string savedDesktopStartDay: "Sunday"
    property bool savedDesktopHideDays: true
    property bool savedDesktopFollowTheme: true

    readonly property bool hasPendingChanges: {
        if (root.isInstanceSettings) {
            return root.currentDesktopOpacity !== root.savedDesktopOpacity ||
                   root.currentDesktopSquareSize !== root.savedDesktopSquareSize ||
                   root.currentDesktopSquareSpacing !== root.savedDesktopSquareSpacing ||
                   (desktopDisplayModeCombo ? (desktopDisplayModeCombo.currentValue || desktopDisplayModeCombo.currentText) !== root.savedDesktopDisplayMode : false) ||
                   (desktopStartDayCombo ? (desktopStartDayCombo.currentValue || desktopStartDayCombo.currentText) !== root.savedDesktopStartDay : false) ||
                   (desktopHideDaysToggle ? desktopHideDaysToggle.checked !== root.savedDesktopHideDays : false) ||
                   (desktopFollowThemeToggle ? desktopFollowThemeToggle.checked !== root.savedDesktopFollowTheme : false)
        } else {
            return root.currentUsername.trim() !== root.savedUsername ||
                   (parseInt(root.currentInterval) || 300) !== root.savedInterval ||
                   (notifyToggle ? notifyToggle.checked !== root.savedNotify : false) ||
                   (themeColorToggle ? themeColorToggle.checked !== root.savedFollowTheme : false) ||
                   (displayModeCombo ? (displayModeCombo.currentValue || displayModeCombo.currentText) !== root.savedDisplayMode : false) ||
                   (startDayCombo ? (startDayCombo.currentValue || startDayCombo.currentText) !== root.savedStartDay : false) ||
                   (hideDaysToggle ? hideDaysToggle.checked !== root.savedHideDays : false)
        }
    }

    property string currentUsername: ""
    property string currentInterval: "300"
    property int currentDesktopOpacity: 80
    property int currentDesktopSquareSize: 24
    property int currentDesktopSquareSpacing: 4

    function refreshProperties() {
        const uName = loadValue("username", "")
        const rInterval = Number(loadValue("refreshInterval", 300)) || 300
        const dOpacity = Number(loadValue("desktopBackgroundOpacity", 80)) || 80
        const dSize = Number(loadValue("desktopSquareSize", 24)) || 24
        const dSpacing = Number(loadValue("desktopSquareSpacing", 4)) || 4

        const savedNotifyVal = loadValue("showNotifications", true)
        const savedNotifyBool = (savedNotifyVal === true || savedNotifyVal === "true")

        const savedFollowThemeVal = loadValue("followThemeColor", true)
        const savedFollowThemeBool = (savedFollowThemeVal === true || savedFollowThemeVal === "true")

        const savedDisplayModeVal = loadValue("displayMode", "2 Month")
        const savedStartDayVal = loadValue("startDay", "Sunday")

        const savedHideDaysVal = loadValue("hideDaysInitials", false)
        const savedHideDaysBool = (savedHideDaysVal === true || savedHideDaysVal === "true")

        // Desktop specific
        const savedDesktopDisplayModeVal = loadValue("displayMode", "2 Month")
        const savedDesktopStartDayVal = loadValue("startDay", "Sunday")
        
        const savedDesktopHideDaysVal = loadValue("hideDaysInitials", true)
        const savedDesktopHideDaysBool = (savedDesktopHideDaysVal === true || savedDesktopHideDaysVal === "true")

        const savedDesktopFollowThemeVal = loadValue("followThemeColor", true)
        const savedDesktopFollowThemeBool = (savedDesktopFollowThemeVal === true || savedDesktopFollowThemeVal === "true")

        // Save to baseline
        root.savedUsername = uName
        root.savedInterval = rInterval
        root.savedNotify = savedNotifyBool
        root.savedFollowTheme = savedFollowThemeBool
        root.savedDisplayMode = savedDisplayModeVal
        root.savedStartDay = savedStartDayVal
        root.savedHideDays = savedHideDaysBool

        root.savedDesktopOpacity = dOpacity
        root.savedDesktopSquareSize = dSize
        root.savedDesktopSquareSpacing = dSpacing
        root.savedDesktopDisplayMode = savedDesktopDisplayModeVal
        root.savedDesktopStartDay = savedDesktopStartDayVal
        root.savedDesktopHideDays = savedDesktopHideDaysBool
        root.savedDesktopFollowTheme = savedDesktopFollowThemeBool

        // Assign current state to match
        root.currentUsername = uName
        root.currentInterval = rInterval.toString()
        root.currentDesktopOpacity = dOpacity
        root.currentDesktopSquareSize = dSize
        root.currentDesktopSquareSpacing = dSpacing

        if (notifyToggle) notifyToggle.checked = savedNotifyBool
        if (themeColorToggle) themeColorToggle.checked = savedFollowThemeBool

        if (displayModeCombo) {
            displayModeCombo.currentValue = savedDisplayModeVal
        }

        if (startDayCombo) {
            startDayCombo.currentValue = savedStartDayVal
        }

        if (hideDaysToggle) hideDaysToggle.checked = savedHideDaysBool

        // Desktop specific combos/toggles
        if (desktopDisplayModeCombo) {
            desktopDisplayModeCombo.currentValue = savedDesktopDisplayModeVal
        }

        if (desktopStartDayCombo) {
            desktopStartDayCombo.currentValue = savedDesktopStartDayVal
        }

        if (desktopHideDaysToggle) {
            desktopHideDaysToggle.checked = savedDesktopHideDaysBool
        }

        if (desktopFollowThemeToggle) {
            desktopFollowThemeToggle.checked = savedDesktopFollowThemeBool
        }
    }

    Component.onCompleted: {
        refreshProperties()
    }

    onPluginServiceChanged: {
        refreshProperties()
    }

    Column {
        id: mainSettingsCol
        width: parent.width
        spacing: Theme.spacingL

        // ========================================================
        // 1. GLOBAL SETTINGS (Bar Widget & Plugin Preferences)
        // ========================================================
        Column {
            width: parent.width
            spacing: Theme.spacingL
            visible: !root.isInstanceSettings

            // --- Section: Account & Source ---
            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    spacing: Theme.spacingXS
                    leftPadding: Theme.spacingM
                    DankIcon {
                        name: "person"
                        size: 16
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: "Account & Source"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2

                    // Segment: GitHub Username
                    Rectangle {
                        width: parent.width
                        implicitHeight: accountContentRow.implicitHeight + Theme.spacingM * 2
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.outerR
                        topRightRadius: root.outerR
                        bottomLeftRadius: root.innerR
                        bottomRightRadius: root.innerR

                        RowLayout {
                            id: accountContentRow
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                Layout.alignment: Qt.AlignVCenter

                                DankIcon {
                                    name: "alternate_email"
                                    size: 18
                                    color: Theme.primary
                                    anchors.centerIn: parent
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                StyledText {
                                    text: "GitHub Username"
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: "Public profile used to fetch contribution calendar data"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            DankTextField {
                                id: usernameInput
                                Layout.preferredWidth: Math.min(220, parent.width * 0.4)
                                Layout.alignment: Qt.AlignVCenter
                                placeholderText: "e.g. JDKamalakar"
                                text: root.currentUsername
                                onTextChanged: {
                                    if (root.currentUsername !== text) {
                                        root.currentUsername = text
                                    }
                                }
                            }
                        }
                    }

                    // Segment: Refresh Interval
                    Rectangle {
                        width: parent.width
                        implicitHeight: refreshContentRow.implicitHeight + Theme.spacingM * 2
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.innerR
                        topRightRadius: root.innerR
                        bottomLeftRadius: root.outerR
                        bottomRightRadius: root.outerR

                        RowLayout {
                            id: refreshContentRow
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                Layout.alignment: Qt.AlignVCenter

                                DankIcon {
                                    name: "schedule"
                                    size: 18
                                    color: Theme.primary
                                    anchors.centerIn: parent
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                StyledText {
                                    text: "Refresh Rate"
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: "Update interval in seconds (minimum 60s, default 300s)"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            DankTextField {
                                id: intervalInput
                                Layout.preferredWidth: Math.min(130, parent.width * 0.3)
                                Layout.alignment: Qt.AlignVCenter
                                placeholderText: "300"
                                text: root.currentInterval
                                onTextChanged: {
                                    if (root.currentInterval !== text) {
                                        root.currentInterval = text
                                    }
                                }
                                validator: IntValidator { bottom: 60; top: 86400 }
                            }
                        }
                    }
                }
            }

            // --- Section: General Preferences ---
            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    spacing: Theme.spacingXS
                    leftPadding: Theme.spacingM
                    DankIcon {
                        name: "tune"
                        size: 16
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: "General Preferences"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2

                    // Segment 1: System Alerts / Notifications Toggle
                    Rectangle {
                        width: parent.width
                        height: 56
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.outerR
                        topRightRadius: root.outerR
                        bottomLeftRadius: root.innerR
                        bottomRightRadius: root.innerR

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: notifyToggle.checked ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surfaceContainerHighest.r, Theme.surfaceContainerHighest.g, Theme.surfaceContainerHighest.b, 0.5)
                                Layout.alignment: Qt.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 150 } }

                                DankIcon {
                                    name: "notifications"
                                    size: 18
                                    color: notifyToggle.checked ? Theme.primary : Theme.surfaceVariantText
                                    anchors.centerIn: parent
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                StyledText {
                                    text: "System Alerts"
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: "Show desktop notifications for refresh and sync status"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
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

                    // Segment 2: Follow DMS Theme Color Toggle
                    Rectangle {
                        width: parent.width
                        height: 56
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.innerR
                        topRightRadius: root.innerR
                        bottomLeftRadius: root.outerR
                        bottomRightRadius: root.outerR

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: themeColorToggle.checked ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surfaceContainerHighest.r, Theme.surfaceContainerHighest.g, Theme.surfaceContainerHighest.b, 0.5)
                                Layout.alignment: Qt.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 150 } }

                                DankIcon {
                                    name: "palette"
                                    size: 18
                                    color: themeColorToggle.checked ? Theme.primary : Theme.surfaceVariantText
                                    anchors.centerIn: parent
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                StyledText {
                                    text: "Follow DMS Theme Color"
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: "Use active DMS accent palette instead of classic GitHub green"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            DankToggle {
                                id: themeColorToggle
                                Layout.alignment: Qt.AlignVCenter
                                checked: true
                                onClicked: {
                                    checked = !checked
                                }
                            }
                        }
                    }
                }
            }

            // --- Section: Bar Heatmap Display ---
            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    spacing: Theme.spacingXS
                    leftPadding: Theme.spacingM
                    DankIcon {
                        name: "dashboard_customize"
                        size: 16
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: "Bar Heatmap Display"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2

                    // Segment 1: Display Mode Dropdown
                    Rectangle {
                        width: parent.width
                        implicitHeight: barDisplayModeRow.implicitHeight + Theme.spacingM * 2
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.outerR
                        topRightRadius: root.outerR
                        bottomLeftRadius: root.innerR
                        bottomRightRadius: root.innerR

                        RowLayout {
                            id: barDisplayModeRow
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                Layout.alignment: Qt.AlignVCenter

                                DankIcon {
                                    name: "grid_view"
                                    size: 18
                                    color: Theme.primary
                                    anchors.centerIn: parent
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                StyledText {
                                    text: "Display Mode"
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: "Range of historical contribution data shown in popup"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            DankDropdown {
                                id: displayModeCombo
                                Layout.preferredWidth: Math.min(180, parent.width * 0.4)
                                Layout.alignment: Qt.AlignVCenter
                                options: ["Week", "Month", "2 Month", "Year"]
                                currentValue: root.savedDisplayMode
                            }
                        }
                    }

                    // Segment 2: Start Day Dropdown
                    Rectangle {
                        width: parent.width
                        implicitHeight: barStartDayRow.implicitHeight + Theme.spacingM * 2
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.innerR
                        topRightRadius: root.innerR
                        bottomLeftRadius: root.innerR
                        bottomRightRadius: root.innerR

                        RowLayout {
                            id: barStartDayRow
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                Layout.alignment: Qt.AlignVCenter

                                DankIcon {
                                    name: "calendar_today"
                                    size: 18
                                    color: Theme.primary
                                    anchors.centerIn: parent
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                StyledText {
                                    text: "Start Day"
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: "First weekday of each week column in the calendar"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            DankDropdown {
                                id: startDayCombo
                                Layout.preferredWidth: Math.min(180, parent.width * 0.4)
                                Layout.alignment: Qt.AlignVCenter
                                options: ["Sunday", "Monday"]
                                currentValue: root.savedStartDay
                            }
                        }
                    }

                    // Segment 3: Hide Days Initials Toggle
                    Rectangle {
                        width: parent.width
                        height: 56
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.innerR
                        topRightRadius: root.innerR
                        bottomLeftRadius: root.outerR
                        bottomRightRadius: root.outerR

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: hideDaysToggle.checked ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surfaceContainerHighest.r, Theme.surfaceContainerHighest.g, Theme.surfaceContainerHighest.b, 0.5)
                                Layout.alignment: Qt.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 150 } }

                                DankIcon {
                                    name: "visibility_off"
                                    size: 18
                                    color: hideDaysToggle.checked ? Theme.primary : Theme.surfaceVariantText
                                    anchors.centerIn: parent
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                StyledText {
                                    text: "Hide Days Initials"
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: "Hide weekday column labels (S, M, T...) from the heatmap"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            DankToggle {
                                id: hideDaysToggle
                                Layout.alignment: Qt.AlignVCenter
                                checked: false
                                onClicked: {
                                    checked = !checked
                                }
                            }
                        }
                    }
                }
            }
        }

        // ========================================================
        // 2. DESKTOP WIDGET SETTINGS (Instance Settings)
        // ========================================================
        Column {
            width: parent.width
            spacing: Theme.spacingL
            visible: root.isInstanceSettings

            // --- Section: Geometry & Appearance ---
            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    spacing: Theme.spacingXS
                    leftPadding: Theme.spacingM
                    DankIcon {
                        name: "desktop_windows"
                        size: 16
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: "Geometry & Layout"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2

                    // Segment 1: Background Opacity Slider
                    Rectangle {
                        width: parent.width
                        implicitHeight: opacityCol.implicitHeight + Theme.spacingM * 2
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.outerR
                        topRightRadius: root.outerR
                        bottomLeftRadius: root.innerR
                        bottomRightRadius: root.innerR

                        Column {
                            id: opacityCol
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingXS

                            RowLayout {
                                width: parent.width
                                spacing: Theme.spacingM

                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                    Layout.alignment: Qt.AlignVCenter

                                    DankIcon {
                                        name: "opacity"
                                        size: 16
                                        color: Theme.primary
                                        anchors.centerIn: parent
                                    }
                                }

                                StyledText {
                                    text: "Background Opacity"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    id: opacityResetBtn
                                    width: 24; height: 24
                                    radius: 6
                                    Layout.alignment: Qt.AlignVCenter
                                    color: opacityResetMa.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                                    border.color: opacityResetMa.containsMouse ? Theme.primary : Theme.outline
                                    border.width: 1
                                    opacity: root.currentDesktopOpacity !== 80 ? (opacityResetMa.containsMouse ? 1.0 : 0.9) : 0.0
                                    visible: opacity > 0
                                    scale: opacityResetMa.containsMouse ? 1.1 : 1.0

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                    DankRipple {
                                        id: opacityRip
                                        anchors.fill: parent
                                        cornerRadius: parent.radius
                                        rippleColor: Theme.primary
                                    }

                                    DankIcon {
                                        name: "restart_alt"
                                        size: 14
                                        anchors.centerIn: parent
                                        color: opacityResetMa.containsMouse ? Theme.primary : Theme.surfaceVariantText
                                        rotation: opacityResetMa.containsMouse ? 90 : 0
                                        Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    ParallelAnimation {
                                        id: opacityResetAnim
                                        NumberAnimation {
                                            target: root
                                            property: "currentDesktopOpacity"
                                            to: 80
                                            duration: 350
                                            easing.type: Easing.OutCubic
                                        }
                                        NumberAnimation {
                                            target: desktopOpacitySlider
                                            property: "value"
                                            to: 80
                                            duration: 350
                                            easing.type: Easing.OutCubic
                                        }
                                        onStopped: {
                                            desktopOpacitySlider.value = Qt.binding(function() { return root.currentDesktopOpacity })
                                        }
                                    }

                                    MouseArea {
                                        id: opacityResetMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: opacityResetAnim.start()
                                        onPressed: (m) => opacityRip.trigger(m.x, m.y)
                                    }
                                }
                            }

                            DankSlider {
                                id: desktopOpacitySlider
                                width: parent.width
                                minimum: 0
                                maximum: 100
                                value: root.currentDesktopOpacity
                                leftIcon: "opacity"
                                unit: "%"
                                wheelEnabled: false
                                onSliderValueChanged: val => {
                                    root.currentDesktopOpacity = val
                                }
                            }
                        }
                    }

                    // Segment 2: Square Size Slider
                    Rectangle {
                        width: parent.width
                        implicitHeight: sizeCol.implicitHeight + Theme.spacingM * 2
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.innerR
                        topRightRadius: root.innerR
                        bottomLeftRadius: root.innerR
                        bottomRightRadius: root.innerR

                        Column {
                            id: sizeCol
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingXS

                            RowLayout {
                                width: parent.width
                                spacing: Theme.spacingM

                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                    Layout.alignment: Qt.AlignVCenter

                                    DankIcon {
                                        name: "grid_on"
                                        size: 16
                                        color: Theme.primary
                                        anchors.centerIn: parent
                                    }
                                }

                                StyledText {
                                    text: "Square Size"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    id: sizeResetBtn
                                    width: 24; height: 24
                                    radius: 6
                                    Layout.alignment: Qt.AlignVCenter
                                    color: sizeResetMa.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                                    border.color: sizeResetMa.containsMouse ? Theme.primary : Theme.outline
                                    border.width: 1
                                    opacity: root.currentDesktopSquareSize !== 24 ? (sizeResetMa.containsMouse ? 1.0 : 0.9) : 0.0
                                    visible: opacity > 0
                                    scale: sizeResetMa.containsMouse ? 1.1 : 1.0

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                    DankRipple {
                                        id: sizeRip
                                        anchors.fill: parent
                                        cornerRadius: parent.radius
                                        rippleColor: Theme.primary
                                    }

                                    DankIcon {
                                        name: "restart_alt"
                                        size: 14
                                        anchors.centerIn: parent
                                        color: sizeResetMa.containsMouse ? Theme.primary : Theme.surfaceVariantText
                                        rotation: sizeResetMa.containsMouse ? 90 : 0
                                        Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    ParallelAnimation {
                                        id: sizeResetAnim
                                        NumberAnimation {
                                            target: root
                                            property: "currentDesktopSquareSize"
                                            to: 24
                                            duration: 350
                                            easing.type: Easing.OutCubic
                                        }
                                        NumberAnimation {
                                            target: desktopSquareSizeSlider
                                            property: "value"
                                            to: 24
                                            duration: 350
                                            easing.type: Easing.OutCubic
                                        }
                                        onStopped: {
                                            desktopSquareSizeSlider.value = Qt.binding(function() { return root.currentDesktopSquareSize })
                                        }
                                    }

                                    MouseArea {
                                        id: sizeResetMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: sizeResetAnim.start()
                                        onPressed: (m) => sizeRip.trigger(m.x, m.y)
                                    }
                                }
                            }

                            DankSlider {
                                id: desktopSquareSizeSlider
                                width: parent.width
                                minimum: 6
                                maximum: 32
                                value: root.currentDesktopSquareSize
                                leftIcon: "grid_on"
                                unit: "px"
                                wheelEnabled: false
                                onSliderValueChanged: val => {
                                    root.currentDesktopSquareSize = val
                                }
                            }
                        }
                    }

                    // Segment 3: Square Spacing Slider
                    Rectangle {
                        width: parent.width
                        implicitHeight: spacingCol.implicitHeight + Theme.spacingM * 2
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.innerR
                        topRightRadius: root.innerR
                        bottomLeftRadius: root.outerR
                        bottomRightRadius: root.outerR

                        Column {
                            id: spacingCol
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingXS

                            RowLayout {
                                width: parent.width
                                spacing: Theme.spacingM

                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                    Layout.alignment: Qt.AlignVCenter

                                    DankIcon {
                                        name: "space_bar"
                                        size: 16
                                        color: Theme.primary
                                        anchors.centerIn: parent
                                    }
                                }

                                StyledText {
                                    text: "Square Spacing"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    id: spacingResetBtn
                                    width: 24; height: 24
                                    radius: 6
                                    Layout.alignment: Qt.AlignVCenter
                                    color: spacingResetMa.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                                    border.color: spacingResetMa.containsMouse ? Theme.primary : Theme.outline
                                    border.width: 1
                                    opacity: root.currentDesktopSquareSpacing !== 4 ? (spacingResetMa.containsMouse ? 1.0 : 0.9) : 0.0
                                    visible: opacity > 0
                                    scale: spacingResetMa.containsMouse ? 1.1 : 1.0

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                    DankRipple {
                                        id: spacingRip
                                        anchors.fill: parent
                                        cornerRadius: parent.radius
                                        rippleColor: Theme.primary
                                    }

                                    DankIcon {
                                        name: "restart_alt"
                                        size: 14
                                        anchors.centerIn: parent
                                        color: spacingResetMa.containsMouse ? Theme.primary : Theme.surfaceVariantText
                                        rotation: spacingResetMa.containsMouse ? 90 : 0
                                        Behavior on rotation { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    ParallelAnimation {
                                        id: spacingResetAnim
                                        NumberAnimation {
                                            target: root
                                            property: "currentDesktopSquareSpacing"
                                            to: 4
                                            duration: 350
                                            easing.type: Easing.OutCubic
                                        }
                                        NumberAnimation {
                                            target: desktopSquareSpacingSlider
                                            property: "value"
                                            to: 4
                                            duration: 350
                                            easing.type: Easing.OutCubic
                                        }
                                        onStopped: {
                                            desktopSquareSpacingSlider.value = Qt.binding(function() { return root.currentDesktopSquareSpacing })
                                        }
                                    }

                                    MouseArea {
                                        id: spacingResetMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: spacingResetAnim.start()
                                        onPressed: (m) => spacingRip.trigger(m.x, m.y)
                                    }
                                }
                            }

                            DankSlider {
                                id: desktopSquareSpacingSlider
                                width: parent.width
                                minimum: 1
                                maximum: 8
                                value: root.currentDesktopSquareSpacing
                                leftIcon: "space_bar"
                                unit: "px"
                                wheelEnabled: false
                                onSliderValueChanged: val => {
                                    root.currentDesktopSquareSpacing = val
                                }
                            }
                        }
                    }
                }
            }

            // --- Section: Desktop Card Display ---
            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    spacing: Theme.spacingXS
                    leftPadding: Theme.spacingM
                    DankIcon {
                        name: "view_compact"
                        size: 16
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: "Desktop Display Mode"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2

                    // Segment 1: Display Mode Dropdown
                    Rectangle {
                        width: parent.width
                        implicitHeight: desktopDisplayModeRow.implicitHeight + Theme.spacingM * 2
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.outerR
                        topRightRadius: root.outerR
                        bottomLeftRadius: root.innerR
                        bottomRightRadius: root.innerR

                        RowLayout {
                            id: desktopDisplayModeRow
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                Layout.alignment: Qt.AlignVCenter

                                DankIcon {
                                    name: "grid_view"
                                    size: 18
                                    color: Theme.primary
                                    anchors.centerIn: parent
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                StyledText {
                                    text: "Display Mode"
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: "Amount of contribution history displayed on desktop"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            DankDropdown {
                                id: desktopDisplayModeCombo
                                Layout.preferredWidth: Math.min(180, parent.width * 0.4)
                                Layout.alignment: Qt.AlignVCenter
                                options: ["Week", "Month", "2 Month", "Year"]
                                currentValue: root.savedDesktopDisplayMode
                            }
                        }
                    }

                    // Segment 2: Start Day Dropdown
                    Rectangle {
                        width: parent.width
                        implicitHeight: desktopStartDayRow.implicitHeight + Theme.spacingM * 2
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.innerR
                        topRightRadius: root.innerR
                        bottomLeftRadius: root.innerR
                        bottomRightRadius: root.innerR

                        RowLayout {
                            id: desktopStartDayRow
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                Layout.alignment: Qt.AlignVCenter

                                DankIcon {
                                    name: "calendar_today"
                                    size: 18
                                    color: Theme.primary
                                    anchors.centerIn: parent
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                StyledText {
                                    text: "Start Day"
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: "First weekday of each week column on the desktop card"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            DankDropdown {
                                id: desktopStartDayCombo
                                Layout.preferredWidth: Math.min(180, parent.width * 0.4)
                                Layout.alignment: Qt.AlignVCenter
                                options: ["Sunday", "Monday"]
                                currentValue: root.savedDesktopStartDay
                            }
                        }
                    }

                    // Segment 3: Hide Days Initials Toggle
                    Rectangle {
                        width: parent.width
                        height: 56
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.innerR
                        topRightRadius: root.innerR
                        bottomLeftRadius: root.innerR
                        bottomRightRadius: root.innerR

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: desktopHideDaysToggle.checked ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surfaceContainerHighest.r, Theme.surfaceContainerHighest.g, Theme.surfaceContainerHighest.b, 0.5)
                                Layout.alignment: Qt.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 150 } }

                                DankIcon {
                                    name: "visibility_off"
                                    size: 18
                                    color: desktopHideDaysToggle.checked ? Theme.primary : Theme.surfaceVariantText
                                    anchors.centerIn: parent
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                StyledText {
                                    text: "Hide Days Initials"
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: "Hide weekday column labels from the desktop heatmap"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            DankToggle {
                                id: desktopHideDaysToggle
                                Layout.alignment: Qt.AlignVCenter
                                checked: false
                                onClicked: {
                                    checked = !checked
                                }
                            }
                        }
                    }

                    // Segment 4: Follow DMS Theme Color (Desktop)
                    Rectangle {
                        width: parent.width
                        height: 56
                        color: Theme.withAlpha(Theme.surfaceContainerHigh, 0.5)
                        border.width: 1
                        border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.10)

                        topLeftRadius: root.innerR
                        topRightRadius: root.innerR
                        bottomLeftRadius: root.outerR
                        bottomRightRadius: root.outerR

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingM
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: desktopFollowThemeToggle.checked ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(Theme.surfaceContainerHighest.r, Theme.surfaceContainerHighest.g, Theme.surfaceContainerHighest.b, 0.5)
                                Layout.alignment: Qt.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 150 } }

                                DankIcon {
                                    name: "palette"
                                    size: 18
                                    color: desktopFollowThemeToggle.checked ? Theme.primary : Theme.surfaceVariantText
                                    anchors.centerIn: parent
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                StyledText {
                                    text: "Follow DMS Theme Color"
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: "Use active DMS accent color instead of classic GitHub green"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            DankToggle {
                                id: desktopFollowThemeToggle
                                Layout.alignment: Qt.AlignVCenter
                                checked: true
                                onClicked: {
                                    checked = !checked
                                }
                            }
                        }
                    }
                }
            }
        }

        // ========================================================
        // 3. ACTION BUTTONS (Save & Apply)
        // ========================================================
        RowLayout {
            width: parent.width
            spacing: Theme.spacingM
            height: 44

            Item {
                id: saveBtn
                Layout.fillWidth: true
                Layout.preferredWidth: 1
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
                        if (root.isInstanceSettings) {
                            root.saveValue("desktopBackgroundOpacity", root.currentDesktopOpacity)
                            root.saveValue("desktopSquareSize", root.currentDesktopSquareSize)
                            root.saveValue("desktopSquareSpacing", root.currentDesktopSquareSpacing)
                            const displayMode = desktopDisplayModeCombo.currentValue || desktopDisplayModeCombo.currentText
                            const startDay = desktopStartDayCombo.currentValue || desktopStartDayCombo.currentText
                            root.saveValue("displayMode", displayMode)
                            root.saveValue("startDay", startDay)
                            root.saveValue("hideDaysInitials", desktopHideDaysToggle.checked)
                            root.saveValue("followThemeColor", desktopFollowThemeToggle.checked)

                            // Synchronously update baseline properties
                            root.savedDesktopOpacity = root.currentDesktopOpacity
                            root.savedDesktopSquareSize = root.currentDesktopSquareSize
                            root.savedDesktopSquareSpacing = root.currentDesktopSquareSpacing
                            root.savedDesktopDisplayMode = displayMode
                            root.savedDesktopStartDay = startDay
                            root.savedDesktopHideDays = desktopHideDaysToggle.checked
                            root.savedDesktopFollowTheme = desktopFollowThemeToggle.checked
                        } else {
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
                            const followTheme = themeColorToggle.checked
                            const displayMode = displayModeCombo.currentValue || displayModeCombo.currentText
                            const startDay = startDayCombo.currentValue || startDayCombo.currentText
                            const hideDays = hideDaysToggle.checked

                            // Persist & Notify
                            root.saveValue("username", name)
                            root.saveValue("refreshInterval", interval)
                            root.saveValue("showNotifications", notify)
                            root.saveValue("followThemeColor", followTheme)
                            root.saveValue("displayMode", displayMode)
                            root.saveValue("startDay", startDay)
                            root.saveValue("hideDaysInitials", hideDays)

                            // Synchronously update baseline properties
                            root.savedUsername = name
                            root.savedInterval = interval
                            root.savedNotify = notify
                            root.savedFollowTheme = followTheme
                            root.savedDisplayMode = displayMode
                            root.savedStartDay = startDay
                            root.savedHideDays = hideDays
                        }

                        ToastService.showSuccess("Settings saved successfully")
                        root.refreshProperties()
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: root.outerR
                    color: root.hasPendingChanges
                        ? (saveArea.pressed ? Theme.withAlpha(Theme.primary, 0.80) : (saveArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.90) : Theme.primary))
                        : (saveArea.pressed ? Theme.withAlpha(Theme.primary, 0.18) : (saveArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.10) : Theme.withAlpha(Theme.secondary, 0.04)))
                    border.width: 1
                    border.color: root.hasPendingChanges
                        ? Theme.primary
                        : (saveArea.pressed ? Theme.withAlpha(Theme.primary, 0.60) : (saveArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.40) : Theme.withAlpha(Theme.secondary, 0.15)))
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
                        color: root.hasPendingChanges ? Theme.primaryText : Theme.primary
                        
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
                        text: "Save & Apply"
                        color: root.hasPendingChanges ? Theme.primaryText : Theme.primary
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                DankRipple {
                    id: saveRipple
                    rippleColor: root.hasPendingChanges ? Theme.withAlpha(Theme.primaryText, 0.3) : Theme.surfaceText
                    cornerRadius: root.outerR
                    anchors.fill: parent
                }
            }
        }
    }
}
