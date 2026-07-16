import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import QtQuick.Layouts
import QtQuick.Controls

PluginComponent {
    id: root

    popoutWidth: {
        if (root.displayMode === "Month") return 280
        if (root.displayMode === "2 Month") return 360
        if (root.displayMode === "Year") return 1650
        return 320 // Week
    }

    popoutHeight: {
        if (root.displayMode === "Week") return 280
        return 430 // Month, 2 Month, and Year
    }

    property bool showNotifications: true
    property bool followThemeColor: true
    property string displayMode: "2 Month"
    property string startDay: "Sunday"
    property bool hideDaysInitials: false
    
    // Icons
    readonly property string iconBar: "commit"
    readonly property string iconRefresh: "refresh"
    readonly property string iconError: "error"
    readonly property string iconOpen: "open_in_browser"
    readonly property string iconSuccess: "check_circle"

    // Settings
    property string githubUsername: ""
    property int refreshInterval: 300
    
    function readShared(key, defaultValue) {
        return SettingsData.getPluginSetting(root.pluginId, key, defaultValue)
    }

    function refreshAll() {
        root.githubUsername = readShared("username", "")
        root.refreshInterval = readShared("refreshInterval", 300)
        root.showNotifications = readShared("showNotifications", true)
        root.followThemeColor = readShared("followThemeColor", true)
        root.displayMode = readShared("displayMode", "2 Month")
        root.startDay = readShared("startDay", "Sunday")
        root.hideDaysInitials = readShared("hideDaysInitials", false)
        root.popoutX = readShared("popoutX", -1)
        root.popoutY = readShared("popoutY", -1)
    }

    property int lastTriggerValue: parseInt(readShared("forceRefreshTrigger", 0)) || 0

    Connections {
        target: SettingsData
        function onPluginSettingsChanged() {
            root.refreshAll()
            
            const trigger = parseInt(SettingsData.getPluginSetting(root.pluginId, "forceRefreshTrigger", 0)) || 0
            if (trigger > root.lastTriggerValue) {
                root.lastTriggerValue = trigger
                root.refreshHeatmap()
            }
        }
    }
    property string faGithubGlyph: "\uf09b"
    property string faFamily: "Font Awesome 6 Brands, Font Awesome 5 Brands, Font Awesome 6 Free, Font Awesome 5 Free"

    // State - Always 7 items for fixed width
    property var rawContributions: []
    property var rawGridData: []  // 53 weeks of data for calendar grid

    // Classic GitHub-style palette (used when followThemeColor is false).
    readonly property var classicPalette: ["#202329", "#0e4429", "#006d32", "#26a641", "#39d353"]

    // Map legacy color hex string to contribution level (0-4)
    function colorToLevel(colorStr) {
        if (!colorStr) return 0
        switch (colorStr.toLowerCase()) {
            case "#0e4429": return 1
            case "#006d32": return 2
            case "#26a641": return 3
            case "#39d353": return 4
            default: return 0
        }
    }

    // Map a contribution level (0-4) to a color, either the classic palette
    // or a set of shades derived from the current DMS theme's primary color.
    function levelToColor(level) {
        const lvl = Math.max(0, Math.min(4, Math.round(level || 0)))
        if (lvl === 0) {
            // Empty slots use a faint transparent surfaceText
            return Theme.withAlpha(Theme.surfaceText, 0.08)
        }
        if (!root.followThemeColor) {
            return root.classicPalette[lvl]
        }
        const steps = [0.25, 0.5, 0.75, 1.0]
        return Theme.withAlpha(Theme.primary, steps[lvl - 1])
    }

    // Dynamic, theme-aware mapping of contributions and grid data
    property var contributions: root.rawContributions.map(day => {
        const lvl = (day.level !== undefined) ? day.level : root.colorToLevel(day.color)
        return Object.assign({}, day, {
            color: day.date === "--/--" ? root.levelToColor(0) : root.levelToColor(lvl),
            level: lvl
        })
    })

    property var gridData: root.rawGridData.map(week => {
        return week.map(day => {
            const lvl = (day.level !== undefined) ? day.level : root.colorToLevel(day.color)
            return Object.assign({}, day, {
                color: day.date === "--/--" ? root.levelToColor(0) : root.levelToColor(lvl),
                level: lvl
            })
        })
    })

    // Sync selectedDay, todayDay, and yesterdayDay references on gridData update
    onGridDataChanged: {
        let validDays = []
        for (let w = 0; w < gridData.length; w++) {
            for (let d = 0; d < gridData[w].length; d++) {
                if (gridData[w][d].date !== "--/--") {
                    validDays.push(gridData[w][d])
                }
            }
        }
        
        let newToday = null
        let newYesterday = null
        if (validDays.length > 0) {
            newToday = validDays[validDays.length - 1]
            if (validDays.length > 1) {
                newYesterday = validDays[validDays.length - 2]
            }
        } else if (gridData.length > 0) {
            const lastWeek = gridData[gridData.length - 1]
            newToday = lastWeek[lastWeek.length - 1]
            if (lastWeek.length > 1) {
                newYesterday = lastWeek[lastWeek.length - 2]
            } else if (gridData.length > 1) {
                const prevWeek = gridData[gridData.length - 2]
                newYesterday = prevWeek[prevWeek.length - 1]
            }
        }

        // Preserve selected day by matching date
        let newSelected = null
        if (selectedDay) {
            for (let w = 0; w < gridData.length; w++) {
                for (let d = 0; d < gridData[w].length; d++) {
                    if (gridData[w][d].date === selectedDay.date) {
                        newSelected = gridData[w][d]
                        break
                    }
                }
                if (newSelected) break
            }
        }

        // Apply new references
        todayDay = newToday
        yesterdayDay = newYesterday
        selectedDay = newSelected || newToday
    }
    property string totalContributions: "0"
    property bool isError: false
    property bool isLoading: false
    onIsLoadingChanged: {
        SettingsData.setPluginSetting(root.pluginId, "isSyncing", isLoading)
    }
    property string errorMessage: ""
    property var lastRefreshTime: null
    property bool isManualRefresh: false
    property var selectedDay: null
    property var todayDay: null
    property var yesterdayDay: null

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

    // Initialize with cached data if available
    Component.onCompleted: {
        root.refreshAll()

        const cachedTotal = root.readShared("cachedTotal", "")
        const cachedGridStr = root.readShared("cachedGrid", "")
        const cachedStartDay = root.readShared("cachedStartDay", "Sunday")
        
        const cacheValid = (cachedStartDay === root.startDay)
        
        if (cachedTotal && cachedGridStr && cacheValid) {
            try {
                const cachedGrid = JSON.parse(cachedGridStr)
                root.totalContributions = cachedTotal
                root.rawGridData = cachedGrid
                root.isError = false
                
                const lastTime = parseInt(root.readShared("lastRefreshTime", "0"))
                if (lastTime > 0) {
                    root.lastRefreshTime = lastTime
                }
            } catch (e) {
                console.error("GitHub: Failed to parse persistent cache")
                initializePlaceholders()
            }
        } else {
            initializePlaceholders()
            if (githubUsername) {
                root.refreshHeatmap()
            }
        }

        // Start timer after a delay to ensure network is ready
        startupDelay.start()
    }

    Timer {
        id: startupDelay
        interval: 5000 // 5 second delay for network stability
        repeat: false
        onTriggered: {
            if (githubUsername) {
                refreshTimer.start()
            }
        }
    }

    // Watch for credential changes
    onGithubUsernameChanged: checkAndStartTimer()
    onRefreshIntervalChanged: {
        if (refreshTimer.running) {
            refreshTimer.restart()
        }
    }
    onStartDayChanged: {
        if (githubUsername) {
            root.isManualRefresh = false
            root.lastRefreshTime = null // clear cooldown
            root.refreshHeatmap()
        }
    }

    function checkAndStartTimer() {
        if (githubUsername) {
            if (!refreshTimer.running) {
                refreshTimer.start()
                root.refreshHeatmap() // Immediate fetch on username change
            }
        } else {
            refreshTimer.stop()
            initializePlaceholders()
        }
    }

    // Initialize 7 placeholder squares
    function initializePlaceholders() {
        const placeholders = []
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        for (let i = 0; i < 7; i++) {
            placeholders.push({
                weekday: days[i],
                date: "--/--",
                count: 0,
                color: Theme.surfaceContainer,
                level: 0
            })
        }

        rawContributions = placeholders
        totalContributions = "0"
        isError = false

        // Initialize grid placeholders (53 weeks × 7 days)
        const gridPlaceholders = []
        for (let week = 0; week < 53; week++) {
            const weekData = []
            for (let day = 0; day < 7; day++) {
                weekData.push({
                    weekday: day,
                    weekdayName: days[day],
                    date: "--/--",
                    count: 0,
                    color: Theme.surfaceContainer,
                    level: 0
                })
            }
            gridPlaceholders.push(weekData)
        }
        rawGridData = gridPlaceholders
    }

    // Shell escape function for security
    function escapeShellString(str) {
        if (!str) return ""
        return str.replace(/\\/g, "\\\\")
                  .replace(/"/g, "\\\"")
                  .replace(/\$/g, "\\$")
                  .replace(/`/g, "\\`")
    }

    function showTooltip(text, mouseArea) {
        // DankTooltipV2 handles all coordinate mapping internally by passing the item
        tooltip.show(text, mouseArea);
    }

    // Auto-refresh timer
    Timer {
        id: refreshTimer
        interval: root.refreshInterval * 1000
        repeat: true
        running: false
        triggeredOnStart: true
        onTriggered: {
            if (root.githubUsername) {
                root.isManualRefresh = false  // Automatic refresh
                root.refreshHeatmap()
            } else {
                root.isError = true
                root.errorMessage = "Configure GitHub username in settings"
            }
        }
    }

    // Refresh function
    function refreshHeatmap() {
        if (!githubUsername) {
            isError = true
            errorMessage = "Configure GitHub username in settings"
            return
        }

        // Cooldown: prevent refreshes within 30 seconds of last successful refresh
        const now = Date.now()
        if (lastRefreshTime && (now - lastRefreshTime) < 30000 && !root.isRetrying) {
            console.log("GitHub: Skipping refresh (cooldown active)")
            return
        }

        console.log("GitHub: Starting fetch...")
        isLoading = true
        root.isRetrying = false
        githubProcess.running = false
        githubProcess.command = ["/usr/bin/env", "bash", "-c", root.buildScript(root.githubUsername, root.startDay)]
        githubProcess.running = true
    }

    // Handle failure and setup retry
    property bool isRetrying: false
    function handleFetchFailure(msg) {
        root.isError = true
        root.errorMessage = msg
        root.isLoading = false
        root.isRetrying = true
        retryTimer.start()
    }

    Timer {
        id: retryTimer
        interval: 2000
        repeat: false
        onTriggered: root.refreshHeatmap()
    }

    // Build the embedded Bash script
    function buildScript(username, sDay) {
        const escapedUsername = escapeShellString(username)
        const escapedStartDay = escapeShellString(sDay)

        // NOTE: We must escape ${} as \${} to prevent JS interpolation
        return `
# GitHub Heatmap Fetcher (Bash + Public API)
GITHUB_USERNAME="${escapedUsername}"
START_DAY="${escapedStartDay}"

# GitHub contribution color scheme (dark theme)
COLOR_0="#202329"
COLOR_1="#0e4429"
COLOR_2="#006d32"
COLOR_3="#26a641"
COLOR_4="#39d353"

# 1. Calculate date range
today=$(date +%Y-%m-%d)
today_dow=$(date -d "$today" +%u)

if [ "$START_DAY" = "Monday" ]; then
    if [ "$today_dow" = "1" ]; then
        current_start="$today"
    else
        days_to_sub=$((today_dow - 1))
        current_start=$(date -d "$today -$days_to_sub days" +%Y-%m-%d)
    fi
else
    if [ "$today_dow" = "7" ]; then
        current_start="$today"
    else
        current_start=$(date -d "$today -$today_dow days" +%Y-%m-%d)
    fi
fi

start_date=$(date -d "$current_start -364 days" +%Y-%m-%d)
today_timestamp=$(date -d "$today" +%s)

# 2. Fetch Data (Public API)
url="https://github-contributions-api.jogruber.de/v4/$GITHUB_USERNAME?y=last"

temp_response=$(mktemp)
http_code=$(curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -w "%{http_code}" -o "$temp_response" "$url")
body=$(cat "$temp_response")
rm -f "$temp_response"

# 3. Validation
if [ "$http_code" != "200" ]; then
    printf '{"contributions":[],"total":0,"error":true,"errorMessage":"User not found or API error (HTTP %s)"}\n' "$http_code"
    exit 1
fi

# 4. Process Data
# We use jq to filter relevant days (>= start_date)
relevant_days=$(echo "$body" | jq -c --arg start "$start_date" '.contributions[] | select(.date >= $start)')

total_contributions=0
all_days=()

# Read filtered JSON lines
while read -r day_json; do
    if [ -z "$day_json" ]; then continue; fi
    
    date=$(echo "$day_json" | jq -r '.date')
    count=$(echo "$day_json" | jq -r '.count')
    level=$(echo "$day_json" | jq -r '.level')
    
    day_timestamp=$(date -d "$date" +%s)
    
    if [ "$day_timestamp" -le "$today_timestamp" ]; then
        
        case "$level" in
            0) color="$COLOR_0" ;;
            1) color="$COLOR_1" ;;
            2) color="$COLOR_2" ;;
            3) color="$COLOR_3" ;;
            4) color="$COLOR_4" ;;
            *) color="$COLOR_0" ;;
        esac

        total_contributions=$((total_contributions + count))

        if [ "$START_DAY" = "Monday" ]; then
            weekday=$(( $(date -d "$date" +%u) - 1 ))
            weekday_names=("Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")
        else
            weekday=$(date -d "$date" +%w)
            weekday_names=("Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat")
        fi

        formatted_date=$(date -d "$date" "+%d / %b / %y")
        tooltip_text=$(date -d "$date" "+%d / %b :: $count")
        
        # Fix: Escape \${} to prevent JS interpolation
        weekday_name="\${weekday_names[$weekday]}"

        all_days+=("$date|$weekday|$count|$color|$formatted_date|$weekday_name|$tooltip_text|$level")
    fi
done <<< "$relevant_days"

# 5. Build Grid
# Fix: Escape \${} to prevent JS interpolation
IFS=$'\\n' sorted_days=($(sort <<<"\${all_days[*]}"))
unset IFS

grid_json="["
current_week="["
current_week_day=-1
first_week=1
first_day_in_week=1

# Fix: Escape \${} to prevent JS interpolation
for day_data in "\${sorted_days[@]}"; do
    IFS='|' read -r date weekday count color formatted_date weekday_name tooltip_text level <<< "$day_data"
    
    if [ "$weekday" == "0" ] && [ "$first_day_in_week" == "0" ]; then
        current_week="$current_week]"
        if [ "$first_week" == "1" ]; then
            grid_json="$grid_json$current_week"
            first_week=0
        else
            grid_json="$grid_json,$current_week"
        fi
        current_week="["
        first_day_in_week=1
    fi

    day_obj="{\\\"weekday\\\":$weekday,\\\"weekdayName\\\":\\\"$weekday_name\\\",\\\"date\\\":\\\"$formatted_date\\\",\\\"count\\\":$count,\\\"color\\\":\\\"$color\\\",\\\"level\\\":$level,\\\"tooltipText\\\":\\\"$tooltip_text\\\"}"

    if [ "$first_day_in_week" == "1" ]; then
        current_week="$current_week$day_obj"
        first_day_in_week=0
    else
        current_week="$current_week,$day_obj"
    fi
done

current_week="$current_week]"
if [ "$first_week" == "1" ]; then
    grid_json="$grid_json$current_week"
else
    grid_json="$grid_json,$current_week"
fi
grid_json="$grid_json]"

# 6. Build Pill Data
# Fix: Escape \${} to prevent JS interpolation
day_count=\${#sorted_days[@]}
pill_start=$((day_count - 7))
if [ $pill_start -lt 0 ]; then pill_start=0; fi

pill_json="["
pill_count=0

for (( i=pill_start; i<day_count; i++ )); do
    # Fix: Escape \${} to prevent JS interpolation
    day_data="\${sorted_days[$i]}"
    IFS='|' read -r date weekday count color formatted_date weekday_name tooltip_text level <<< "$day_data"

    if [ $pill_count -gt 0 ]; then
        pill_json="$pill_json,"
    fi
    pill_json="$pill_json{\\\"weekday\\\":\\\"$weekday_name\\\",\\\"date\\\":\\\"$formatted_date\\\",\\\"count\\\":$count,\\\"color\\\":\\\"$color\\\",\\\"level\\\":$level,\\\"tooltipText\\\":\\\"$tooltip_text\\\"}"
    pill_count=$((pill_count + 1))
done
pill_json="$pill_json]"

printf '{"contributions":%s,"gridData":%s,"total":%d,"error":false}\\n' "$pill_json" "$grid_json" "$total_contributions"
exit 0
`
    }

    // Bash process
    Process {
        id: githubProcess
        command: ["/usr/bin/env", "bash", "-c", root.buildScript(root.githubUsername, root.startDay)]
        running: false

        stdout: SplitParser {
            onRead: data => {
                try {
                    const result = JSON.parse(data.trim())

                    if (result.error) {
                        console.error("GitHub: API error -", result.errorMessage)
                        root.isError = true
                        root.errorMessage = result.errorMessage || "Unknown error"
                        root.initializePlaceholders()
                        root.isLoading = false
                        if (root.isManualRefresh) {
                            notifyFail.running = true
                        }
                        return
                    }

                    console.log("GitHub: Successfully fetched", result.contributions.length, "days for pill,", result.gridData.length, "weeks for grid")

                    root.isError = false
                    root.isLoading = false

                    // Ensure we always have exactly 7 items for pill
                    let newContributions = result.contributions || []

                    // Pad with placeholders if less than 7
                    while (newContributions.length < 7) {
                        newContributions.push({
                            weekday: "---",
                            date: "--/--",
                            count: 0,
                            color: Theme.surfaceContainer,
                            level: 0
                        })
                    }

                    // Trim if more than 7
                    newContributions = newContributions.slice(0, 7)

                    root.rawContributions = newContributions
                    root.totalContributions = result.total.toString()

                    // Process grid data - ensure 4 weeks with 7 days each
                    const days = root.startDay === "Monday"
                        ? ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                        : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    let newGridData = result.gridData || []

                    // Pad to 53 weeks if needed
                    while (newGridData.length < 53) {
                        const emptyWeek = []
                        for (let d = 0; d < 7; d++) {
                            emptyWeek.push({
                                weekday: d,
                                weekdayName: days[d],
                                date: "--/--",
                                count: 0,
                                color: Theme.surfaceContainer,
                                level: 0
                            })
                        }
                        newGridData.unshift(emptyWeek)
                    }

                    // Ensure each week has 7 days
                    for (let w = 0; w < newGridData.length; w++) {
                        while (newGridData[w].length < 7) {
                            const missingDay = newGridData[w].length
                            newGridData[w].push({
                                weekday: missingDay,
                                weekdayName: days[missingDay],
                                date: "--/--",
                                count: 0,
                                color: Theme.surfaceContainer,
                                level: 0
                            })
                        }
                    }

                    // Take only last 53 weeks
                    newGridData = newGridData.slice(-53)

                    root.rawGridData = newGridData
                    // Cache successful fetch persistently
                    root.lastRefreshTime = Date.now()
                    SettingsData.setPluginSetting(root.pluginId, "cachedTotal", root.totalContributions)
                    SettingsData.setPluginSetting(root.pluginId, "cachedGrid", JSON.stringify(root.rawGridData))
                    SettingsData.setPluginSetting(root.pluginId, "cachedStartDay", root.startDay)
                    SettingsData.setPluginSetting(root.pluginId, "lastRefreshTime", root.lastRefreshTime.toString())
                    
                    if (root.isManualRefresh && root.showNotifications) {
                        notifySuccess.running = true
                    }

                } catch (e) {
                    console.error("GitHub: Failed to parse response -", e, "Data:", data)
                    root.isError = true
                    root.errorMessage = "Failed to parse GitHub response"
                    root.initializePlaceholders()
                    root.isLoading = false
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.isLoading = false
            if (exitCode !== 0 && !root.isError) {
                console.error("GitHub: Script failed with exit code", exitCode)
                root.isError = true
                root.errorMessage = "Script failed with exit code: " + exitCode
                if (root.isManualRefresh && root.showNotifications) {
                    notifyFail.running = true
                }
                root.handleFetchFailure("Sync failed (Check logs)")
            }
        }
    }

    // Notification processes
    Process {
        id: notifySuccess
        command: ["notify-send", "-t", "3000", "GitHub Synced", "Contributions refreshed successfully"]
        running: false
    }

    Process {
        id: notifyFail
        command: ["notify-send", "-u", "critical", "-t", "5000", "GitHub Sync Failed", root.errorMessage]
        running: false
    }

    Process {
        id: openProfileProcess
        command: ["xdg-open", "https://github.com/" + root.githubUsername]
        running: false
    }

    // Horizontal bar pill - ALWAYS 7 squares
    horizontalBarPill: Component {
        RowLayout {
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: 7

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 16
                    radius: 2
                    color: index < root.contributions.length
                           ? root.contributions[index].color
                           : root.levelToColor(0)
                    border.color: Theme.withAlpha(Theme.outline, 0.3)
                    border.width: 1
                    opacity: root.isLoading ? 0.6 : 1.0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
        }
    }

    // Vertical bar pill - ALWAYS 7 squares
    verticalBarPill: Component {
        Column {
            spacing: 2

            Repeater {
                model: 7

                Rectangle {
                    width: 16
                    height: 8
                    radius: 2
                    color: index < root.contributions.length
                           ? root.contributions[index].color
                           : root.levelToColor(0)
                    border.color: Theme.withAlpha(Theme.outline, 0.3)
                    border.width: 1
                    opacity: root.isLoading ? 0.6 : 1.0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }
        }
    }

    // Popout position persistence
    property int popoutX: -1
    property int popoutY: -1

    function savePopoutPosition(x, y) {
        SettingsData.setPluginSetting(root.pluginId, "popoutX", x)
        SettingsData.setPluginSetting(root.pluginId, "popoutY", y)
        PluginService.setGlobalVar(root.pluginId, "popoutX", x)
        PluginService.setGlobalVar(root.pluginId, "popoutY", y)
    }

    // --- Popout Content ---
    popoutContent: Component {
        PopoutComponent {
            id: popoutContainer

            // Restore saved position
            x: root.popoutX >= 0 ? root.popoutX : x
            y: root.popoutY >= 0 ? root.popoutY : y

            // Save position when moved
            onXChanged: if (visible) Qt.callLater(() => root.savePopoutPosition(x, y))
            onYChanged: if (visible) Qt.callLater(() => root.savePopoutPosition(x, y))

            showCloseButton: false
            headerText: "" 

            Loader {
                id: popoutLoader
                width: parent.width
                asynchronous: true
                sourceComponent: heatmapWidgetContent
            }
        }
    }


    Component {
        id: heatmapWidgetContent
        Column {
            id: mainCol
            width: parent.width
            spacing: Theme.spacingM
            padding: 0
            topPadding: 0
            bottomPadding: 2

            // Header card
            StyledRect {
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                height: 72
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.width: 1
                border.color: Theme.withAlpha(Theme.primary, 0.15)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    Rectangle {
                        width: 42
                        height: 42
                        radius: 21
                        color: Theme.withAlpha(Theme.primary, 0.2)
                        
                        MouseArea {
                            id: profileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: mouse => profileRipple.trigger(mouse.x, mouse.y)
                            onClicked: if (root.githubUsername) openProfileProcess.running = true
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

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        
                        StyledText {
                            id: usernameText
                            Layout.fillWidth: true
                            text: root.githubUsername || "GitHub User"
                            font.bold: true
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.surfaceText
                            elide: Text.ElideRight
                            
                            onTextChanged: usernameAnim.restart()
                            transform: Translate { id: usernameTrans }
                            SequentialAnimation {
                                id: usernameAnim
                                ParallelAnimation {
                                    NumberAnimation { target: usernameText; property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: usernameTrans; property: "y"; to: 5; duration: 150; easing.type: Easing.OutQuad }
                                }
                                PropertyAction { target: usernameTrans; property: "y"; value: -5 }
                                ParallelAnimation {
                                    NumberAnimation { target: usernameText; property: "opacity"; to: 1; duration: 150; easing.type: Easing.InQuad }
                                    NumberAnimation { target: usernameTrans; property: "y"; to: 0; duration: 150; easing.type: Easing.InQuad }
                                }
                            }
                        }

                        StyledText {
                            id: contributionStatusText
                            Layout.fillWidth: true
                            text: root.isError ? "Connection Error" : (root.isLoading ? "Syncing..." : root.visibleContributions + " contributions")
                            font.pixelSize: Theme.fontSizeSmall - 1
                            color: Theme.primary
                            opacity: 0.8
                            
                            onTextChanged: statusAnim.restart()
                            transform: Translate { id: statusTrans }
                            SequentialAnimation {
                                id: statusAnim
                                ParallelAnimation {
                                    NumberAnimation { target: contributionStatusText; property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutQuad }
                                    NumberAnimation { target: statusTrans; property: "y"; to: 5; duration: 150; easing.type: Easing.OutQuad }
                                }
                                PropertyAction { target: statusTrans; property: "y"; value: -5 }
                                ParallelAnimation {
                                    NumberAnimation { target: contributionStatusText; property: "opacity"; to: 0.8; duration: 150; easing.type: Easing.InQuad }
                                    NumberAnimation { target: statusTrans; property: "y"; to: 0; duration: 150; easing.type: Easing.InQuad }
                                }
                            }
                        }
                    }

                    Item {
                        width: 38
                        height: 38
                        Layout.alignment: Qt.AlignVCenter
                        scale: refreshArea.pressed ? 0.9 : (refreshArea.containsMouse ? 1.1 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                        MouseArea {
                            id: refreshArea
                            anchors.fill: parent
                            hoverEnabled: !root.isLoading
                            enabled: !root.isLoading
                            cursorShape: root.isLoading ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onPressed: mouse => refreshRipple.trigger(mouse.x, mouse.y)
                            onClicked: {
                                root.isManualRefresh = true
                                root.refreshHeatmap()
                            }
                            onExited: {
                                if (!root.isLoading) {
                                    refreshIcon.rotation = 0
                                }
                            }
                        }

                        Rectangle {
                            id: refreshBg
                            anchors.fill: parent
                            radius: refreshArea.pressed ? (width / 2) : Theme.cornerRadius
                            color: refreshArea.pressed ? Theme.withAlpha(Theme.primary, 0.18) : (refreshArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.10) : Theme.withAlpha(Theme.secondary, 0.04))
                            border.width: 1
                            border.color: refreshArea.pressed ? Theme.withAlpha(Theme.primary, 0.60) : (refreshArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.40) : Theme.withAlpha(Theme.secondary, 0.15))
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on radius { NumberAnimation { duration: 150 } }
                        }

                        DankIcon {
                            id: refreshIcon
                            name: root.isLoading ? "cached" : root.iconRefresh
                            size: 20
                            color: Theme.primary
                            anchors.centerIn: parent

                            SequentialAnimation {
                                id: hoverSpinAnim
                                running: refreshArea.containsMouse && !root.isLoading
                                loops: Animation.Infinite
                                onStopped: refreshIcon.rotation = 0
                                NumberAnimation { target: refreshIcon; property: "rotation"; to: -8; duration: 150; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: refreshIcon; property: "rotation"; to: 8; duration: 150; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: refreshIcon; property: "rotation"; to: 0; duration: 150; easing.type: Easing.InOutQuad }
                                PauseAnimation { duration: 400 }
                            }

                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: root.isLoading
                                onStopped: refreshIcon.rotation = 0
                            }
                        }

                        DankRipple {
                            id: refreshRipple
                            rippleColor: Theme.surfaceText
                            cornerRadius: refreshBg.radius
                            anchors.fill: parent
                        }
                    }
                }
            }

            // Error display
            StyledRect {
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                height: root.isError ? 60 : 0
                radius: Theme.cornerRadius
                color: Theme.errorContainer || Theme.surfaceContainerHigh
                visible: root.isError
                clip: true
                Behavior on height { NumberAnimation { duration: 150 } }

                StyledText {
                    anchors.centerIn: parent
                    width: Math.max(0, parent.width - Theme.spacingL * 2)
                    text: root.errorMessage
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.onErrorContainer || Theme.error
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            // Calendar grid container
            StyledRect {
                id: gridContainer
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                height: {
                    if (root.displayMode === "Week") return 90
                    return 240
                }
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                border.width: 1
                border.color: Theme.withAlpha(Theme.primary, 0.15)
                visible: !root.isError

                HoverHandler {
                    id: gridHover
                    onHoveredChanged: if (!hovered) root.selectedDay = root.todayDay
                }

                Flickable {
                    id: flickable
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    contentWidth: gridRowLayout.width
                    contentHeight: gridRowLayout.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.horizontal: ScrollBar { 
                        visible: flickable.contentWidth > flickable.width 
                    }

                    onContentWidthChanged: {
                        if (contentWidth > width) {
                            contentX = contentWidth - width
                        }
                    }

                    Row {
                        id: gridRowLayout
                        y: Math.max(0, (flickable.height - height) / 2)
                        x: Math.max(0, (flickable.width - width) / 2)
                        spacing: root.displayMode === "Month" ? 16 : 4
                        
                        // 1) VERTICAL DAY LABELS (For Month, 2 Month, Year)
                        Column {
                            visible: root.displayMode !== "Week" && !root.hideDaysInitials
                            spacing: 4
                            topPadding: 4
                            Repeater {
                                model: root.startDay === "Monday" ? ["M", "T", "W", "T", "F", "S", "S"] : ["S", "M", "T", "W", "T", "F", "S"]
                                StyledText {
                                    text: modelData
                                    font.pixelSize: 10
                                    color: Theme.surfaceVariantText
                                    width: 14
                                    height: 26
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        // 2) GRID for Month, 2 Month, Year
                        Row {
                            visible: root.displayMode !== "Week"
                            spacing: root.displayMode === "Month" ? 16 : 4
                            Repeater {
                                model: {
                                    if (root.displayMode === "Month") return root.gridData.slice(-5)
                                    if (root.displayMode === "2 Month") return root.gridData.slice(-9)
                                    if (root.displayMode === "Year") return root.gridData.slice(-53)
                                    return []
                                }
                                Column {
                                    spacing: 4
                                    required property var modelData
                                    Repeater {
                                        model: modelData
                                        Rectangle {
                                            width: 26
                                            height: 26
                                            radius: root.selectedDay === modelData ? (width/2) : 4
                                            Behavior on radius { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                                            color: modelData.color || root.levelToColor(0)
                                            border.color: root.selectedDay === modelData ? Theme.primary : Theme.withAlpha(Theme.outline, 0.3)
                                            border.width: root.selectedDay === modelData ? 2 : 1
                                            required property var modelData
                                            opacity: root.isLoading ? 0.6 : 1.0
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                            Behavior on color { ColorAnimation { duration: 150 } }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onEntered: root.selectedDay = modelData
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 3) HORIZONTAL WEEK for "Week"
                        Row {
                            visible: root.displayMode === "Week"
                            spacing: 12
                            Repeater {
                                model: {
                                    if (root.displayMode === "Week" && root.gridData.length > 0) {
                                        return root.gridData[root.gridData.length - 1]
                                    }
                                    return []
                                }
                                Column {
                                    spacing: 8
                                    required property var modelData
                                    
                                    StyledText {
                                        visible: !root.hideDaysInitials
                                        text: modelData.weekdayName ? modelData.weekdayName.charAt(0) : ""
                                        font.pixelSize: 10
                                        color: Theme.surfaceVariantText
                                        width: 26
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: root.selectedDay === modelData ? 13 : 4
                                        Behavior on radius { NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
                                        color: modelData.color || root.levelToColor(0)
                                        border.color: root.selectedDay === modelData ? Theme.primary : Theme.withAlpha(Theme.outline, 0.3)
                                        border.width: root.selectedDay === modelData ? 2 : 1
                                        opacity: root.isLoading ? 0.6 : 1.0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onEntered: root.selectedDay = modelData
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

                // Contribution detail card
                StyledRect {
                    width: parent.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 80
                    radius: Theme.cornerRadius
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.primary, 0.15)
                    visible: root.selectedDay !== null && !root.isError
                    clip: true

                    Row {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingM

                        // Count large display
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: 80

                            StyledText {
                                text: root.selectedDay ? root.selectedDay.count : "0"
                                font.pixelSize: 32
                                font.bold: true
                                color: Theme.surfaceText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: "contributions"
                                font.pixelSize: 10
                                color: Theme.surfaceVariantText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        // Vertical separator
                        Rectangle {
                            height: parent.height - Theme.spacingS
                            width: 1
                            color: Theme.outlineVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Date and day info
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Row {
                                spacing: Theme.spacingS
                                DankIcon {
                                    name: root.iconBar
                                    size: 16
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    text: root.selectedDay ? root.selectedDay.weekdayName : ""
                                    font.bold: true
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                }
                            }

                            StyledText {
                                text: {
                                    if (!root.selectedDay) return ""
                                    if (root.selectedDay === root.todayDay) return "Today"
                                    if (root.selectedDay === root.yesterdayDay) return "Yesterday"
                                    return root.selectedDay.date
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }
            }
        }
    }

    // Single global tooltip instance for the plugin
    DankTooltipV2 {
        id: tooltip
    }
}
