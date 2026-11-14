/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

.pragma library

/*
 * Helpers of the Apps & notifications pages.
 */

// Android's Formatter.formatFileSize (SI units): bytes as a whole number,
// then kB, MB and GB once the value passes 900; two decimals below 1, one
// below 10, none from 10 up (settings-b-06: "12 MB", "1.5 MB"). point is the
// locale's decimal separator.
function formatSize(bytes, point) {
    var b = Number(bytes)
    if (!(b > 0))
        b = 0
    var units = ["B", "kB", "MB", "GB"]
    var i = 0
    while (b > 900 && i < units.length - 1) {
        b /= 1000
        i++
    }
    var digits = i === 0 ? 0 : (b < 1 ? 2 : (b < 10 ? 1 : 0))
    var text = b.toFixed(digits)
    if (point && point !== ".")
        text = text.replace(".", point)
    return text + " " + units[i]
}

// the stored lists are string lists; anything else counts as empty
function asList(value) {
    var out = []
    if (value === undefined || value === null)
        return out
    var n = value.length
    for (var i = 0; i < n; i++)
        out.push(String(value[i]))
    return out
}

function has(list, id) {
    return asList(list).indexOf(id) >= 0
}

function plus(list, id) {
    var out = asList(list)
    if (out.indexOf(id) < 0)
        out.push(id)
    return out
}

function minus(list, id) {
    return asList(list).filter(function (x) { return x !== id })
}

// the entries of known-apps: "<package>|<name>" (the phone's apps that
// asteroid-btsyncd has seen in notifications); a line without a name shows
// its package
function parseKnown(list) {
    var out = []
    var seen = {}
    var all = asList(list)
    for (var i = 0; i < all.length; i++) {
        var cut = all[i].indexOf("|")
        var pkg = cut < 0 ? all[i] : all[i].substring(0, cut)
        var name = cut < 0 ? "" : all[i].substring(cut + 1)
        if (pkg === "" || seen[pkg])
            continue
        seen[pkg] = true
        out.push({ "id": pkg, "name": name !== "" ? name : pkg })
    }
    out.sort(function (a, b) { return a.name.localeCompare(b.name) })
    return out
}
