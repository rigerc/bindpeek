// SPDX-FileCopyrightText: 2026 rigerc
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import "ShortcutPresentation.js" as Shortcuts

// The five closest-matching shortcuts surround the held modifier indicator.
// Remaining bindings stay visible as highlighted keys in the board below.
Item {
    id: root
    required property QtObject theme
    property var bindings: []
    property var held: []

    readonly property var actions: Shortcuts.ordered(bindings, held)
    readonly property var shown: actions.slice(0, 5)
    readonly property int padding: Math.max(12, theme.fontSizeBody)
    readonly property int gap: Math.max(8, Math.round(theme.fontSizeBody * 0.8))
    readonly property int keyUnit: Math.max(17, Math.min(38,
        Math.floor((theme.screenWidth - 90) / 19),
        Math.floor((theme.screenHeight - 420) / 7)))
    readonly property int cardWidth: Math.max(118, Math.min(210, Math.round(theme.screenWidth * 0.22)))
    readonly property int cardHeight: Math.max(48, theme.fontSizeBody * 3.8)
    readonly property int orbitWidth: Math.max(board.implicitWidth, Math.round(cardWidth * 3.5))
    readonly property int orbitHeight: Math.max(260, Math.min(380, Math.round(theme.screenHeight * 0.42)))
    readonly property var slots: [
        {x: 0.50, y: 0.14},
        {x: 0.79, y: 0.36},
        {x: 0.73, y: 0.77},
        {x: 0.27, y: 0.77},
        {x: 0.21, y: 0.36}
    ]
    function slotX(index) { return orbitWidth * slots[index].x }
    function slotY(index) { return orbitHeight * slots[index].y }

    implicitWidth: stack.implicitWidth + padding * 2
    implicitHeight: stack.implicitHeight + padding * 2

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusPanel
        color: root.theme.background
        opacity: root.theme.panelOpacity
    }
    Rectangle {
        anchors.fill: parent
        radius: root.theme.radiusPanel
        color: "transparent"
        border.color: root.theme.border
        border.width: root.theme.borderWidth
    }

    Column {
        id: stack
        anchors.centerIn: parent
        spacing: root.gap

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("RADIAL ACTIONS  ·  %1 available").arg(root.actions.length)
            color: root.theme.text
            font.family: root.theme.fontFamilyMono
            font.bold: true
            font.pixelSize: Math.max(12, root.theme.fontSizeBody)
        }

        Item {
            id: orbit
            width: root.orbitWidth
            height: root.orbitHeight

            Canvas {
                id: spokes
                anchors.fill: parent
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = root.theme.accent.toString()
                    ctx.globalAlpha = 0.65
                    ctx.lineWidth = 2
                    for (var i = 0; i < root.shown.length; ++i) {
                        ctx.beginPath()
                        ctx.moveTo(width / 2, height * 0.48)
                        ctx.lineTo(root.slotX(i), root.slotY(i))
                        ctx.stroke()
                    }
                }
                Connections {
                    target: root
                    function onShownChanged() { spokes.requestPaint() }
                }
                Connections {
                    target: root.theme
                    function onAccentChanged() { spokes.requestPaint() }
                }
            }

            Rectangle {
                id: center
                width: Math.max(72, root.theme.fontSizeBody * 5.5)
                height: width
                x: orbit.width / 2 - width / 2
                y: orbit.height * 0.48 - height / 2
                radius: root.theme.radiusPill * 2
                color: root.theme.surfaceHover
                border.color: root.theme.accent
                border.width: 3
                Text {
                    anchors.fill: parent
                    anchors.margins: 6
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.held.length ? root.held.join("+") : qsTr("ALL")
                    color: root.theme.text
                    font.family: root.theme.fontFamilyMono
                    font.bold: true
                    font.pixelSize: Math.max(12, root.theme.fontSizeBody * 1.15)
                    elide: Text.ElideRight
                    wrapMode: Text.WrapAnywhere
                }
            }

            Repeater {
                model: root.shown
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool exact:
                        (modelData.modifiers || []).length === root.held.length
                    width: root.cardWidth
                    height: root.cardHeight
                    x: root.slotX(index) - width / 2
                    y: root.slotY(index) - height / 2
                    radius: root.theme.radiusPill * 2
                    color: root.theme.surface
                    border.color: exact ? root.theme.accent : root.theme.borderFocus
                    border.width: exact ? 2 : 1
                    Row {
                        anchors.centerIn: parent
                        spacing: root.gap / 2
                        Rectangle {
                            id: actionKey
                            width: Math.max(31, root.theme.fontSizeBody * 2.4)
                            height: Math.max(28, root.theme.fontSizeBody * 2.2)
                            radius: root.theme.radiusPill
                            color: root.theme.surfaceHover
                            border.color: exact ? root.theme.accent : root.theme.borderFocus
                            border.width: 1
                            Text {
                                anchors.fill: parent
                                anchors.margins: 2
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.key || "?"
                                color: root.theme.text
                                font.family: root.theme.fontFamilyMono
                                font.pixelSize: Math.max(10, root.theme.fontSizeBody)
                                font.bold: true
                                elide: Text.ElideRight
                            }
                        }
                        Text {
                            width: root.cardWidth - actionKey.width - root.gap * 2
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.description || modelData.shortcut || qsTr("Unnamed shortcut")
                            color: root.theme.text
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.fontSizeBody
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.actions.length === 0
                text: qsTr("No shortcuts")
                color: root.theme.textMuted
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.fontSizeBody
            }
        }

        Text {
            width: root.orbitWidth
            visible: root.actions.length > 5
            text: qsTr("+%1 more: %2").arg(root.actions.length - 5)
                  .arg(root.actions.slice(5, 8).map(function (item) {
                      return item.shortcut || item.key
                  }).join("  ·  "))
            color: root.theme.textMuted
            font.family: root.theme.fontFamilyMono
            font.pixelSize: root.theme.fontSizeSmall
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
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
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Release modifiers to hide  ·  Shortcuts remain active")
            color: root.theme.textMuted
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.fontSizeSmall
        }
    }
}
