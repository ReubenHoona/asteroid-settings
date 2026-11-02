/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import org.asteroid.settings
import Nemo.Configuration

// System > Date & time (stock prefs_date_time.xml): Use 24-hour format (the
// time in that format under it), Set date, Set time, Set time zone, each
// with its current value. The watch takes the time from the phone when it
// connects; there is no automatic time zone yet.
SettingsPage {
    id: page
    objectName: "dateTimePage"
    title: qsTrId("id-date-time-page")

    DateTimeSettings { id: dtSettings }
    WallClock {
        id: clock
        enabled: true
        updateFrequency: WallClock.Minute
    }
    ConfigurationValue {
        id: use12H
        key: "/org/asteroidos/settings/use-12h-format"
        defaultValue: false
    }

    // what timedate1 says the zone is, read again when the page shows
    property string zone: dtSettings.currentTimezone()
    function zoneLabel(tz, now) {
        var minutes = -now.getTimezoneOffset()
        var sign = minutes < 0 ? "-" : "+"
        minutes = Math.abs(minutes)
        var hh = ("0" + Math.floor(minutes / 60)).slice(-2)
        var mm = ("0" + (minutes % 60)).slice(-2)
        var city = String(tz).split("/").pop().replace(/_/g, " ")
        return "GMT" + sign + hh + ":" + mm + (city ? " " + city : "")
    }

    SettingsChip {
        objectName: "hourFormatSwitch"
        //% "Use 24-hour format"
        title: qsTrId("id-24h-format")
        summary: clock.time.toLocaleString(Qt.locale(), use12H.value ? "h:mm AP" : "HH:mm")
        control: "toggle"
        checked: !use12H.value
        onClicked: use12H.value = !use12H.value
    }
    SettingsChip {
        objectName: "setDateItem"
        //% "Set date"
        title: qsTrId("id-set-date")
        summary: clock.time.toLocaleDateString(Qt.locale(), Locale.LongFormat)
        onClicked: layerStack.push(dateLayer)
    }
    SettingsChip {
        objectName: "setTimeItem"
        //% "Set time"
        title: qsTrId("id-set-time")
        summary: clock.time.toLocaleString(Qt.locale(), use12H.value ? "h:mm AP" : "HH:mm")
        onClicked: layerStack.push(timeLayer)
    }
    SettingsChip {
        objectName: "setZoneItem"
        //% "Set time zone"
        title: qsTrId("id-set-timezone")
        summary: page.zoneLabel(page.zone, clock.time)
        onClicked: layerStack.push(timezoneLayer, { "done": function () { page.zone = dtSettings.currentTimezone() } })
    }
}
