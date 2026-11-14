/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import SettingsTest

// The test double of the C++ TimeZoneModel (src/timezonemodel.cpp): a few
// zones with fixed offsets (the unit test of the real one runs the tz database).
QtObject {
    id: model
    property string tabFile: ""
    property var zones: []
    readonly property int count: zones.length
    readonly property var table: [
        { id: "Pacific/Honolulu", offset: -36000, abbr: "HST" },
        { id: "America/New_York", offset: -18000, abbr: "EST" },
        { id: "Africa/Abidjan", offset: 0, abbr: "GMT" },
        { id: "Europe/London", offset: 0, abbr: "GMT" },
        { id: "Europe/Berlin", offset: 3600, abbr: "CET" },
        { id: "Europe/Paris", offset: 3600, abbr: "CET" },
        { id: "Asia/Istanbul", offset: 10800, abbr: "+03" },
        { id: "Pacific/Auckland", offset: 46800, abbr: "NZDT" },
        { id: "Zulu", offset: 0, abbr: "UTC" }
    ]
    function reload() {
        var l = table.slice()
        l.sort(function (a, b) { return a.offset - b.offset || cityOf(a.id).localeCompare(cityOf(b.id)) })
        zones = l
    }
    function cityOf(id) { return String(id).split("/").pop().replace(/_/g, " ") }
    function offsetLabel(s) {
        var m = Math.abs(s) / 60
        return "GMT" + (s < 0 ? "-" : "+") + ("0" + Math.floor(m / 60)).slice(-2) + ":" + ("0" + (m % 60)).slice(-2)
    }
    function zoneId(i) { return zones[i].id }
    function city(i) { return cityOf(zones[i].id) }
    function offsetText(i) { return offsetLabel(zones[i].offset) }
    function indexOf(id) {
        for (var i = 0; i < zones.length; i++)
            if (zones[i].id === id) return i
        return -1
    }
    function labelFor(id) {
        for (var i = 0; i < table.length; i++)
            if (table[i].id === id) {
                var a = table[i].abbr
                var like = a.indexOf("GMT") === 0 || a.indexOf("UTC") === 0 || a.charAt(0) === "+" || a.charAt(0) === "-"
                return offsetLabel(table[i].offset) + (like ? "" : " " + a)
            }
        return ""
    }
}
