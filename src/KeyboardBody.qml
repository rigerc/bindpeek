// SPDX-FileCopyrightText: 2026 rigerc
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick

// Keyboard representation of the unfiltered Bindpeek model. Each physical key
// remains a QML item, so modifier filtering and descriptions update live.
Item {
    id: root
    required property QtObject theme
    property var bindings: []
    property var held: []
    readonly property int gap: Math.max(3, Math.round(unit * 0.09))
    readonly property int unit: Math.floor(Math.max(28, Math.min(58,
                           (theme.screenWidth - 80) / 24,
                           (theme.screenHeight - 190) / 8)))
    readonly property int padding: Math.round(unit * 0.34)
    implicitWidth: content.implicitWidth + 2 * padding
    implicitHeight: content.implicitHeight + 2 * padding
    focus: true
    onVisibleChanged: if (visible) forceActiveFocus()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            OverlayController.closeKeyboard()
            event.accepted = true
        }
    }

    function k(label, code, width, mod) {
        return { label: label, code: code, units: width || 1, modifier: mod || "" }
    }

    // ISO-style alphanumeric block, navigation block and numeric keypad.
    // Widths are key units; no bitmap is used, so every key remains reactive.
    readonly property var mainRows: [
        [k("Esc","ESCAPE"), k("F1","F1"), k("F2","F2"), k("F3","F3"),
         k("F4","F4"), k("F5","F5"), k("F6","F6"), k("F7","F7"),
         k("F8","F8"), k("F9","F9"), k("F10","F10"), k("F11","F11"),
         k("F12","F12"), k("Prt","PRINT"), k("Del","DELETE")],
        [k("`","BACKTICK"), k("1","1"), k("2","2"), k("3","3"), k("4","4"),
         k("5","5"), k("6","6"), k("7","7"), k("8","8"), k("9","9"),
         k("0","0"), k("-","-"), k("=","="), k("Backspace","BACKSPACE",2)],
        [k("Tab","TAB",1.5), k("Q","Q"), k("W","W"), k("E","E"), k("R","R"),
         k("T","T"), k("Y","Y"), k("U","U"), k("I","I"), k("O","O"),
         k("P","P"), k("[","["), k("]","]"), k("\\","\\",1.5)],
        [k("Caps","CAPSLOCK",1.75), k("A","A"), k("S","S"), k("D","D"),
         k("F","F"), k("G","G"), k("H","H"), k("J","J"), k("K","K"),
         k("L","L"), k(";",";"), k("'","'"), k("Enter","ENTER",2.25)],
        [k("Shift","SHIFT",2,"SHIFT"), k("<","102ND",1), k("Z","Z"),
         k("X","X"), k("C","C"), k("V","V"), k("B","B"), k("N","N"),
         k("M","M"), k(",",","), k(".","."), k("/","/"),
         k("Shift","SHIFT",2,"SHIFT")],
        [k("Ctrl","CTRL",1.3,"CTRL"), k("Super","SUPER",1.3,"SUPER"),
         k("Alt","ALT",1.3,"ALT"), k("Space","SPACE",5.2),
         k("Alt","ALT",1.3,"ALT"), k("Super","SUPER",1.3,"SUPER"),
         k("Menu","MENU",1.2), k("Ctrl","CTRL",1.3,"CTRL")]
    ]
    readonly property var navRows: [
        [k("Ins","INSERT"), k("Home","HOME"), k("PgUp","PAGEUP")],
        [k("Del","DELETE"), k("End","END"), k("PgDn","PAGEDOWN")],
        [k("","",""), k("","",""), k("","","")],
        [k("","",""), k("↑","UP"), k("","","")],
        [k("←","LEFT"), k("↓","DOWN"), k("→","RIGHT")]
    ]
    readonly property var padRows: [
        [k("Num","NUMLOCK"), k("/","KPSLASH"), k("*","KPASTERISK"), k("-","KPMINUS")],
        [k("7","KP7"), k("8","KP8"), k("9","KP9"), k("+","KPPLUS")],
        [k("4","KP4"), k("5","KP5"), k("6","KP6"), k("+","KPPLUS")],
        [k("1","KP1"), k("2","KP2"), k("3","KP3"), k("Enter","KPENTER")],
        [k("0","KP0",2), k(".","KPDOT"), k("Enter","KPENTER")]
    ]

    function canonical(value) {
        var name = String(value).toUpperCase()
        if (name.length === 1)
            return name
        name = name.replace(/[ _-]/g, "")
        var aliases = {
            "ESC": "ESCAPE", "RETURN": "ENTER", "SPACEBAR": "SPACE",
            "GRAVE": "BACKTICK", "ASCIITILDE": "BACKTICK",
            "BRACKETLEFT": "[", "BRACKETRIGHT": "]",
            "BACKSLASH": "\\", "SEMICOLON": ";", "APOSTROPHE": "'",
            "COMMA": ",", "PERIOD": ".", "DOT": ".", "SLASH": "/",
            "MINUS": "-", "EQUAL": "=", "EQUALS": "=",
            "PAGEUP": "PAGEUP", "PRIOR": "PAGEUP", "NEXT": "PAGEDOWN",
            "PRINTSCREEN": "PRINT", "SYSRQ": "PRINT",
            "KPDECIMAL": "KPDOT", "KPDELETE": "KPDOT",
            "KPADD": "KPPLUS", "KPSUBTRACT": "KPMINUS",
            "KPMULTIPLY": "KPASTERISK", "KPDIVIDE": "KPSLASH",
            "ISOLEFTTAB": "TAB", "LESS": "102ND"
        }
        return aliases[name] || name
    }

    function isReachable(bind) {
        for (var i = 0; i < held.length; ++i) {
            if (bind.modifiers.indexOf(held[i]) === -1)
                return false
        }
        return true
    }

    function forKey(code) {
        var matches = []
        for (var i = 0; i < bindings.length; ++i) {
            var bind = bindings[i]
            if (canonical(bind.key) === canonical(code) && isReachable(bind))
                matches.push(bind)
        }
        return matches
    }

    readonly property var unplaced: {
        var codes = []
        var allRows = mainRows.concat(navRows).concat(padRows)
        for (var row of allRows)
            for (var key of row)
                codes.push(canonical(key.code))
        var extra = []
        for (var bind of bindings)
            if (isReachable(bind) && codes.indexOf(canonical(bind.key)) === -1)
                extra.push(bind)
        return extra
    }
    readonly property int availableCount: {
        var count = 0
        for (var bind of bindings)
            if (isReachable(bind))
                ++count
        return count
    }

    Rectangle {
        anchors.fill: parent
        radius: theme.radiusPanel
        color: theme.background
        opacity: theme.panelOpacity
    }
    Rectangle {
        anchors.fill: parent
        radius: theme.radiusPanel
        color: "transparent"
        border.color: theme.border
        border.width: theme.borderWidth
    }

    Column {
        id: content
        anchors.centerIn: parent
        spacing: root.gap * 2

        Row {
            spacing: root.unit * 0.45
            Text {
                text: "BINDPEEK  /  KEYBOARD"
                color: root.theme.text
                font.family: root.theme.fontFamilyMono
                font.bold: true
                font.pixelSize: Math.max(12, root.unit * 0.28)
            }
            Text {
                text: root.held.length ? root.held.join(" + ") : "All modifiers"
                color: root.theme.accent
                font.family: root.theme.fontFamilyMono
                font.pixelSize: Math.max(11, root.unit * 0.24)
            }
            Text {
                text: root.availableCount + " shortcuts"
                color: root.theme.textMuted
                font.family: root.theme.fontFamilyMono
                font.pixelSize: Math.max(10, root.unit * 0.22)
            }
        }

        Row {
            id: board
            spacing: root.gap * 3
            // Repeated per-key delegates keep descriptions and border styling
            // synchronized with the held modifier model.
            Repeater {
                model: [root.mainRows, root.navRows, root.padRows]
                delegate: Column {
                    required property var modelData
                    spacing: root.gap
                    Repeater {
                        model: modelData
                        delegate: Row {
                            required property var modelData
                            spacing: root.gap
                            Repeater {
                                model: modelData
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property var info: modelData
                                    readonly property var active: root.forKey(info.code)
                                    readonly property bool heldKey: info.modifier !== ""
                                                && root.held.indexOf(info.modifier) !== -1
                                    readonly property bool exact: active.some(
                                                item => item.modifiers.length === root.held.length)
                                    readonly property bool blank: info.code === ""
                                    width: root.unit * (info.units || 1)
                                           + root.gap * ((info.units || 1) - 1)
                                    height: root.unit
                                    radius: Math.max(4, root.unit * 0.12)
                                    color: blank ? "transparent"
                                           : active.length || heldKey ? root.theme.surfaceHover
                                           : root.theme.surface
                                    border.width: blank ? 0 : active.length || heldKey ? 2 : 1
                                    border.color: heldKey ? root.theme.accent
                                                : exact ? root.theme.brand
                                                : active.length ? root.theme.accent
                                                : root.theme.border
                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: Math.max(3, root.unit * 0.10)
                                        spacing: root.gap / 2
                                        visible: !blank
                                        Text {
                                            width: parent.width
                                            text: info.label
                                            elide: Text.ElideRight
                                            color: heldKey ? root.theme.accent : root.theme.text
                                            font.family: root.theme.fontFamilyMono
                                            font.bold: active.length > 0
                                            font.pixelSize: Math.max(9, root.unit * 0.25)
                                        }
                                        Text {
                                            width: parent.width
                                            text: active.length === 0 ? ""
                                                  : active[0].description
                                                    + (active.length > 1 ? " +" + (active.length - 1) : "")
                                            elide: Text.ElideRight
                                            color: exact ? root.theme.brand : root.theme.textMuted
                                            font.family: root.theme.fontFamily
                                            font.pixelSize: Math.max(8, root.unit * 0.17)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            width: board.implicitWidth
            visible: root.unplaced.length > 0
            text: "Other: " + root.unplaced.map(item => item.shortcut
                              + "  " + item.description).join("   •   ")
            elide: Text.ElideRight
            color: root.theme.textMuted
            font.family: root.theme.fontFamily
            font.pixelSize: Math.max(10, root.unit * 0.20)
        }
        Text {
            width: board.implicitWidth
            text: "Hold Super / Ctrl / Alt / Shift to filter   •   Esc or click to close"
            color: root.theme.textMuted
            font.family: root.theme.fontFamily
            font.pixelSize: Math.max(10, root.unit * 0.22)
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: OverlayController.closeKeyboard()
    }
}
