// SPDX-FileCopyrightText: 2026 rigerc
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick

// Pointer hover for a KeyboardBoard: the key under the pointer, and the
// modifiers its shortcuts use, are lit on the board. Shared by every view that
// draws a keyboard, the overlay's and the settings preview's alike.
//
// Hovering waits for the pointer to actually move. An overlay opens wherever
// the pointer happens to rest, and the compositor reports that resting
// position as soon as the surface appears; lighting up the key underneath it
// would look like a key the user had picked.
//
// Positions are compared in window coordinates: the opening scale animation
// shifts the item-local position of a pointer that never moved. A change of
// size re-centres the surface under the pointer, so it takes a fresh reference
// point instead of counting as movement.
MouseArea {
    id: area
    required property Item keyboard
    property bool armed: false
    property point anchor: Qt.point(-1, -1)
    readonly property int threshold: 3

    hoverEnabled: enabled

    function reset() {
        armed = false
        anchor = Qt.point(-1, -1)
        keyboard.clearHover()
    }
    function rebase() {
        if (!armed)
            anchor = Qt.point(-1, -1)
    }

    // Effective visibility: follows the view being shown and hidden.
    onVisibleChanged: reset()
    onEnabledChanged: reset()
    onWidthChanged: rebase()
    onHeightChanged: rebase()
    onExited: keyboard.clearHover()
    onPositionChanged: mouse => {
        if (!armed) {
            var scene = mapToItem(null, mouse.x, mouse.y)
            if (anchor.x < 0) {
                anchor = scene
                return
            }
            if (Math.abs(scene.x - anchor.x) < threshold
                    && Math.abs(scene.y - anchor.y) < threshold)
                return
            armed = true
        }
        var local = keyboard.mapFromItem(area, mouse.x, mouse.y)
        keyboard.hoverAt(local.x, local.y)
    }
}
