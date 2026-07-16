import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Desktop surface of the GitHub Heatmap composite plugin.
DesktopPluginComponent {
    id: root

    // A single square plus its label header needs at least this much room;
    // below it we fall back to the single-day compact view.
    minWidth: 140
    minHeight: 90

    function readShared(key, defaultValue) {
        return SettingsData.getPluginSetting(root.pluginId, key, defaultValue)
    }

    // --- Settings (shared plugin_settings.json namespace with HeatMapWidget.qml) ---
    property string githubUsername: ""
    property bool followThemeColor: true
    property bool showDisplayName: false
    property real bgOpacity: 0.8
    property int squareSize: 24
    property int squareSpacing: 4
    property string displayMode: "2 Month"
    property string startDay: "Sunday"
    property bool hideDaysInitials: true
    readonly property string cachedStartDay: readShared("cachedStartDay", "Sunday")

    property string faGithubGlyph: "\uf09b"
    property string faFamily: "Font Awesome 6 Brands, Font Awesome 5 Brands, Font Awesome 6 Free, Font Awesome 5 Free"
    readonly property string iconRefresh: "refresh"
    property bool isSyncing: false

    // --- Data cached by the bar widget after each successful fetch ---
    property string totalContributions: "0"
    property string githubDisplayName: ""
    // Full year, 53 weeks x 7 days, oldest week first - see HeatMapWidget.qml's
    // cachedGrid write for how this is populated.
    property var rawGridData: []

    // True once refreshAll() has successfully picked up real cached grid
    // data at least once.
    property bool settingsEverLoaded: false
    // Counts consecutive empty reads before settingsEverLoaded first flips true.
    property int emptyReadCount: 0

    readonly property int maxEmptyRetries: 8

    function refreshAll() {
        const newUsername = readShared("username", "")
        const rawNew = readShared("cachedGrid", "")

        if (root.settingsEverLoaded && newUsername === "" && rawNew === "" && root.githubUsername !== "") {
            // Looks like a not-ready-yet read, not a genuine reset - leave
            // existing state alone and let the retry timer or the next real
            // pluginSettingsChanged signal supply correct data.
            return
        }

        root.githubUsername = newUsername
        root.followThemeColor = getData("followThemeColor", true)
        root.showDisplayName = getData("showDisplayName", false)
        root.bgOpacity = (getData("desktopBackgroundOpacity", 80)) / 100
        root.squareSize = getData("desktopSquareSize", 24)
        root.squareSpacing = getData("desktopSquareSpacing", 4)
        root.displayMode = getData("displayMode", "2 Month")
        root.startDay = getData("startDay", "Sunday")
        root.hideDaysInitials = getData("hideDaysInitials", true)
        root.totalContributions = readShared("cachedTotal", "0")
        root.githubDisplayName = readShared("cachedDisplayName", "")
        root.isSyncing = readShared("isSyncing", false)

        if (!rawNew) {
            root.rawGridData = []
            if (!root.settingsEverLoaded) {
                root.emptyReadCount += 1
                if (root.emptyReadCount >= root.maxEmptyRetries) {
                    root.settingsEverLoaded = true
                }
            }
        } else {
            try {
                root.rawGridData = JSON.parse(rawNew)
                root.settingsEverLoaded = true
                root.emptyReadCount = 0
            } catch (e) {
                root.rawGridData = []
            }
        }
    }

    Component.onCompleted: refreshAll()

    // Self-healing retry in case the first refreshAll() above hit SettingsData
    // before it had finished loading.
    Timer {
        interval: 1000
        repeat: true
        running: !root.settingsEverLoaded
        onTriggered: {
            root.refreshAll()
            if (!root.settingsEverLoaded) {
                interval = Math.min(interval * 2, 15000)
            }
        }
    }

    Connections {
        target: SettingsData
        function onPluginSettingsChanged() {
            root.refreshAll()
        }
    }

    Connections {
        target: Theme
        function onPrimaryChanged() { root.refreshAll() }
        function onSurfaceTextChanged() { root.refreshAll() }
    }

    onPluginDataChanged: {
        root.refreshAll()
    }

    readonly property var classicPalette: ["#202329", "#0e4429", "#006d32", "#26a641", "#39d353"]

    function levelToColor(level) {
        const lvl = Math.max(0, Math.min(4, Math.round(level || 0)))
        if (lvl === 0) {
            return Theme.withAlpha(Theme.surfaceText, 0.08)
        }
        if (!root.followThemeColor) {
            return root.classicPalette[lvl]
        }
        const steps = [0.25, 0.5, 0.75, 1.0]
        return Theme.withAlpha(Theme.primary, steps[lvl - 1])
    }

    function getAlignedGrid(rawGrid, localStart, cachedStart) {
        if (!rawGrid || rawGrid.length === 0) return []
        
        let flat = []
        for (let w = 0; w < rawGrid.length; w++) {
            for (let d = 0; d < rawGrid[w].length; d++) {
                flat.push(rawGrid[w][d])
            }
        }
        
        if (localStart !== cachedStart) {
            if (cachedStart === "Sunday" && localStart === "Monday") {
                flat.shift()
                flat.push({ date: "--/--", count: 0, level: 0, color: root.levelToColor(0) })
            } else if (cachedStart === "Monday" && localStart === "Sunday") {
                flat.unshift({ date: "--/--", count: 0, level: 0, color: root.levelToColor(0) })
                flat.pop()
            }
        }
        
        let grouped = []
        for (let i = 0; i < flat.length; i += 7) {
            grouped.push(flat.slice(i, i + 7))
        }
        return grouped
    }

    // Full year (up to 53 weeks), recolored and aligned under this surface's own settings.
    property var gridData: {
        const recolored = root.rawGridData.map(week =>
            week.map(day => Object.assign({}, day, {
                color: day.date === "--/--" ? root.levelToColor(0) : root.levelToColor(day.level)
            }))
        )
        return root.getAlignedGrid(recolored, root.startDay, root.cachedStartDay)
    }

    // Recalculate contributions displayed based on the desktop displayMode setting
    property int visibleContributions: {
        let total = 0;
        if (!root.gridData || root.gridData.length === 0) return 0;
        
        if (root.displayMode === "Week") {
            let week = root.gridData[root.gridData.length - 1];
            for (let i = 0; i < week.length; i++) {
                total += week[i].count;
            }
        } else {
            let weeks = 0;
            if (root.displayMode === "Month") weeks = 5;
            else if (root.displayMode === "2 Month") weeks = 9;
            else if (root.displayMode === "Year") weeks = 53;
            
            let sliced = root.gridData.slice(-weeks);
            for (let w = 0; w < sliced.length; w++) {
                for (let d = 0; d < sliced[w].length; d++) {
                    total += sliced[w][d].count;
                }
            }
        }
        return total;
    }

    Rectangle {
        id: mainContainer
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surfaceContainerLow, root.bgOpacity)
        border.color: Theme.withAlpha(Theme.outline, 0.15)
        border.width: 1

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingM

            readonly property real headerMinHeight: Theme.fontSizeLarge + Theme.fontSizeSmall + Theme.spacingS

            readonly property string displayMode: {
                if (root.widgetHeight < headerMinHeight + root.squareSize + Theme.spacingS) return "tiny"
                if (heatmapArea.oneWeekFitsHeight && heatmapArea.weeksThatFitWidth >= 2) return "grid"
                return "strip"
            }

            // Header Container Card
            Rectangle {
                id: headerCard
                Layout.fillWidth: true
                implicitHeight: 72
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainer, root.bgOpacity)
                border.color: Theme.withAlpha(Theme.outline, 0.3)
                border.width: 1
                visible: contentColumn.displayMode !== "tiny"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    // Left: GitHub Profile Icon
                    Rectangle {
                        width: 42
                        height: 42
                        radius: 21
                        color: Theme.withAlpha(Theme.primary, 0.2)
                        Layout.alignment: Qt.AlignVCenter
                        
                        MouseArea {
                            id: profileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: mouse => profileRipple.trigger(mouse.x, mouse.y)
                            onClicked: if (root.githubUsername) Qt.openUrlExternally("https://github.com/" + root.githubUsername)
                        }

                        StyledText {
                            text: root.faGithubGlyph
                            font.family: root.faFamily
                            font.pixelSize: 22
                            color: Theme.primary
                            anchors.centerIn: parent
                            scale: profileArea.containsMouse ? 1.2 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        }

                        DankRipple {
                            id: profileRipple
                            rippleColor: Theme.surfaceText
                            cornerRadius: 21
                            anchors.fill: parent
                        }
                    }

                    // Right: Username & Contributions (No Refresh Button)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Layout.alignment: Qt.AlignVCenter

                        StyledText {
                            Layout.fillWidth: true
                            text: (root.showDisplayName && root.githubDisplayName) ? root.githubDisplayName : (root.githubUsername || "GitHub User")
                            font.bold: true
                            font.pixelSize: contentColumn.displayMode === "strip" ? Theme.fontSizeMedium : Theme.fontSizeLarge
                            color: Theme.surfaceText
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root.isSyncing ? "Syncing..." : (root.visibleContributions + " contributions")
                            font.pixelSize: Theme.fontSizeSmall - 1
                            color: Theme.primary
                            opacity: 0.85
                        }
                    }
                }
            }

            // Contribution Container Card
            Rectangle {
                id: gridCard
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainer, root.bgOpacity)
                border.color: Theme.withAlpha(Theme.outline, 0.3)
                border.width: 1

                // Responsive heatmap area
                Item {
                    id: heatmapArea
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    visible: root.gridData.length > 0

                    readonly property int cell: root.squareSize + root.squareSpacing

                    readonly property real labelWidth: root.hideDaysInitials ? 0 : (Math.max(8, root.squareSize - 2) + 2 + root.squareSpacing * 2)

                    // Live (unthrottled) fit calculation.
                    readonly property int liveWeeksThatFitWidth: cell > 0 ? Math.max(0, Math.floor((width - labelWidth + root.squareSpacing) / cell)) : 0
                    readonly property bool liveOneWeekFitsHeight: cell > 0 ? (Math.floor((height + root.squareSpacing) / cell) >= 7) : false

                    // Debounced copies actually used for rendering.
                    property int weeksThatFitWidth: liveWeeksThatFitWidth
                    property bool oneWeekFitsHeight: liveOneWeekFitsHeight

                    Timer {
                        id: resizeSettle
                        interval: 100
                        onTriggered: {
                            heatmapArea.weeksThatFitWidth = heatmapArea.liveWeeksThatFitWidth
                            heatmapArea.oneWeekFitsHeight = heatmapArea.liveOneWeekFitsHeight
                        }
                    }
                    onWidthChanged: resizeSettle.restart()
                    onHeightChanged: resizeSettle.restart()

                    readonly property string mode: contentColumn.displayMode

                    readonly property int maxWeeksByMode: {
                        if (root.displayMode === "Week") return 1
                        if (root.displayMode === "Month") return 5
                        if (root.displayMode === "2 Month") return 9
                        if (root.displayMode === "Year") return 53
                        return 9
                    }
                    readonly property int weeksToShow: Math.max(1, Math.min(root.gridData.length, Math.min(weeksThatFitWidth, maxWeeksByMode)))
                    readonly property int firstVisibleWeekIdx: root.gridData.length - weeksToShow

                    // "tiny" mode: single square for today
                    Rectangle {
                        visible: heatmapArea.mode === "tiny"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(root.squareSize * 2, parent.width, parent.height)
                        height: width
                        radius: Math.max(1, width * 0.25)
                        antialiasing: true
                        color: {
                            const weeks = root.gridData
                            if (weeks.length === 0) return root.levelToColor(0)
                            const lastWeek = weeks[weeks.length - 1]
                            for (let d = lastWeek.length - 1; d >= 0; d--) {
                                if (lastWeek[d].date !== "--/--") return lastWeek[d].color
                            }
                            return root.levelToColor(0)
                        }
                        border.color: Theme.withAlpha(Theme.outline, 0.35)
                        border.width: 1
                    }

                    // "strip" mode: single horizontal row of the most recent 7 days
                    Row {
                        visible: heatmapArea.mode === "strip"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: root.squareSpacing

                        Repeater {
                            model: {
                                if (heatmapArea.mode !== "strip" || root.gridData.length === 0) return []
                                const flat = []
                                for (let w = 0; w < root.gridData.length; w++) {
                                    for (let d = 0; d < root.gridData[w].length; d++) {
                                        if (root.gridData[w][d].date !== "--/--") flat.push(root.gridData[w][d])
                                    }
                                }
                                return flat.slice(-7)
                            }

                            Rectangle {
                                width: Math.min(root.squareSize, heatmapArea.height)
                                height: width
                                radius: Math.max(1, width * 0.25)
                                antialiasing: true
                                color: modelData.color
                                border.color: Theme.withAlpha(Theme.outline, 0.35)
                                border.width: 1
                            }
                        }
                    }

                    // Grid view: up to 53 weeks x 7 days
                    Row {
                        id: gridContainer
                        visible: heatmapArea.mode === "grid"
                        anchors.centerIn: parent
                        spacing: root.squareSpacing * 2

                        // 1) VERTICAL DAY LABELS (Only if !root.hideDaysInitials)
                        Column {
                            visible: !root.hideDaysInitials
                            spacing: root.squareSpacing
                            
                            Repeater {
                                model: root.startDay === "Monday" ? ["M", "T", "W", "T", "F", "S", "S"] : ["S", "M", "T", "W", "T", "F", "S"]
                                StyledText {
                                    text: modelData
                                    font.pixelSize: Math.max(8, root.squareSize - 2)
                                    color: Theme.surfaceVariantText
                                    width: font.pixelSize + 2
                                    height: root.squareSize
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        // 2) GRID OF SQUARES
                        GridLayout {
                            id: gridLayout
                            columns: Math.max(1, heatmapArea.weeksToShow)
                            rows: 7
                            flow: GridLayout.TopToBottom
                            rowSpacing: root.squareSpacing
                            columnSpacing: root.squareSpacing

                            Repeater {
                                model: gridContainer.visible ? heatmapArea.weeksToShow * 7 : 0

                                Rectangle {
                                    readonly property int weekIdx: heatmapArea.firstVisibleWeekIdx + Math.floor(index / 7)
                                    readonly property int dayIdx: index % 7
                                    readonly property var dayData: {
                                        const week = root.gridData[weekIdx]
                                        return week && dayIdx < week.length ? week[dayIdx] : null
                                    }

                                    Layout.preferredWidth: root.squareSize
                                    Layout.preferredHeight: root.squareSize
                                    radius: Math.max(1, root.squareSize * 0.25)
                                    antialiasing: true
                                    color: dayData ? dayData.color : root.levelToColor(0)
                                    border.color: Theme.withAlpha(Theme.outline, 0.3)
                                    border.width: 1
                                }
                            }
                        }
                    }
                }

                // Empty state
                StyledText {
                    visible: root.gridData.length === 0
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    text: root.githubUsername
                          ? "Waiting for data - open the GitHub Heatmap bar widget once to fetch it."
                          : "Set your GitHub username in the GitHub Heatmap plugin settings."
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }
    }
}
