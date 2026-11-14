/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import org.asteroid.settings
import Nemo.Configuration
import Nemo.DBus

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
 * The caption shows only while Automatic time format is on. Times are
 * written by TimeFormat (pattern B, DateFormat.getTimeFormat), which reads
 * the same use-12h-format key with the same code default.
 *
 * W2-settings-battery-system:
 * - Automatic date & time (settings-b-24; AutoDateTimePreference:127-129):
 *   a switch, on by default (stock: on unless clockwork_auto_time is 2);
 *   /org/asteroidos/settings/auto-time. btsyncd applies the phone's time
 *   only while it is on, and connman's TimeUpdates follows it ("auto" /
 *   "manual", set here as timed's NtpController does). Set date and Set
 *   time are greyed while it is on (ManualDatePreference:127-129).
 * - Automatic time zone (settings-b-25; AutoTimeZonePreference:127-129):
 *   /org/asteroidos/settings/auto-time-zone, on by default; Gadgetbridge
 *   sends the phone's zone and btsyncd sets it while the key is on. Set time
 *   zone is greyed while it is on (ManualTimeZonePreference:143-145). Use
 *   location waits for location time zone detection (settings-b-08).
 * - Summaries (settings-b-26): Set date is the locale's long date without
 *   the weekday (DateTimeSettingsHelper:24-40, "2 November 2026", "November
 *   2, 2026"), Set time zone is "GMT+13:00" and the zone's short name when it
 *   is not GMT-like ("GMT+13:00 NZDT"; ManualTimeZonePreference:145-175);
 *   the zone list is the selection dialog "Select time zone".
 */
SettingsPage {
    id: page
    objectName: "dateTimePage"
    title: qsTrId("id-date-time-page")

    DateTimeSettings { id: dtSettings }
    TimeZoneModel { id: zones }
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
    ConfigurationValue {
        id: autoTime
        key: "/org/asteroidos/settings/auto-time"
        defaultValue: true
    }
    ConfigurationValue {
        id: autoZone
        key: "/org/asteroidos/settings/auto-time-zone"
        defaultValue: true
    }
    DBusInterface {
        id: connmanClock
        bus: DBus.SystemBus
        service: "net.connman"
        path: "/"
        iface: "net.connman.Clock"
    }
    DBusInterface {
        id: timedate
        bus: DBus.SystemBus
        service: "org.freedesktop.timedate1"
        path: "/org/freedesktop/timedate1"
        iface: "org.freedesktop.timedate1"
    }

    function on(v) { return v === true || v === "true" }
    readonly property bool formatFromPhone: on(fromPhone.value)
    readonly property bool autoDateTime: on(autoTime.value)
    readonly property bool autoTimeZone: on(autoZone.value)
    // the 24-hour switch's sample time: 13:00 on 31 December this year
    readonly property var hourSample: new Date(clock.time.getFullYear(), 11, 31, 13, 0, 0)

    // what timedate1 says the zone is, read again when the page shows
    property string zone: dtSettings.currentTimezone()

    // DateFormat.getLongDateFormat: the locale's long date without the
    // weekday; "dddd, d MMMM yyyy" becomes "d MMMM yyyy"
    function longDate(date, locale) {
        var l = locale || Qt.locale()
        var fmt = l.dateFormat(Locale.LongFormat)
        fmt = fmt.replace(/d{3,4}[,.]?\s*/, "").replace(/[,\s]+$/, "")
        return l.toString(date, fmt)
    }

    // connman takes the time from the network ("auto") or leaves it
    // ("manual"), as timed's NtpController sets both properties
    function setClockUpdates(auto) {
        var mode = auto ? "auto" : "manual"
        var props = ["TimeUpdates", "TimezoneUpdates"]
        for (var i = 0; i < props.length; i++)
            connmanClock.typedCall("SetProperty", [
                { "type": "s", "value": props[i] },
                { "type": "v", "value": { "type": "s", "value": mode } }
            ], function () {}, function (error, message) { console.log("connman clock", error, message) })
    }
    // the zone list as the selection dialog, sorted by offset then city
    function chooseZone() {
        zones.reload()
        var cities = [], offsets = []
        for (var i = 0; i < zones.count; i++) {
            cities.push(zones.city(i))
            offsets.push(zones.offsetText(i))
        }
        //% "Select time zone"
        app.choose(qsTrId("id-select-timezone"), cities, zones.indexOf(page.zone),
                   function (i) {
                       var id = zones.zoneId(i)
                       if (id !== page.zone) {
                           timedate.typedCall("SetTimezone", [
                               { "type": "s", "value": id },
                               { "type": "b", "value": false }
                           ], function () { page.zone = dtSettings.currentTimezone() },
                           function (error, message) { console.log("call failed", error, "message:", message) })
                           page.zone = id
                       }
                   }, offsets)
    }

    SettingsChip {
        objectName: "autoDateTimeSwitch"
        //% "Automatic date & time"
        title: qsTrId("id-auto-date-time")
        control: "toggle"
        checked: page.autoDateTime
        onClicked: {
            autoTime.value = !page.autoDateTime
            page.setClockUpdates(autoTime.value)
        }
    }
    SettingsChip {
        objectName: "autoTimeZoneSwitch"
        //% "Automatic time zone"
        title: qsTrId("id-auto-time-zone")
        control: "toggle"
        checked: page.autoTimeZone
        onClicked: autoZone.value = !page.autoTimeZone
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
        active: !page.autoDateTime
        //% "Set date"
        title: qsTrId("id-set-date")
        summary: page.longDate(clock.time)
        onClicked: layerStack.push(dateLayer)
    }
    SettingsChip {
        objectName: "setTimeItem"
        active: !page.autoDateTime
        //% "Set time"
        title: qsTrId("id-set-time")
        summary: TimeFormat.time(clock.time)
        onClicked: layerStack.push(timeLayer)
    }
    SettingsChip {
        objectName: "setZoneItem"
        active: !page.autoTimeZone
        //% "Set time zone"
        title: qsTrId("id-set-timezone")
        summary: zones.labelFor(page.zone)
        onClicked: page.chooseZone()
    }
    SettingsText {
        objectName: "hourFormatCaption"
        visible: page.formatFromPhone
        //% "Time format managed by phone's settings"
        text: qsTrId("id-hour-format-explain")
    }
}
