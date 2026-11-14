/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

.pragma library

// The networks that were seen without internet, kept in a dconf string
// (/org/asteroidos/eos-wifi/no-internet, a JSON array of names): stock marks
// a saved network whose last connection had no internet access
// (WifiConfiguration.hasNoInternetAccess) and says "No internet" under it.

function parse(value) {
    if (value === undefined || value === null || value === "")
        return []
    try {
        var a = JSON.parse(String(value))
        return Array.isArray(a) ? a : []
    } catch (e) {
        return []
    }
}

// the new stored value with name added (on) or removed (off)
function update(value, name, on) {
    var a = parse(value)
    var i = a.indexOf(name)
    if (on && i < 0)
        a.push(name)
    else if (!on && i >= 0)
        a.splice(i, 1)
    return JSON.stringify(a)
}
