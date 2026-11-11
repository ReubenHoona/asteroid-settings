/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import org.asteroid.settings
import Nemo.Configuration

/*
 * System > Date & time. Stock CP3A's page (ClockworkNavRouteCollector
 * $init$27.java, in the order of prefs_date_time.xml) has Automatic date &
 * time, Automatic time zone, Use location, [Use 24-hour format, order 50],
 * Set date, Set time, Set time zone, and the caption "Time format managed by
 * phone's settings" (order 90; ManualTimeZonePreference.java:179-181). The
 * user's choice 4 (PLAN.md section 4) adds, after Use location:
 * - Automatic time format (/org/asteroidos/settings/time-format-from-phone):
 *   off, the user's value: the watch keeps its own 12/24-hour setting; on,
 *   stock's: the phone's 24-hour setting, which btsyncd writes into
 *   use-12h-format while time sync is on (W2-btsyncd-data, W2-gb-data);
 * - Use 24-hour format (checked = use-12h-format false), shown only while
 *   Automatic time format is off; stock removes it when the phone sets the
 *   format and shows the caption instead (DateTimeSettingsFragment
 *   ExternalSyntheticLambda4). Its summary is 13:00 on 31 December in the
 *   time format, not the clock (DateTimeSettingsFragment.java:250-251).
 * The caption shows only while Automatic time format is on. The automatic
 * date, time zone and location rows go above (W2-settings-battery-system).
 * Times are written by TimeFormat (pattern B, DateFormat.getTimeFormat),
 * which reads the same use-12h-format key with the same code default.
 * The watch takes the time from the phone when it connects.
 */
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
    ConfigurationValue {
        id: fromPhone
        key: "/org/asteroidos/settings/time-format-from-phone"
        defaultValue: false
    }

    function on(v) { return v === true || v === "true" }
    readonly property bool formatFromPhone: on(fromPhone.value)
    // the 24-hour switch's sample time: 13:00 on 31 December this year
    readonly property var hourSample: new Date(clock.time.getFullYear(), 11, 31, 13, 0, 0)

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
        objectName: "autoTimeFormatSwitch"
        //% "Automatic time format"
        title: qsTrId("id-auto-time-format")
        control: "toggle"
        checked: page.formatFromPhone
        onClicked: fromPhone.value = !page.formatFromPhone
    }
    SettingsChip {
        id: hourFormat
        objectName: "hourFormatSwitch"
        visible: !page.formatFromPhone
        //% "Use 24-hour format"
        title: qsTrId("id-24h-format")
        summary: TimeFormat.time(page.hourSample)
        control: "toggle"
        checked: !page.on(use12H.value)
        // 24-hour on -> 12-hour, and back
        onClicked: use12H.value = hourFormat.checked
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
        summary: TimeFormat.time(clock.time)
        onClicked: layerStack.push(timeLayer)
    }
    SettingsChip {
        objectName: "setZoneItem"
        //% "Set time zone"
        title: qsTrId("id-set-timezone")
        summary: page.zoneLabel(page.zone, clock.time)
        onClicked: layerStack.push(timezoneLayer, { "done": function () { page.zone = dtSettings.currentTimezone() } })
    }
    SettingsText {
        objectName: "hourFormatCaption"
        visible: page.formatFromPhone
        //% "Time format managed by phone's settings"
        text: qsTrId("id-hour-format-explain")
    }
}
