// SPDX-FileCopyrightText: 2026 rigerc
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import "ShortcutPresentation.js" as Shortcuts

// A readable shortlist above the same physical keycaps as KeyboardBody.
// The compositor still owns shortcuts: this is a passive cheat sheet.
Item {
    id: root
    required property QtObject theme
    property var bindings: []
    property var held: []

    readonly property int padding: Math.max(12, Math.round(theme.fontSizeBody * 1.1))
    readonly property int gap: Math.max(8, Math.round(theme.fontSizeBody * 0.8))
    readonly property int keyUnit: Math.max(17, Math.min(38,
        Math.floor((theme.screenWidth - 90) / 19),
        Math.floor((theme.screenHeight - 350) / 7)))
    readonly property int rowHeight: Math.max(36, Math.min(52, theme.fontSizeBody * 3))
    readonly property int maxRows: theme.screenHeight < 780 ? 4
                                    : theme.screenHeight < 1000 ? 5 : 7
    readonly property var actions: Shortcuts.ordered(bindings, held)
    readonly property var shown: actions.slice(0, maxRows)
    readonly property int cardWidth: Math.max(board.implicitWidth,
                                             Math.min(620, theme.screenWidth - 64))

    implicitWidth: stack.implicitWidth + padding * 2
    implicitHeight: stack.implicitHeight + padding * 2

    Column {
        id: stack
        anchors.centerIn: parent
        spacing: root.gap

        Rectangle {
            id: card
            width: root.cardWidth
            height: content.implicitHeight + root.padding * 2
            radius: root.theme.radiusPanel
            color: "transparent"
            border.color: root.theme.borderFocus
            border.width: Math.max(1, root.theme.borderWidth)

            // Fade only the plate, never the action text and keycaps.
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: root.theme.background
                opacity: root.theme.panelOpacity
                z: -1
            }

            Column {
                id: content
                x: root.padding
                y: root.padding
                width: card.width - root.padding * 2
                spacing: root.gap

                Row {
                    spacing: root.gap
                    Rectangle {
                        width: Math.max(66, root.theme.fontSizeBody * 5)
                        height: Math.max(34, root.theme.fontSizeBody * 2.5)
                        radius: root.theme.radiusPill
                        color: root.theme.surfaceHover
                        border.color: root.theme.accent
                        border.width: 2
                        Text {
                            anchors.centerIn: parent
                            text: root.held.length ? root.held.join("+") : qsTr("ALL")
                            color: root.theme.text
                            font.family: root.theme.fontFamilyMono
                            font.pixelSize: Math.max(11, root.theme.fontSizeBody)
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width - 6
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                    Text {
                        text: qsTr("Quick Actions")
                        color: root.theme.text
                        font.family: root.theme.fontFamily
                        font.bold: true
                        font.pixelSize: Math.max(15, root.theme.fontSizeTitle)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Repeater {
                    model: root.shown
                    delegate: Rectangle {
                        id: actionRow
                        required property var modelData
                        required property int index
                        readonly property bool exact:
                            (modelData.modifiers || []).length === root.held.length
                        width: content.width
                        height: root.rowHeight
                        radius: root.theme.radiusPill
                        color: exact ? root.theme.surfaceHover : root.theme.surface
                        border.width: exact ? 2 : 1
                        border.color: exact ? root.theme.accent : root.theme.border
                        // The row frames use the palette accent, while
                        // keyboard highlights still distinguish exact matches.
                        scale: exact ? 1.01 : 1
                        Behavior on scale {
                            enabled: root.theme.animationsEnabled
                            NumberAnimation {
                                duration: root.theme.cardAnimationDuration
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on color {
                            enabled: root.theme.animationsEnabled
                            ColorAnimation { duration: root.theme.cardAnimationDuration }
                        }
                        Behavior on border.color {
                            enabled: root.theme.animationsEnabled
                            ColorAnimation { duration: root.theme.cardAnimationDuration }
                        }

                        AnimatedKeycap {
                            id: keycap
                            x: root.gap / 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(44, root.theme.fontSizeBody * 3.6)
                            height: parent.height - root.gap
                            radius: root.theme.radiusPill
                            theme: root.theme
                            caption: modelData.key || "?"
                            available: true
                            exact: actionRow.exact
                            centered: true
                            captionSize: Math.max(10, root.theme.fontSizeBody)
                        }
                        Text {
                            x: keycap.x + keycap.width + root.gap
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(70, parent.width - x - root.gap - shortcut.width - root.gap)
                            text: modelData.description || modelData.shortcut || qsTr("Unnamed shortcut")
                            elide: Text.ElideRight
                            color: root.theme.text
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeBody
                        }
                        Text {
                            id: shortcut
                            anchors.right: parent.right
                            anchors.rightMargin: root.gap
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.shortcut || ""
                            color: root.theme.textMuted
                            font.family: root.theme.fontFamilyMono
                            font.pixelSize: Math.max(10, root.theme.fontSizeSmall)
                            elide: Text.ElideLeft
                            width: Math.min(180, root.cardWidth * 0.29)
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: root.actions.length === 0
                    text: qsTr("No shortcuts for these modifiers")
                    color: root.theme.textMuted
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeBody
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: root.theme.border
                }
                Text {
                    width: parent.width
                    text: root.actions.length > root.shown.length
                          ? qsTr("+%1 more shortcuts. Hold another modifier to filter.")
                              .arg(root.actions.length - root.shown.length)
                          : qsTr("Release modifiers to hide  ·  Shortcuts run normally")
                    color: root.theme.textMuted
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.fontSizeSmall
                    elide: Text.ElideRight
                }
            }
        }

        KeyboardBoard {
            id: board
            anchors.horizontalCenter: parent.horizontalCenter
            theme: root.theme
            bindings: root.bindings
            held: root.held
            compact: true
            unit: root.keyUnit
        }
    }
}
