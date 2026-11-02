/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Vibration (stock prefs_vibration.xml): Silence watch (stock:
// off the wrist or charging; this watch knows the charger: asteroid-btsyncd's
// quiet-on-charger), then Interactive haptics: the taps and crown ticks of
// the screens (the key the quick panel's vibration toggle switches).
SettingsPage {
    objectName: "vibrationPage"
    title: qsTrId("id-vibration-page")

    ConfigurationValue {
        id: quietOnCharger
        key: "/org/asteroidos/notifications/quiet-on-charger"
        defaultValue: true
    }
    ConfigurationValue {
        id: vibration
        key: "/desktop/asteroid/vibration"
        defaultValue: true
    }

    SettingsChip {
        objectName: "quietSwitch"
        //% "Silence watch while charging"
        title: qsTrId("id-quiet-on-charger")
        control: "toggle"
        checked: quietOnCharger.value
        onClicked: quietOnCharger.value = !quietOnCharger.value
    }
    SettingsText {
        //% "Notifications won't sound or vibrate while the watch is charging"
        text: qsTrId("id-quiet-on-charger-explain")
    }
    //% "Interactive haptics"
    SettingsCategory { text: qsTrId("id-interactive-haptics") }
    SettingsChip {
        objectName: "hapticsSwitch"
        //% "Touch & crown feedback"
        title: qsTrId("id-touch-feedback")
        control: "toggle"
        checked: vibration.value
        onClicked: {
            vibration.value = !vibration.value
            if (vibration.value)
                Haptics.click()
        }
    }
}
