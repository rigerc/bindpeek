// SPDX-FileCopyrightText: 2026 rigerc
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import "ShortcutPresentation.js" as Shortcuts

// Shared physical keycaps: used by the full keyboard and both compact views.
// Bind data is never fabricated. Each key highlights if the actual compositor
// source lists an action reachable with the currently held modifiers.
Item {
    id: root
    required property QtObject theme
    property var bindings: []
    property var held: []
    property bool compact: false
    property bool showDescriptions: !compact
    property int unit: 36
    property int gap: Math.max(2, Math.round(unit * 0.09))
    implicitWidth: board.implicitWidth
    implicitHeight: board.implicitHeight

    function k(label, code, width, mod) {
        return {label: label, code: code, units: width || 1, modifier: mod || ""}
    }

    readonly property var mainRows: [
        [k("Esc","ESCAPE"), k("F1","F1"), k("F2","F2"), k("F3","F3"),
         k("F4","F4"), k("F5","F5"), k("F6","F6"), k("F7","F7"),
         k("F8","F8"), k("F9","F9"), k("F10","F10"), k("F11","F11"),
         k("F12","F12"), k("Prt","PRINT"), k("Del","DELETE")],
        [k("\x60","BACKTICK"), k("1","1"), k("2","2"), k("3","3"), k("4","4"),
         k("5","5"), k("6","6"), k("7","7"), k("8","8"), k("9","9"),
         k("0","0"), k("-","-"), k("=","="), k("Backspace","BACKSPACE",2)],
        [k("Tab","TAB",1.5), k("Q","Q"), k("W","W"), k("E","E"), k("R","R"),
         k("T","T"), k("Y","Y"), k("U","U"), k("I","I"), k("O","O"),
         k("P","P"), k("[","["), k("]","]"), k("\\","\\",1.5)],
        [k("Caps","CAPSLOCK",1.75), k("A","A"), k("S","S"), k("D","D"),
         k("F","F"), k("G","G"), k("H","H"), k("J","J"), k("K","K"),
         k("L","L"), k(";",";"), k("'","'"), k("Enter","ENTER",2.25)],
        [k("Shift","SHIFT",2,"SHIFT"), k("<","102ND"), k("Z","Z"),
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

    function forKey(code) {
        var matches = []
        for (var i = 0; i < bindings.length; ++i) {
            var bind = bindings[i]
            if (Shortcuts.canonical(bind.key) === Shortcuts.canonical(code)
                    && Shortcuts.reachable(bind, held))
                matches.push(bind)
        }
        return matches
    }

    readonly property int availableCount: Shortcuts.ordered(bindings, held).length
    readonly property var unplaced: {
        var codes = []
        var rows = mainRows.concat(navRows).concat(padRows)
        for (var i = 0; i < rows.length; ++i)
            for (var j = 0; j < rows[i].length; ++j)
                codes.push(Shortcuts.canonical(rows[i][j].code))
        var extra = []
        var active = Shortcuts.ordered(bindings, held)
        for (var n = 0; n < active.length; ++n)
            if (codes.indexOf(Shortcuts.canonical(active[n].key)) === -1)
                extra.push(active[n])
        return extra
    }

    Row {
        id: board
        spacing: root.gap * (root.compact ? 1 : 3)
        Repeater {
            model: root.compact ? [root.mainRows]
                                : [root.mainRows, root.navRows, root.padRows]
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
                                radius: Math.max(3, root.unit * 0.12)
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
                                    anchors.margins: Math.max(2, root.unit * 0.08)
                                    spacing: Math.max(1, root.gap / 2)
                                    visible: !blank
                                    Text {
                                        width: parent.width
                                        text: info.label
                                        elide: Text.ElideRight
                                        horizontalAlignment: root.compact ? Text.AlignHCenter : Text.AlignLeft
                                        color: heldKey ? root.theme.accent : root.theme.text
                                        font.family: root.theme.fontFamilyMono
                                        font.bold: active.length > 0
                                        font.pixelSize: Math.max(8, root.unit * (root.compact ? 0.34 : 0.25))
                                    }
                                    Text {
                                        width: parent.width
                                        visible: root.showDescriptions
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
}
