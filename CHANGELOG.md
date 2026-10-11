# Changelog

All notable changes to the **GitHub Heatmap Revive** plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.1.0] - 2026-10-11

### Added
- **Segmented Settings UI**: Redesigned `HeatMapSettings.qml` with a modern segmented card layout, categorized preference groups (`outerR` & `innerR` radius tokens), icon badges, and smooth animations.
- **Native DMS Controls**: Adopted `DankDropdown` across all settings selector inputs for seamless integration with DMS themes and popups.
- **Explicit Runtime Dependencies**: Declared `bash`, `curl`, `jq`, `coreutils`, `libnotify`, and `xdg-utils` in `plugin.json` for package managers and plugin registry manifests.
- **Automated Release Workflow**: Added GitHub Actions workflow (`.github/release.yml`) to automatically package `.tar.gz` release archives and draft GitHub releases on version bumps.
- **Privacy & Host Disclosure**: Added explicit third-party API data source disclosure (`github-contributions-api.jogruber.de`) in `README.md`.

### Fixed
- **Date Formatting Bug**: Fixed an issue where hovering over days in the graph displayed unparsed formula syntax `($p[2] | pad2) / ...` due to unescaped JavaScript template interpolation.
- **Background Resource Usage**: Eliminated ~2,500 sub-process spawns (`jq` and GNU `date` per day) every 5-minute refresh by consolidating parsing into a single-pass `jq` pipeline (~10ms execution).
- **Theme Color Tokens**: Replaced hardcoded `#ffffff` on action buttons with `Theme.primaryText`, and replaced fixed font sizes (32, 22, 10) with `Theme.fontSize*` and `Theme` geometry tokens.

---

## [2.0.0] - 2026-07-17

### Added
- **Desktop Widget Support**: Introduced `DesktopWidget.qml` as a companion desktop widget component alongside the bar widget.
- **Composite Plugin Architecture**: Updated plugin type to `composite` with both `dankbar-widget` and `desktop-widget` capabilities.
- **Dedicated Desktop Settings**: Added instance configuration for desktop card opacity, square sizing, cell spacing, and display modes.

---

## [1.2.3] - 2026-06-28

### Changed
- Standardized animation durations and easings across the UI.
- Enabled asynchronous loading for popout components to improve bar responsiveness.
- Enhanced visual feedback and borders when hovering/selecting active days.

---

## [1.2.2] - 2026-05-31

### Added
- Relative day labels (`Today` / `Yesterday`) for quick streak tracking.

### Changed
- Removed graphical drop shadows for a cleaner, flatter Material design aesthetic.

---

## [1.2.0] - 2026-04-12

### Added
- Interactive tooltips on hover displaying exact date and contribution count.
- Notification options for background fetch status and sync failures.
- Renamed plugin identifier to `githubHeatmapRevive`.
- Modernized settings interface.

---

## [1.0.0] - 2026-04-12

### Added
- Initial revived release for Dank Material Shell.
- 7-day pill preview for Dank Bar.
- Popout contribution calendar with dark GitHub contribution palette and DMS theme following support.
