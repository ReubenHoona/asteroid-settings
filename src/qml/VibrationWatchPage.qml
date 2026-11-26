/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Accessibility > Vibration watch as stock CP3A's
// (VibrationWatchFragment, xml/prefs_accessibility_vibration_watch.xml): the
// switch Vibration watch and its caption, the header Vibration type, the
// radio rows Digits and Terse each with its caption, and Vibration speed, a
// list (Very slow, Slow, Medium, Fast, Very fast; default Medium) with the
// chosen speed as its second line (VibrationWatchSpeedPreference). The type
// rows and the speed depend on the switch (android:dependency): grey and
// still while it is off. The keys are the launcher's (CR-34,
// a11y/VibrationWatch.qml): a11y/vibration-watch b false,
// a11y/vibration-watch-type s digits or terse, a11y/vibration-watch-speed i
// 0..4 default 2.
SettingsPage {
    id: page
    objectName: "vibrationWatchPage"
    //% "Vibration watch"
    title: qsTrId("id-vibration-watch")

    ConfigurationValue {
        id: watch
        key: "/org/asteroidos/a11y/vibration-watch"
        defaultValue: false
    }
    ConfigurationValue {
        id: type
        key: "/org/asteroidos/a11y/vibration-watch-type"
        defaultValue: "digits"
    }
    ConfigurationValue {
        id: speed
        key: "/org/asteroidos/a11y/vibration-watch-speed"
        defaultValue: 2
    }

    readonly property bool on: watch.value === true || watch.value === "true"
    readonly property string currentType: String(type.value) === "terse" ? "terse" : "digits"
    // the launcher's validSpeed: 0..4, anything else Medium
    readonly property int currentSpeed: {
        var n = Math.round(Number(speed.value))
        return n >= 0 && n <= 4 ? n : 2
    }
    readonly property var speedNames: [
        //% "Very slow"
        qsTrId("id-vibration-speed-very-slow"),
        //% "Slow"
        qsTrId("id-vibration-speed-slow"),
        //% "Medium"
        qsTrId("id-vibration-speed-medium"),
        //% "Fast"
        qsTrId("id-vibration-speed-fast"),
        //% "Very fast"
        qsTrId("id-vibration-speed-very-fast")
    ]

    SettingsChip {
        objectName: "vibrationWatchSwitch"
        title: qsTrId("id-vibration-watch")
        control: "toggle"
        checked: page.on
        onClicked: watch.value = !checked
    }
    SettingsText {
        objectName: "vibrationWatchCaption"
        //% "Get the current time as vibrations. When the screen is on, tap the watch face with 2 fingers to check the time: single tap for the hour, double tap for the minute."
        text: qsTrId("id-vibration-watch-explain")
    }
    SettingsCategory {
        objectName: "vibrationTypeCategory"
        //% "Vibration type"
        text: qsTrId("id-vibration-type")
    }
    SettingsChip {
        objectName: "vibrationTypeDigits"
        active: page.on
        //% "Digits"
        title: qsTrId("id-vibration-type-digits")
        control: "radio"
        checked: page.currentType === "digits"
        onClicked: if (page.on) type.value = "digits"
    }
    SettingsText {
        objectName: "vibrationTypeDigitsCaption"
        //% "Vibration watch gives you the current time in decimal format. A long vibration means 10 and a short vibration means 1."
        text: qsTrId("id-vibration-type-digits-explain")
    }
    SettingsChip {
        objectName: "vibrationTypeTerse"
        active: page.on
        //% "Terse"
        title: qsTrId("id-vibration-type-terse")
        control: "radio"
        checked: page.currentType === "terse"
        onClicked: if (page.on) type.value = "terse"
    }
    SettingsText {
        objectName: "vibrationTypeTerseCaption"
        //% "Vibration watch gives the minutes briefly. Each short vibration means a quarter-hour."
        text: qsTrId("id-vibration-type-terse-explain")
    }
    SettingsChip {
        objectName: "vibrationSpeedItem"
        active: page.on
        //% "Vibration speed"
        title: qsTrId("id-vibration-speed")
        summary: page.speedNames[page.currentSpeed]
        onClicked: if (page.on) app.choose(qsTrId("id-vibration-speed"), page.speedNames, page.currentSpeed,
                                           function (i) { speed.value = i })
    }
}
