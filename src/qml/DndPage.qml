/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Apps & notifications > Do Not Disturb (stock prefs_dnd.xml): the
// "Do Not Disturb" header and its On/Off switch. The same dconf key as the
// quick panel's moon; asteroid-btsyncd follows it and keeps the phone's
// Do Not Disturb in step.
SettingsPage {
    objectName: "dndPage"
    title: qsTrId("id-dnd-page")

    ConfigurationValue {
        id: doNotDisturb
        key: "/org/asteroidos/notifications/do-not-disturb"
        defaultValue: false
    }

    SettingsCategory { text: qsTrId("id-dnd-page") }
    SettingsChip {
        objectName: "dndSwitch"
        title: doNotDisturb.value ? qsTrId("id-on") : qsTrId("id-off")
        control: "toggle"
        checked: doNotDisturb.value
        onClicked: doNotDisturb.value = !doNotDisturb.value
    }
    SettingsText {
        //% "Notifications arrive quietly, without a banner or vibration. Alarms still ring. Your phone's Do Not Disturb follows it."
        text: qsTrId("id-dnd-explain")
    }
}
