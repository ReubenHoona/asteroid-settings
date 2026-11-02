/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Apps & notifications > Do Not Disturb (stock prefs_dnd.xml): the
// "Do Not Disturb" header and its On/Off switch, then "Bedtime mode" and its
// switch with what it does. The same dconf keys as the quick panel's tiles;
// the launcher's modes engine keeps the two apart (the one turned on last
// wins), asteroid-btsyncd keeps the phone's Do Not Disturb in step with
// either.
SettingsPage {
    objectName: "dndPage"
    title: qsTrId("id-dnd-page")


    SettingsCategory { text: qsTrId("id-dnd-page") }
    SettingsChip {
        objectName: "dndSwitch"
        title: modeState.doNotDisturb ? qsTrId("id-on") : qsTrId("id-off")
        control: "toggle"
        checked: modeState.doNotDisturb
        onClicked: modeState.doNotDisturb = !modeState.doNotDisturb
    }
    SettingsText {
        //% "Notifications arrive quietly, without a banner or vibration. Alarms still ring. Your phone's Do Not Disturb follows it."
        text: qsTrId("id-dnd-explain")
    }
    //% "Bedtime mode"
    SettingsCategory { text: qsTrId("id-bedtime-mode") }
    SettingsChip {
        objectName: "bedtimeSwitch"
        title: modeState.bedtime ? qsTrId("id-on") : qsTrId("id-off")
        control: "toggle"
        checked: modeState.bedtime
        onClicked: modeState.bedtime = !modeState.bedtime
    }
    SettingsText {
        //% "Watch screen, tilt-to-wake, and touch are turned off. Only alarms and timers will notify you."
        text: qsTrId("id-bedtime-explain")
    }
}
