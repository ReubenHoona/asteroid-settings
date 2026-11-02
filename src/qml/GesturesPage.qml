/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings

// Settings > Gestures (stock prefs_gestures.xml): Tilt-to-wake (mce's wrist
// gesture; turning it on asks first, as stock) and Touch-to-wake (mce's
// tap gesture action, the touch panel's wake taps).
SettingsPage {
    objectName: "gesturesPage"
    title: qsTrId("id-gestures-page")

    TiltToWake { id: tiltToWake }
    TapToWake { id: tapToWake }

    SettingsChip {
        objectName: "tiltSwitch"
        active: tiltToWake.available
        title: qsTrId("id-tilt-to-wake")
        control: "toggle"
        checked: tiltToWake.enabled
        onClicked: {
            if (tiltToWake.enabled) {
                tiltToWake.enabled = false
                return
            }
            //% "Tilt-to-wake reduces battery life."
            confirm.ask(qsTrId("id-tilt-confirm"), qsTrId("id-turn-on"),
                        function () { tiltToWake.enabled = true })
        }
    }
    SettingsChip {
        objectName: "touchSwitch"
        //% "Touch-to-wake"
        title: qsTrId("id-touch-to-wake")
        control: "toggle"
        checked: tapToWake.enabled
        onClicked: tapToWake.enabled = !tapToWake.enabled
    }
}
