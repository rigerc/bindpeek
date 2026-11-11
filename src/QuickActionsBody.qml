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

    // The scale setting. Fonts already follow it through the theme; the
    // fixed measures below are multiplied by it, and the ones tied to the
    // screen stop growing at what fits.
    readonly property real s: theme.overlayScale
    readonly property int padding: Math.max(12 * s, Math.round(theme.fontSizeBody * 1.1))
    readonly property int gap: Math.max(8 * s, Math.round(theme.fontSizeBody * 0.8))
    readonly property real fitKeyUnit: Math.min((theme.screenWidth - 90) / 19,
                                                (theme.screenHeight - 350) / 7)
    readonly property real naturalKeyUnit: Math.max(17, Math.min(38, fitKeyUnit))
    readonly property int keyUnit: Math.floor(Math.max(9,
        Math.min(naturalKeyUnit * s, Math.max(naturalKeyUnit, fitKeyUnit))))
    readonly property int rowHeight: Math.max(36 * s, Math.min(52 * s, theme.fontSizeBody * 3))
    // Fewer rows on a short screen, and fewer again when they are drawn large.
    readonly property int maxRows: Math.min(theme.screenHeight < 780 ? 4
                                            : theme.screenHeight < 1000 ? 5 : 7,
                                            Math.max(2, Math.floor(theme.screenHeight * 0.36
                                                                   / (rowHeight + gap))))
    readonly property var actions: Shortcuts.ordered(bindings, held)
    readonly property var shown: actions.slice(0, maxRows)
    readonly property int cardWidth: Math.max(board.implicitWidth,
                                             Math.min(620 * s, theme.screenWidth - 64))

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
                        width: Math.max(66 * root.s, root.theme.fontSizeBody * 5)
                        height: Math.max(34 * root.s, root.theme.fontSizeBody * 2.5)
                        radius: root.theme.radiusPill
                        color: root.theme.surfaceHover
                        border.color: root.theme.accent
                        border.width: 2
                        Text {
                            anchors.centerIn: parent
                            text: root.held.length ? root.held.join("+") : qsTr("ALL")
                            color: root.theme.text
                            font.family: root.theme.fontFamilyMono
                            font.pixelSize: Math.max(11 * root.s, root.theme.fontSizeBody)
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
                        font.pixelSize: Math.max(15 * root.s, root.theme.fontSizeTitle)
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
                        readonly property bool pointed: board.hoveredCode !== ""
                            && Shortcuts.canonical(modelData.key) === board.hoveredCode
                        width: content.width
                        height: root.rowHeight
                        radius: root.theme.radiusPill
                        color: exact ? root.theme.surfaceHover : root.theme.surface
                        border.width: exact ? 2 : 1
                        border.color: pointed ? root.theme.text
                                      : exact ? root.theme.accent : root.theme.border
                        opacity: board.hoveredMatches.length > 0 && !pointed ? 0.5 : 1
                        Behavior on opacity {
                            enabled: root.theme.animationsEnabled
                            NumberAnimation { duration: root.theme.cardAnimationDuration }
                        }
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
                            width: Math.max(44 * root.s, root.theme.fontSizeBody * 3.6)
                            height: parent.height - root.gap
                            radius: root.theme.radiusPill
                            theme: root.theme
                            caption: modelData.key || "?"
                            available: true
                            exact: actionRow.exact
                            hovered: actionRow.pointed
                            centered: true
                            captionSize: Math.max(10 * root.s, root.theme.fontSizeBody)
                        }
                        Text {
                            x: keycap.x + keycap.width + root.gap
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(70 * root.s, parent.width - x - root.gap - shortcut.width - root.gap)
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
                            font.pixelSize: Math.max(10 * root.s, root.theme.fontSizeSmall)
                            elide: Text.ElideLeft
                            width: Math.min(180 * root.s, root.cardWidth * 0.29)
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
                    readonly property bool hovering: board.hoverSummary !== ""
                    text: hovering ? board.hoverSummary
                          : root.actions.length > root.shown.length
                          ? qsTr("+%1 more shortcuts. Hold another modifier to filter.")
                              .arg(root.actions.length - root.shown.length)
                          : qsTr("Release modifiers to hide  ·  Shortcuts run normally")
                    color: hovering ? root.theme.accent : root.theme.textMuted
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

    // Hovering a key on the board lights it, its modifiers and its actions
    // above; see KeyboardHover.qml.
    property bool hoverHighlights: true
    KeyboardHover {
        anchors.fill: parent
        keyboard: board
        enabled: root.hoverHighlights
    }
}
