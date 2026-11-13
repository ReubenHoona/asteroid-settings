/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import Nemo.Configuration

/*
 * The watch's modes as Settings shows them (the launcher's modes engine,
 * asteroid-launcher src/modescore.h, does what they change; keep the two
 * tables in step): which mode holds a setting, and the summary stock shows
 * on a setting a mode holds ("Bedtime mode is on"), with the setting
 * greyed out and showing its value in the mode.
 *
 *                  always-on  tilt  touch  brightness
 *   Theater        x          x     x
 *   Bedtime        x          x     x      x (at most 8 %)
 *   Battery saver  x          x
 *   Extra dim                              x (under 10 %)
 */
Item {
    id: state
    visible: false

    ConfigurationValue { id: bedtimeConf; key: "/org/asteroidos/modes/bedtime"; defaultValue: false }
    ConfigurationValue { id: theaterConf; key: "/org/asteroidos/modes/theater"; defaultValue: false }
    ConfigurationValue { id: saverConf; key: "/org/asteroidos/modes/battery-saver"; defaultValue: false }
    ConfigurationValue { id: extraDimConf; key: "/org/asteroidos/modes/extra-dim"; defaultValue: false }
    ConfigurationValue { id: intensityConf; key: "/org/asteroidos/modes/extra-dim-intensity"; defaultValue: 50 }
    ConfigurationValue { id: dndConf; key: "/org/asteroidos/notifications/do-not-disturb"; defaultValue: false }

    property alias bedtime: bedtimeConf.value
    property alias theater: theaterConf.value
    property alias batterySaver: saverConf.value
    property alias extraDim: extraDimConf.value
    property alias extraDimIntensity: intensityConf.value
    property alias doNotDisturb: dndConf.value

    /*
     * Customize pages (modes-dnd-03): /org/asteroidos/modes/<mode>/<name>, mode
     * do-not-disturb | bedtime | theater, name starred | repeat | media |
     * alarm-sound | alarm-vibrate. Stock's defaults: FocusModeConstants.
     * createZenPolicyFor (Bedtime: starred and repeat callers, alarm sound and
     * vibration, no media; Theater: alarms vibrate only) and Do Not Disturb's
     * all five.
     */
    readonly property var customizeDefaults: ({
        "do-not-disturb": { "starred": true, "repeat": true, "media": true, "alarm-sound": true, "alarm-vibrate": true },
        "bedtime": { "starred": true, "repeat": true, "media": false, "alarm-sound": true, "alarm-vibrate": true },
        "theater": { "starred": false, "repeat": false, "media": false, "alarm-sound": false, "alarm-vibrate": true }
    })
    function customizeKey(mode, name) { return "/org/asteroidos/modes/" + mode + "/" + name }
    function customizeDefault(mode, name) {
        return customizeDefaults.hasOwnProperty(mode) ? customizeDefaults[mode][name] === true : false
    }

    readonly property string alwaysOnHolder: theater ? "theater" : bedtime ? "bedtime" : batterySaver ? "battery-saver" : ""
    readonly property string tiltHolder: alwaysOnHolder
    readonly property string touchHolder: theater ? "theater" : bedtime ? "bedtime" : ""
    readonly property string brightnessHolder: bedtime ? "bedtime" : extraDim ? "extra-dim" : ""

    function summary(holder) {
        switch (holder) {
        //% "Bedtime mode is on"
        case "bedtime": return qsTrId("id-mode-bedtime-on")
        //% "Theater mode is on"
        case "theater": return qsTrId("id-mode-theater-on")
        //% "Battery saver mode is on"
        case "battery-saver": return qsTrId("id-mode-saver-on")
        //% "Extra dim is on"
        case "extra-dim": return qsTrId("id-mode-extra-dim-on")
        }
        return ""
    }
}
