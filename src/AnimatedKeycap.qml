// SPDX-FileCopyrightText: 2026 rigerc
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick

// Visual emphasis only. "available" means a shortcut can be reached with the
// held modifiers; the keyboard watch never exposes ordinary key identities.
Rectangle {
    id: cap
    required property var theme
    property string caption: ""
    property string detail: ""
    property bool available: false
    property bool exact: false
    property bool heldModifier: false
    // Pointer emphasis from the interactive keyboard: the key under the
    // pointer, the modifier keys its shortcuts need, and everything else
    // stepped back while that key has shortcuts to show.
    property bool hovered: false
    property bool related: false
    property bool dimmed: false
    property bool blank: false
    property bool showDetail: false
    property bool centered: false
    property int captionSize: Math.max(10, theme.fontSizeBody)
    property int detailSize: Math.max(8, theme.fontSizeSmall)
    readonly property bool lit: available || heldModifier || hovered || related
    readonly property bool modifierLit: heldModifier || related
    readonly property color highlightColor: hovered ? theme.text
                                            : modifierLit ? theme.accent
                                            : exact ? theme.brand : theme.accent

    radius: Math.max(3, theme.radiusPill)
    color: blank ? "transparent" : lit ? theme.surfaceHover : theme.surface
    border.width: blank ? 0 : lit ? 2 : theme.borderWidthKey
    border.color: hovered ? theme.text : modifierLit ? theme.accent
                  : exact ? theme.brand : available ? theme.accent : theme.border
    scale: blank ? 1 : hovered ? 1.1 : modifierLit ? 1.06 : exact ? 1.04
           : available ? 1.02 : 1
    // Lifted above its neighbours so the enlarged hovered cap is not clipped.
    z: hovered ? 2 : modifierLit ? 1 : 0
    opacity: dimmed && !blank ? 0.4 : 1

    Behavior on color {
        enabled: cap.theme.animationsEnabled
        ColorAnimation { duration: cap.theme.keyAnimationDuration }
    }
    Behavior on scale {
        enabled: cap.theme.animationsEnabled
        NumberAnimation {
            duration: cap.theme.keyAnimationDuration
            easing.type: Easing.OutCubic
        }
    }
    Behavior on border.color {
        enabled: cap.theme.animationsEnabled
        ColorAnimation { duration: cap.theme.keyAnimationDuration }
    }
    Behavior on opacity {
        enabled: cap.theme.animationsEnabled
        NumberAnimation { duration: cap.theme.keyAnimationDuration }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: cap.radius + 4
        color: "transparent"
        border.width: 2
        border.color: cap.highlightColor
        opacity: cap.blank ? 0 : cap.hovered ? 0.8 : cap.modifierLit ? 0.65
                 : cap.exact ? 0.42 : cap.available ? 0.22 : 0
        z: -1
        Behavior on opacity {
            enabled: cap.theme.animationsEnabled
            NumberAnimation { duration: cap.theme.keyAnimationDuration }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Math.max(2, cap.width * 0.09)
        anchors.rightMargin: Math.max(2, cap.width * 0.09)
        anchors.top: parent.top
        anchors.topMargin: 2
        height: Math.max(1, cap.height * 0.05)
        radius: height / 2
        color: cap.theme.borderFocus
        opacity: cap.blank ? 0 : cap.lit ? 0.48 : 0.17
        Behavior on opacity {
            enabled: cap.theme.animationsEnabled
            NumberAnimation { duration: cap.theme.keyAnimationDuration }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: Math.max(2, cap.height * 0.08)
        spacing: 1
        visible: !cap.blank
        Text {
            width: parent.width
            text: cap.caption
            elide: Text.ElideRight
            horizontalAlignment: cap.centered ? Text.AlignHCenter : Text.AlignLeft
            color: cap.modifierLit ? cap.theme.accent : cap.theme.text
            font.family: cap.theme.fontFamilyMono
            font.bold: cap.lit
            font.pixelSize: cap.captionSize
        }
        Text {
            width: parent.width
            visible: cap.showDetail
            text: cap.detail
            elide: Text.ElideRight
            color: cap.exact ? cap.theme.brand : cap.theme.textMuted
            font.family: cap.theme.fontFamily
            font.pixelSize: cap.detailSize
        }
    }
}
