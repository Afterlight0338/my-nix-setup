// Keybind cheat sheet, toggled by hl.dsp.global("cheatsheet:toggle") (Super + /).
// Binds are read from ~/.config/hypr/variables.lua (+ overrides in ~/.config/caelestia/hypr-vars.lua),
// grouped by the "-- Header" comments there. Colours follow the current caelestia scheme.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "search.js" as Search

ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property var c: ({})
    property var groups: []

    // Rice Settings page (backend: ~/.local/bin/rice-settings, which owns the list of settings)
    property string mode: "keys" // keys | settings
    property string tab: "simple" // simple | advanced
    property var settings: []
    property string settingsError: ""
    property bool peek: false // a slider is being dragged: fade the card so the desktop shows through
    readonly property string backend: home + "/.local/bin/rice-settings"
    readonly property var sections: {
        const out = [];
        for (const s of settings.filter(s => s.tab === tab)) {
            let sec = out.find(x => x.name === s.section);
            if (!sec)
                out.push(sec = { name: s.section, items: [] });
            sec.items.push(s);
        }
        return out;
    }

    function refreshSettings() {
        getProc.running = true;
    }

    function setSetting(key, value) {
        settingsError = "";
        setProc.command = [backend, "set", key, String(value)];
        setProc.running = true;
    }

    function open(m) {
        if (!win.visible)
            win.screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null;
        mode = m;
        win.visible = true;
        search.text = "";
        flick.contentY = 0;
        settingsFlick.contentY = 0;
        if (m === "settings")
            refreshSettings();
        else
            search.forceActiveFocus();
    }

    // Binds hardcoded in ~/.config/hypr/hyprland/keybinds.lua and hypr-user.lua
    readonly property var extra: [
        { label: "Focus window", keys: [["Super", "Arrows"]] },
        { label: "Move window", keys: [["Super", "Shift", "Arrows"]] },
        { label: "Drag / resize window", keys: [["Super", "LMB"], ["Super", "RMB"]] },
        { label: "Kill shell", keys: [["Ctrl", "Super", "Shift", "R"]] },
        { label: "Restart shell", keys: [["Ctrl", "Super", "Alt", "R"]] },
        { label: "Show bar for 60s / hide it", keys: [["Super", "B"]] },
        { label: "Toggle game mode", keys: [["Super", "G"]] },
        { label: "Toggle questionable wallpapers", keys: [["Super", "Shift", "W"]] },
        { label: "This cheat sheet", keys: [["Super", "/"]] },
        { label: "Rice settings", keys: [["Super", "Shift", "/"]] },
        { label: "Do Not Disturb", keys: [["Super", "Shift", "N"]] }
    ]

    // Caelestia launcher commands: tap Super, then type these. Defaults from the caelestia-qml-plugin
    // config (launcher.actions); Shutdown/Reboot/Logout only show with launcher.enableDangerousActions.
    readonly property var launcherCmds: [
        { label: "Calculator (Qalc)", keys: [[">calc 2+2"]] },
        { label: "Wallpaper carousel", keys: [[">wallpaper"]] },
        { label: "Random wallpaper", keys: [[">random"]] },
        { label: "Change colour scheme", keys: [[">scheme"]] },
        { label: "Change scheme variant", keys: [[">variant"]] },
        { label: "Light / dark mode", keys: [[">light"], [">dark"]] },
        { label: "Lock session", keys: [[">lock"]] },
        { label: "Sleep (suspend then hibernate)", keys: [[">sleep"]] },
        { label: "Shell settings (Nexus)", keys: [[">settings"]] },
        { label: "Shutdown / reboot / logout", keys: [[">shutdown"], [">reboot"], [">logout"]] },
        { label: "Search apps by category", keys: [["@c games"]] },
        { label: "Search apps by description", keys: [["@d"]] },
        { label: "Search apps by command", keys: [["@e"]] },
        { label: "Search apps by keywords", keys: [["@k"]] }
    ]

    // Commands to type in a terminal (scripts in ~/.local/bin)
    readonly property var terminalCmds: [
        { label: "Fastfetch grimoire in English (saved)", keys: [["fastfetch-en"]] },
        { label: "Fastfetch grimoire in Japanese (saved)", keys: [["fastfetch-jp"]] }
    ]

    readonly property var keyNames: ({
        SUPER: "Super", SUPER_L: "Super", CTRL: "Ctrl", ALT: "Alt", SHIFT: "Shift", TAB: "Tab",
        mouse_down: "Scroll ↓", mouse_up: "Scroll ↑", "mouse:272": "LMB", "mouse:273": "RMB", "mouse:274": "MMB",
        Return: "Enter", Backslash: "\\", Comma: ",", Period: ".", Minus: "-", Equal: "=", Slash: "/",
        Page_Up: "PgUp", Page_Down: "PgDn", Up: "↑", Down: "↓", Left: "←", Right: "→",
        Escape: "Esc", Backspace: "Bksp", Delete: "Del"
    })
    readonly property var words: ({
        win: "window", ws: "workspace", mon: "monitor", notifs: "notifications", prev: "previous", pip: "picture-in-picture"
    })
    readonly property var mods: ["SUPER", "CTRL", "ALT", "SHIFT"]

    function col(name, fallback) {
        return c[name] ? "#" + c[name] : fallback;
    }

    // Same colour with alpha: clear glass like kitty/Dolphin (no blur)
    function colA(name, fallback, a) {
        const k = Qt.darker(col(name, fallback), 1);
        return Qt.rgba(k.r, k.g, k.b, a);
    }

    function label(name) {
        const s = name.replace(/([a-z])([A-Z])/g, "$1 $2").toLowerCase().split(" ").map(w => words[w] ?? w).join(" ");
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    function combo(raw) {
        const parts = raw.split("+").map(p => p.trim());
        if (parts.every(p => mods.includes(p)))
            parts.push("0-9"); // modifier-only binds are used as mod + workspace number
        return [...new Set(parts.map(p => keyNames[p] ?? p))];
    }

    // keyboard combos are listed before mouse ones
    function isMouse(keys) {
        return keys.some(k => k.startsWith("Scroll") || k.endsWith("MB"));
    }

    // Returns [[groupName, [[kbName, [combos]]...]]...] from a variables.lua-style file
    function parse(text) {
        const out = [];
        let group = "Workspaces", started = false;
        for (const line of text.split("\n")) {
            if (line.includes("KEYBINDS"))
                started = true;
            if (!started)
                continue;
            const h = line.match(/^\s*--\s*([^.-][^.]*)$/);
            if (h) {
                group = h[1].trim();
                continue;
            }
            const m = line.match(/^\s*(kb\w+)\s*=\s*(.*)$/);
            if (m)
                out.push([group, m[1], (m[2].match(/"[^"]*"/g) ?? []).map(s => s.slice(1, -1))]);
        }
        return out;
    }

    function rebuild() {
        if (!varsFile.loaded)
            return;
        const overrides = {};
        if (overridesFile.loaded)
            for (const [, name, binds] of parseOverrides(overridesFile.text()))
                overrides[name] = binds;

        const byGroup = new Map();
        for (const [group, name, binds] of parse(varsFile.text())) {
            if (!byGroup.has(group))
                byGroup.set(group, []);
            const keys = (overrides[name] ?? binds).map(combo);
            byGroup.get(group).push({ label: label(name.slice(2)), keys: keys.filter(k => !isMouse(k)).concat(keys.filter(isMouse)) });
        }
        byGroup.set("Other", extra);
        byGroup.set("Launcher commands (tap Super, then type)", launcherCmds);
        byGroup.set("Terminal commands", terminalCmds);
        groups = [...byGroup].map(([name, items]) => ({ name, items }));
    }

    // hypr-vars.lua has no KEYBINDS marker or headers, just name = value lines
    function parseOverrides(text) {
        return parse("KEYBINDS\n" + text);
    }

    FileView {
        id: varsFile
        path: root.home + "/.config/hypr/variables.lua"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.rebuild()
    }

    FileView {
        id: overridesFile
        path: root.home + "/.config/caelestia/hypr-vars.lua"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.rebuild()
    }

    FileView {
        path: root.home + "/.local/state/caelestia/scheme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.c = JSON.parse(text()).colours ?? {}
    }

    GlobalShortcut {
        appid: "cheatsheet"
        name: "toggle"
        description: "Toggle keybind cheat sheet"
        onPressed: win.visible && root.mode === "keys" ? win.visible = false : root.open("keys")
    }

    GlobalShortcut {
        appid: "cheatsheet"
        name: "settings"
        description: "Toggle rice settings"
        onPressed: win.visible && root.mode === "settings" ? win.visible = false : root.open("settings")
    }

    Process {
        id: getProc
        command: [root.backend, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.settings = JSON.parse(text);
                } catch (e) {
                    root.settingsError = "Couldn't read settings: " + e;
                }
            }
        }
    }

    Process {
        id: setProc
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.settingsError = text.trim()
        }
        onExited: root.refreshSettings()
    }

    // Header pill button
    component Pill: Rectangle {
        id: pill
        property string text
        property bool active: false
        signal clicked
        implicitWidth: pillText.implicitWidth + 32
        implicitHeight: 36
        radius: 18
        color: active ? root.col("primary", "#6687c7") : pillMouse.containsMouse ? root.col("surfaceContainerHighest", "#303548") : root.col("surfaceContainerHigh", "#2a2f40")

        Text {
            id: pillText
            anchors.centerIn: parent
            text: pill.text
            font.pixelSize: 14
            font.weight: Font.Medium
            color: pill.active ? root.col("onPrimary", "#171a24") : root.col("onSurface", "#e7e5e0")
        }

        MouseArea {
            id: pillMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }

    // One setting's control, picked by its type
    component SettingControl: Item {
        id: ctl
        required property var spec
        implicitWidth: 190
        implicitHeight: 30

        // bool: switch
        Rectangle {
            visible: ctl.spec.type === "bool"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 24
            radius: 12
            color: ctl.spec.value ? root.col("primary", "#6687c7") : root.col("surfaceContainerHighest", "#303548")

            Rectangle {
                width: 18
                height: 18
                radius: 9
                anchors.verticalCenter: parent.verticalCenter
                x: ctl.spec.value ? parent.width - width - 3 : 3
                color: ctl.spec.value ? root.col("onPrimary", "#171a24") : root.col("outline", "#46516b")
                Behavior on x { NumberAnimation { duration: 120 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setSetting(ctl.spec.key, !ctl.spec.value)
            }
        }

        // choice: segmented pills
        Row {
            visible: ctl.spec.type === "choice"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: ctl.spec.type === "choice" ? ctl.spec.options : []

                Rectangle {
                    required property var modelData
                    readonly property bool on: ctl.spec.value === modelData[0]
                    width: optText.implicitWidth + 18
                    height: 26
                    radius: 13
                    color: on ? root.col("primary", "#6687c7") : root.col("surfaceContainerHighest", "#303548")

                    Text {
                        id: optText
                        anchors.centerIn: parent
                        text: parent.modelData[1]
                        font.pixelSize: 12
                        color: parent.on ? root.col("onPrimary", "#171a24") : root.col("onSurface", "#e7e5e0")
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setSetting(ctl.spec.key, parent.modelData[0])
                    }
                }
            }
        }

        // int / slider: drag, value applied on release
        Item {
            id: sl
            visible: ctl.spec.type === "int" || ctl.spec.type === "slider"
            anchors.fill: parent
            readonly property real min: ctl.spec.min ?? 0
            readonly property real max: ctl.spec.max ?? 1
            readonly property real step: ctl.spec.step ?? 1
            property real shown: ctl.spec.value ?? min
            property bool dragging: false
            onDraggingChanged: root.peek = dragging
            property real sent: NaN
            // While dragging, send the newest value every 120 ms (skipped while the previous set still runs)
            Timer {
                interval: 120
                repeat: true
                running: sl.dragging
                onTriggered: if (!setProc.running && sl.shown !== sl.sent) { sl.sent = sl.shown; root.setSetting(ctl.spec.key, sl.shown); }
            }
            Connections {
                target: ctl
                function onSpecChanged() { if (!sl.dragging) sl.shown = ctl.spec.value ?? sl.min; }
            }

            Text {
                id: slValue
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                horizontalAlignment: Text.AlignRight
                text: (sl.step < 1 ? sl.shown.toFixed(2) : Math.round(sl.shown)) + (ctl.spec.unit ?? "")
                font.family: "JetBrainsMono NF"
                font.pixelSize: 12
                color: root.col("onSurface", "#e7e5e0")
            }

            Rectangle {
                id: track
                anchors.right: slValue.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 130
                height: 6
                radius: 3
                color: root.col("surfaceContainerHighest", "#303548")

                Rectangle {
                    width: parent.width * (sl.shown - sl.min) / (sl.max - sl.min)
                    height: parent.height
                    radius: 3
                    color: root.col("primary", "#6687c7")
                }

                Rectangle {
                    x: parent.width * (sl.shown - sl.min) / (sl.max - sl.min) - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    radius: 8
                    color: root.col("primary", "#6687c7")
                    border.color: root.col("onPrimary", "#171a24")
                    border.width: 2
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    cursorShape: Qt.PointingHandCursor
                    function pick(mx) {
                        const f = Math.max(0, Math.min(1, (mx - 10) / track.width));
                        const v = sl.min + Math.round(f * (sl.max - sl.min) / sl.step) * sl.step;
                        sl.shown = Math.round(v * 100) / 100;
                    }
                    onPressed: mouse => { sl.sent = ctl.spec.value; sl.dragging = true; pick(mouse.x); }
                    onPositionChanged: mouse => pick(mouse.x)
                    onReleased: { sl.dragging = false; if (sl.shown !== ctl.spec.value) root.setSetting(ctl.spec.key, sl.shown); }
                }
            }
        }

        // text: applied on Enter or when focus leaves
        Rectangle {
            visible: ctl.spec.type === "text" || ctl.spec.type === "time"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 170
            height: 28
            radius: 8
            color: root.col("surfaceContainerHighest", "#303548")
            border.color: textIn.activeFocus ? root.col("primary", "#6687c7") : "transparent"

            TextInput {
                id: textIn
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                text: ctl.spec.type === "text" || ctl.spec.type === "time" ? ctl.spec.value : ""
                font.family: "JetBrainsMono NF"
                font.pixelSize: 12
                color: root.col("onSurface", "#e7e5e0")
                selectionColor: root.col("primary", "#6687c7")
                clip: true
                onEditingFinished: if (text !== ctl.spec.value) root.setSetting(ctl.spec.key, text)
                Keys.onEscapePressed: { text = ctl.spec.value; focus = false; }
            }
        }
    }

    // One action's combos, one per line, right-aligned
    component Combos: Column {
        required property var keys
        spacing: 3

        Repeater {
            model: keys

            Row {
                required property var modelData
                anchors.right: parent.right
                spacing: 3

                Repeater {
                    model: modelData

                    Rectangle {
                        required property string modelData
                        width: Math.max(keyText.implicitWidth + 12, 22)
                        height: 22
                        radius: 6
                        color: root.col("surfaceContainerHighest", "#303548")

                        Text {
                            id: keyText
                            anchors.centerIn: parent
                            text: parent.modelData
                            font.family: "JetBrainsMono NF"
                            font.pixelSize: 11
                            color: root.col("onSurface", "#e7e5e0")
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: win

        readonly property var result: Search.filter(root.groups, search.text)

        visible: false
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "cheatsheet"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Rectangle {
            anchors.fill: parent
            color: "transparent" // no dim: see the desktop react live

            MouseArea {
                anchors.fill: parent
                onClicked: win.visible = false
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 1840)
                height: parent.height - 80 // fixed so the card doesn't jump while filtering
                radius: 24
                // Glass like kitty (0.65). Hyprland blurs it only at alpha >= 0.3 (hypr-user.lua), so while a
                // slider is dragged the card drops to 0.2 and the desktop behind shows sharp and live
                color: root.colA("surfaceContainer", "#232735", root.peek ? 0.2 : 0.65)
                Behavior on color { ColorAnimation { duration: 150 } }
                border.color: root.col("outlineVariant", "#303548")

                MouseArea { anchors.fill: parent } // swallow clicks so they don't close the sheet

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 32
                    spacing: 20

                    RowLayout {
                        spacing: 24

                        Text {
                            text: root.mode === "keys" ? "Keybinds" : "Settings"
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            color: root.col("onSurface", "#e7e5e0")
                        }

                        Rectangle {
                            visible: root.mode === "keys"
                            Layout.preferredWidth: 420
                            Layout.preferredHeight: 40
                            radius: 20
                            color: root.col("surfaceContainerHigh", "#2a2f40")
                            border.color: search.activeFocus ? root.col("primary", "#6687c7") : "transparent"

                            TextInput {
                                id: search
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 18
                                verticalAlignment: TextInput.AlignVCenter
                                font.pixelSize: 15
                                color: root.col("onSurface", "#e7e5e0")
                                selectionColor: root.col("primary", "#6687c7")
                                clip: true
                                onTextChanged: flick.contentY = 0
                                Keys.onEscapePressed: text ? text = "" : win.visible = false

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !parent.text
                                    text: "Search binds… (resize, screenshot, volume)"
                                    font: parent.font
                                    color: root.col("outline", "#46516b")
                                }
                            }
                        }

                        Pill {
                            visible: root.mode === "settings"
                            text: "Simple"
                            active: root.tab === "simple"
                            onClicked: { root.tab = "simple"; settingsFlick.contentY = 0; }
                        }

                        Pill {
                            visible: root.mode === "settings"
                            text: "Advanced"
                            active: root.tab === "advanced"
                            onClicked: { root.tab = "advanced"; settingsFlick.contentY = 0; }
                        }

                        Text {
                            visible: root.mode === "settings" && !!root.settingsError
                            Layout.maximumWidth: 600
                            text: root.settingsError
                            elide: Text.ElideRight
                            font.pixelSize: 13
                            color: root.col("error", "#c46a6a")
                        }

                        Item { Layout.fillWidth: true }

                        Pill {
                            text: root.mode === "keys" ? "⚙  Settings" : "⌨  Keybinds"
                            onClicked: root.open(root.mode === "keys" ? "settings" : "keys")
                        }
                    }

                    // Esc closes the settings page (the keybind page handles Esc in its search box)
                    Shortcut {
                        enabled: win.visible && root.mode === "settings"
                        sequence: "Escape"
                        onActivated: win.visible = false
                    }

                    Rectangle {
                        visible: root.mode === "keys" && !!win.result.best
                        Layout.preferredWidth: 420 * 2 + 22
                        Layout.preferredHeight: bestRow.implicitHeight + 28
                        radius: 16
                        color: root.col("primaryContainer", "#405b91")

                        RowLayout {
                            id: bestRow
                            anchors.fill: parent
                            anchors.margins: 14
                            anchors.leftMargin: 20
                            spacing: 16

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Probably what you're looking for · " + (win.result.best?.group ?? "")
                                    font.pixelSize: 11
                                    color: root.col("onPrimaryContainer", "#e7e5e0")
                                    opacity: 0.75
                                }

                                Text {
                                    text: win.result.best?.item.label ?? ""
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                    color: root.col("onPrimaryContainer", "#e7e5e0")
                                }
                            }

                            Combos {
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                keys: win.result.best?.item.keys ?? []
                            }
                        }
                    }

                    Text {
                        visible: root.mode === "keys" && search.text && !win.result.best
                        text: "No binds match \"" + search.text + "\""
                        font.pixelSize: 14
                        color: root.col("onSurfaceVariant", "#a9a9b5")
                    }

                    Flickable {
                        id: flick
                        visible: root.mode === "keys"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: grid.implicitHeight
                        clip: true

                        Flow {
                            id: grid
                            width: parent.width
                            spacing: 22

                            Repeater {
                                model: win.result.groups

                                ColumnLayout {
                                    required property var modelData
                                    width: 420
                                    spacing: 8

                                    Text {
                                        text: modelData.name
                                        font.pixelSize: 15
                                        font.weight: Font.DemiBold
                                        color: root.col("primary", "#6687c7")
                                        Layout.bottomMargin: 2
                                    }

                                    Repeater {
                                        model: modelData.items

                                        RowLayout {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            spacing: 12

                                            Text {
                                                Layout.fillWidth: true
                                                Layout.alignment: Qt.AlignTop
                                                Layout.topMargin: 3
                                                text: modelData.label
                                                elide: Text.ElideRight
                                                font.pixelSize: 13
                                                color: root.col("onSurfaceVariant", "#a9a9b5")
                                            }

                                            Combos {
                                                keys: modelData.keys
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Flickable {
                        id: settingsFlick
                        visible: root.mode === "settings"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: settingsGrid.implicitHeight
                        clip: true

                        Flow {
                            id: settingsGrid
                            width: parent.width
                            spacing: 22

                            Repeater {
                                model: root.sections

                                Rectangle {
                                    required property var modelData
                                    width: 420
                                    height: secCol.implicitHeight + 32
                                    radius: 16
                                    color: root.colA("surfaceContainerHigh", "#2a2f40", root.peek ? 0.05 : 0.3)
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    ColumnLayout {
                                        id: secCol
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 16
                                        spacing: 10

                                        Text {
                                            text: modelData.name
                                            font.pixelSize: 15
                                            font.weight: Font.DemiBold
                                            color: root.col("primary", "#6687c7")
                                        }

                                        Repeater {
                                            model: modelData.items

                                            RowLayout {
                                                required property var modelData
                                                Layout.fillWidth: true
                                                spacing: 12

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.label
                                                    wrapMode: Text.WordWrap
                                                    font.pixelSize: 13
                                                    color: root.col("onSurfaceVariant", "#a9a9b5")
                                                }

                                                SettingControl {
                                                    spec: modelData
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
