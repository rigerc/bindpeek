// SPDX-FileCopyrightText: 2026 rigerc
// SPDX-License-Identifier: GPL-3.0-or-later
.pragma library

// This is presentation-only filtering. A passive overlay never consumes a
// keypress or launches a command: the compositor remains responsible for that.
function reachable(bind, held) {
    var mods = bind.modifiers || []
    for (var i = 0; i < held.length; ++i)
        if (mods.indexOf(held[i]) === -1)
            return false
    return true
}

function ordered(bindings, held) {
    var rows = []
    for (var i = 0; i < bindings.length; ++i)
        if (reachable(bindings[i], held))
            rows.push({entry: bindings[i], at: i})

    // Shortcuts matching all currently held modifiers appear before ones that
    // require an additional modifier. Preserve source order for equal ranks.
    rows.sort(function (a, b) {
        var aMore = (a.entry.modifiers || []).length - held.length
        var bMore = (b.entry.modifiers || []).length - held.length
        return aMore !== bMore ? aMore - bMore : a.at - b.at
    })
    return rows.map(function (row) { return row.entry })
}

function canonical(value) {
    var name = String(value || "").toUpperCase()
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
        "PRIOR": "PAGEUP", "NEXT": "PAGEDOWN",
        "PRINTSCREEN": "PRINT", "SYSRQ": "PRINT",
        "KPDECIMAL": "KPDOT", "KPDELETE": "KPDOT",
        "KPADD": "KPPLUS", "KPSUBTRACT": "KPMINUS",
        "KPMULTIPLY": "KPASTERISK", "KPDIVIDE": "KPSLASH",
        "ISOLEFTTAB": "TAB", "LESS": "102ND"
    }
    return aliases[name] || name
}
