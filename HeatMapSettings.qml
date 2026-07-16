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
                   (desktopDisplayModeCombo ? desktopDisplayModeCombo.currentText !== root.savedDesktopDisplayMode : false) ||
                   (desktopStartDayCombo ? desktopStartDayCombo.currentText !== root.savedDesktopStartDay : false) ||
                   (desktopHideDaysToggle ? desktopHideDaysToggle.checked !== root.savedDesktopHideDays : false) ||
                   (desktopFollowThemeToggle ? desktopFollowThemeToggle.checked !== root.savedDesktopFollowTheme : false)
        } else {
            return root.currentUsername.trim() !== root.savedUsername ||
                   (parseInt(root.currentInterval) || 300) !== root.savedInterval ||
                   (notifyToggle ? notifyToggle.checked !== root.savedNotify : false) ||
                   (themeColorToggle ? themeColorToggle.checked !== root.savedFollowTheme : false) ||
                   (displayModeCombo ? displayModeCombo.currentText !== root.savedDisplayMode : false) ||
                   (startDayCombo ? startDayCombo.currentText !== root.savedStartDay : false) ||
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
            if (savedDisplayModeVal === "Month") {
                displayModeCombo.currentIndex = 1
            } else if (savedDisplayModeVal === "2 Month") {
                displayModeCombo.currentIndex = 2
            } else if (savedDisplayModeVal === "Year") {
                displayModeCombo.currentIndex = 3
            } else {
                displayModeCombo.currentIndex = 0
            }
        }

        if (startDayCombo) {
            if (savedStartDayVal === "Monday") {
                startDayCombo.currentIndex = 1
            } else {
                startDayCombo.currentIndex = 0
            }
        }

        if (hideDaysToggle) hideDaysToggle.checked = savedHideDaysBool

        // Desktop specific combos/toggles
        if (desktopDisplayModeCombo) {
            if (savedDesktopDisplayModeVal === "Month") {
                desktopDisplayModeCombo.currentIndex = 1
            } else if (savedDesktopDisplayModeVal === "2 Month") {
                desktopDisplayModeCombo.currentIndex = 2
            } else if (savedDesktopDisplayModeVal === "Year") {
                desktopDisplayModeCombo.currentIndex = 3
            } else {
                desktopDisplayModeCombo.currentIndex = 0
            }
        }

        if (desktopStartDayCombo) {
            if (savedDesktopStartDayVal === "Monday") {
                desktopStartDayCombo.currentIndex = 1
            } else {
                desktopStartDayCombo.currentIndex = 0
            }
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

        // --- Global Settings Section (Plugin Settings) ---
        Column {
            width: parent.width
            spacing: Theme.spacingL
            visible: !root.isInstanceSettings

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
                        if (root.currentUsername !== text) {
                            root.currentUsername = text
                        }
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
                        if (root.currentInterval !== text) {
                            root.currentInterval = text
                        }
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

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXXS
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
                            Layout.fillWidth: true
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

            // --- Appearance Section ---
            Rectangle {
                width: parent.width
                height: Math.max(0, themeRow.implicitHeight + Theme.spacingM * 2)
                color: Theme.surfaceContainer
                radius: Theme.cornerRadius
                border.color: Theme.outline
                border.width: 1
                opacity: 0.8

                RowLayout {
                    id: themeRow
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    DankIcon {
                        name: "palette"
                        size: 22
                        opacity: 0.8
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingXXS
                        StyledText {
                            text: "Follow DMS Theme Color"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }
                        StyledText {
                            text: "Use your DMS accent color for the heatmap instead of the classic GitHub green."
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
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

            // --- Display Configuration ---
            Rectangle {
                width: parent.width
                height: Math.max(0, displayModeCol.implicitHeight + Theme.spacingM * 2)
                color: Theme.surfaceContainer
                radius: Theme.cornerRadius
                border.color: Theme.outline
                border.width: 1
                opacity: 0.8

                ColumnLayout {
                    id: displayModeCol
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    // Display Mode Dropdown
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "grid_view"
                            size: 22
                            opacity: 0.8
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXXS
                            StyledText {
                                text: "Display Mode"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }
                            StyledText {
                                text: "Configure how much historical contribution data to show."
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    ComboBox {
                        id: displayModeCombo
                        Layout.fillWidth: true
                        model: ["Week", "Month", "2 Month", "Year"]

                        delegate: ItemDelegate {
                            width: displayModeCombo.width
                            contentItem: StyledText {
                                text: modelData
                                color: highlighted ? Theme.primary : Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: highlighted ? Theme.withAlpha(Theme.primary, 0.1) : "transparent"
                            }
                        }

                        contentItem: StyledText {
                            leftPadding: Theme.spacingS
                            rightPadding: displayModeCombo.indicator.width + displayModeCombo.spacing
                            text: displayModeCombo.displayText
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            implicitWidth: 120
                            implicitHeight: 40
                            border.color: displayModeCombo.pressed ? Theme.primary : Theme.withAlpha(Theme.outline, 0.5)
                            border.width: displayModeCombo.visualFocus ? 2 : 1
                            color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                            radius: Theme.cornerRadius
                        }

                        popup: Popup {
                            y: displayModeCombo.height + 2
                            width: displayModeCombo.width
                            implicitHeight: contentItem.implicitHeight
                            padding: 1

                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: displayModeCombo.popup.visible ? displayModeCombo.delegateModel : null
                                currentIndex: displayModeCombo.highlightedIndex

                                ScrollIndicator.vertical: ScrollIndicator { }
                            }

                            background: Rectangle {
                                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                                border.color: Theme.withAlpha(Theme.outline, 0.5)
                                border.width: 1
                                radius: Theme.cornerRadius
                            }
                        }
                    }

                    // Start Day Dropdown
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingM
                        Layout.topMargin: Theme.spacingS

                        DankIcon {
                            name: "calendar_today"
                            size: 22
                            opacity: 0.8
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXXS
                            StyledText {
                                text: "Start Day"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }
                            StyledText {
                                text: "Select the starting weekday of the contribution week grid."
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    ComboBox {
                        id: startDayCombo
                        Layout.fillWidth: true
                        model: ["Sunday", "Monday"]

                        delegate: ItemDelegate {
                            width: startDayCombo.width
                            contentItem: StyledText {
                                text: modelData
                                color: highlighted ? Theme.primary : Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: highlighted ? Theme.withAlpha(Theme.primary, 0.1) : "transparent"
                            }
                        }

                        contentItem: StyledText {
                            leftPadding: Theme.spacingS
                            rightPadding: startDayCombo.indicator.width + startDayCombo.spacing
                            text: startDayCombo.displayText
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            implicitWidth: 120
                            implicitHeight: 40
                            border.color: startDayCombo.pressed ? Theme.primary : Theme.withAlpha(Theme.outline, 0.5)
                            border.width: startDayCombo.visualFocus ? 2 : 1
                            color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                            radius: Theme.cornerRadius
                        }

                        popup: Popup {
                            y: startDayCombo.height + 2
                            width: startDayCombo.width
                            implicitHeight: contentItem.implicitHeight
                            padding: 1

                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: startDayCombo.popup.visible ? startDayCombo.delegateModel : null
                                currentIndex: startDayCombo.highlightedIndex

                                ScrollIndicator.vertical: ScrollIndicator { }
                            }

                            background: Rectangle {
                                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                                border.color: Theme.withAlpha(Theme.outline, 0.5)
                                border.width: 1
                                radius: Theme.cornerRadius
                            }
                        }
                    }

                    // Hide Days Initials Toggle
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingM
                        Layout.topMargin: Theme.spacingS

                        DankIcon {
                            name: "visibility_off"
                            size: 22
                            opacity: 0.8
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXXS
                            StyledText {
                                text: "Hide Days Initials"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }
                            StyledText {
                                text: "Hide the day labels (S, M, T...) from the heatmap."
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
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

        // --- Desktop Settings Section (Instance Settings) ---
        Column {
            width: parent.width
            spacing: Theme.spacingL
            visible: root.isInstanceSettings

            StyledText {
                width: parent.width
                text: "Desktop Widget"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Bold
                color: Theme.surfaceText
            }

            StyledText {
                width: parent.width
                text: "Only affects the resizable card placed on your desktop."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
            }

            Rectangle {
                width: parent.width
                height: Math.max(0, desktopCol.implicitHeight + Theme.spacingM * 2)
                color: Theme.surfaceContainer
                radius: Theme.cornerRadius
                border.color: Theme.outline
                border.width: 1
                opacity: 0.8

                Column {
                    id: desktopCol
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS

                        RowLayout {
                            width: parent.width
                            spacing: Theme.spacingM

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

                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS

                        RowLayout {
                            width: parent.width
                            spacing: Theme.spacingM

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

                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS

                        RowLayout {
                            width: parent.width
                            spacing: Theme.spacingM

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

                    // Display Mode Dropdown
                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Display Mode"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        RowLayout {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankIcon {
                                name: "grid_view"
                                size: 22
                                opacity: 0.8
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ComboBox {
                                id: desktopDisplayModeCombo
                                Layout.fillWidth: true
                                model: ["Week", "Month", "2 Month", "Year"]

                                delegate: ItemDelegate {
                                    width: desktopDisplayModeCombo.width
                                    contentItem: StyledText {
                                        text: modelData
                                        color: highlighted ? Theme.primary : Theme.surfaceText
                                        font.pixelSize: Theme.fontSizeMedium
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        color: highlighted ? Theme.withAlpha(Theme.primary, 0.1) : "transparent"
                                    }
                                }

                                contentItem: StyledText {
                                    leftPadding: Theme.spacingS
                                    rightPadding: desktopDisplayModeCombo.indicator.width + desktopDisplayModeCombo.spacing
                                    text: desktopDisplayModeCombo.displayText
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    implicitWidth: 120
                                    implicitHeight: 40
                                    border.color: desktopDisplayModeCombo.pressed ? Theme.primary : Theme.withAlpha(Theme.outline, 0.5)
                                    border.width: desktopDisplayModeCombo.visualFocus ? 2 : 1
                                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                                    radius: Theme.cornerRadius
                                }

                                popup: Popup {
                                    y: desktopDisplayModeCombo.height + 2
                                    width: desktopDisplayModeCombo.width
                                    implicitHeight: contentItem.implicitHeight
                                    padding: 1

                                    contentItem: ListView {
                                        clip: true
                                        implicitHeight: contentHeight
                                        model: desktopDisplayModeCombo.popup.visible ? desktopDisplayModeCombo.delegateModel : null
                                        currentIndex: desktopDisplayModeCombo.highlightedIndex

                                        ScrollIndicator.vertical: ScrollIndicator { }
                                    }

                                    background: Rectangle {
                                        color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                                        border.color: Theme.withAlpha(Theme.outline, 0.5)
                                        border.width: 1
                                        radius: Theme.cornerRadius
                                    }
                                }
                            }
                        }
                    }

                    // Start Day Dropdown
                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Start Day"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        RowLayout {
                            width: parent.width
                            spacing: Theme.spacingM

                            DankIcon {
                                name: "calendar_today"
                                size: 22
                                opacity: 0.8
                                Layout.alignment: Qt.AlignVCenter
                            }

                            ComboBox {
                                id: desktopStartDayCombo
                                Layout.fillWidth: true
                                model: ["Sunday", "Monday"]

                                delegate: ItemDelegate {
                                    width: desktopStartDayCombo.width
                                    contentItem: StyledText {
                                        text: modelData
                                        color: highlighted ? Theme.primary : Theme.surfaceText
                                        font.pixelSize: Theme.fontSizeMedium
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        color: highlighted ? Theme.withAlpha(Theme.primary, 0.1) : "transparent"
                                    }
                                }

                                contentItem: StyledText {
                                    leftPadding: Theme.spacingS
                                    rightPadding: desktopStartDayCombo.indicator.width + desktopStartDayCombo.spacing
                                    text: desktopStartDayCombo.displayText
                                    color: Theme.surfaceText
                                    font.pixelSize: Theme.fontSizeMedium
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    implicitWidth: 120
                                    implicitHeight: 40
                                    border.color: desktopStartDayCombo.pressed ? Theme.primary : Theme.withAlpha(Theme.outline, 0.5)
                                    border.width: desktopStartDayCombo.visualFocus ? 2 : 1
                                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                                    radius: Theme.cornerRadius
                                }

                                popup: Popup {
                                    y: desktopStartDayCombo.height + 2
                                    width: desktopStartDayCombo.width
                                    implicitHeight: contentItem.implicitHeight
                                    padding: 1

                                    contentItem: ListView {
                                        clip: true
                                        implicitHeight: contentHeight
                                        model: desktopStartDayCombo.popup.visible ? desktopStartDayCombo.delegateModel : null
                                        currentIndex: desktopStartDayCombo.highlightedIndex

                                        ScrollIndicator.vertical: ScrollIndicator { }
                                    }

                                    background: Rectangle {
                                        color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                                        border.color: Theme.withAlpha(Theme.outline, 0.5)
                                        border.width: 1
                                        radius: Theme.cornerRadius
                                    }
                                }
                            }
                        }
                    }

                    // Hide Days Initials Toggle
                    RowLayout {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "visibility_off"
                            size: 22
                            opacity: 0.8
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXXS
                            StyledText {
                                text: "Hide Days Initials"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }
                            StyledText {
                                text: "Hide the day labels (S, M, T...) from the desktop heatmap."
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
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

                    // Follow DMS Theme Color Toggle (Desktop Specific)
                    RowLayout {
                        width: parent.width
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "palette"
                            size: 22
                            opacity: 0.8
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingXXS
                            StyledText {
                                text: "Follow DMS Theme Color"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }
                            StyledText {
                                text: "Use your DMS accent color for the desktop heatmap instead of the classic GitHub green."
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
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

        // --- Action Buttons (Save & Reset) ---
        RowLayout {
            width: parent.width
            spacing: Theme.spacingM
            height: 44

            // --- Save Button ---
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
                            root.saveValue("displayMode", desktopDisplayModeCombo.currentText)
                            root.saveValue("startDay", desktopStartDayCombo.currentText)
                            root.saveValue("hideDaysInitials", desktopHideDaysToggle.checked)
                            root.saveValue("followThemeColor", desktopFollowThemeToggle.checked)

                            // Synchronously update baseline properties
                            root.savedDesktopOpacity = root.currentDesktopOpacity
                            root.savedDesktopSquareSize = root.currentDesktopSquareSize
                            root.savedDesktopSquareSpacing = root.currentDesktopSquareSpacing
                            root.savedDesktopDisplayMode = desktopDisplayModeCombo.currentText
                            root.savedDesktopStartDay = desktopStartDayCombo.currentText
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
                            const displayMode = displayModeCombo.currentText
                            const startDay = startDayCombo.currentText
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
                    radius: Theme.cornerRadius
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
                        color: root.hasPendingChanges ? "#ffffff" : Theme.primary
                        
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
                        color: root.hasPendingChanges ? "#ffffff" : Theme.primary
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                DankRipple {
                    id: saveRipple
                    rippleColor: root.hasPendingChanges ? Theme.withAlpha("#ffffff", 0.3) : Theme.surfaceText
                    cornerRadius: Theme.cornerRadius
                    anchors.fill: parent
                }
            }
        }
    }
}
