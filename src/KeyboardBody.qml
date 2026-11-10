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
    // Also used in the editor's static preview: it must not steal focus or
    // close a real overlay when somebody clicks the preview.
    property bool interactive: true
    signal closeRequested()
    readonly property int gap: Math.max(3, Math.round(unit * 0.09))
    readonly property int unit: Math.floor(Math.max(28, Math.min(58,
                           (theme.screenWidth - 80) / 24,
                           (theme.screenHeight - 190) / 8)))
    readonly property int padding: Math.round(unit * 0.34)
    implicitWidth: content.implicitWidth + 2 * padding
    implicitHeight: content.implicitHeight + 2 * padding
    focus: interactive
    onVisibleChanged: if (visible && interactive) forceActiveFocus()
    // Switching from passive keyboard to the explicitly toggled view does not
    // change visibility, so the new interactive state must request focus too.
    onInteractiveChanged: if (interactive && visible) forceActiveFocus()
    Keys.onPressed: event => {
        // When a compositor forwards the binding, Super+K toggles off too.
        if (interactive && (event.key === Qt.Key_Escape ||
                (event.key === Qt.Key_K && (event.modifiers & Qt.MetaModifier)))) {
            closeRequested()
            event.accepted = true
        }
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
                text: board.availableCount + " shortcuts"
                color: root.theme.textMuted
                font.family: root.theme.fontFamilyMono
                font.pixelSize: Math.max(10, root.unit * 0.22)
            }
        }

        KeyboardBoard {
            id: board
            theme: root.theme
            bindings: root.bindings
            held: root.held
            unit: root.unit
            gap: root.gap
        }

        Text {
            width: board.implicitWidth
            visible: board.unplaced.length > 0
            text: "Other: " + board.unplaced.map(item => item.shortcut
                              + "  " + item.description).join("   •   ")
            elide: Text.ElideRight
            color: root.theme.textMuted
            font.family: root.theme.fontFamily
            font.pixelSize: Math.max(10, root.unit * 0.20)
        }
        Text {
            width: board.implicitWidth
            text: root.interactive
                  ? qsTr("Hold modifiers to filter   •   Esc or click to close")
                  : qsTr("Release modifiers to hide   •   Shortcuts remain active")
            color: root.theme.textMuted
            font.family: root.theme.fontFamily
            font.pixelSize: Math.max(10, root.unit * 0.22)
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        onClicked: root.closeRequested()
    }
}
