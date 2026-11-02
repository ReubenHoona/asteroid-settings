/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings

// Display > Adjust brightness (stock prefs_adaptive_brightness.xml): the
// level as an inline slider, Adaptive brightness under it. mce's display
// brightness in percent, 10 to 100 in tens as before (with adaptive
// brightness on, mce scales the light sensor's curve by it).
SettingsPage {
    objectName: "brightnessPage"
    title: qsTrId("id-brightness")

    DisplaySettings { id: displaySettings }

    SettingsSlider {
        objectName: "brightnessSlider"
        from: 10
        to: 100
        stepSize: 10
        value: displaySettings.brightness
        onMoved: (newValue) => displaySettings.brightness = newValue
    }
    SettingsChip {
        objectName: "adaptiveSwitch"
        //% "Adaptive brightness"
        title: qsTrId("id-adaptive-brightness")
        control: "toggle"
        checked: displaySettings.ambientLightSensorEnabled
        onClicked: displaySettings.ambientLightSensorEnabled = !displaySettings.ambientLightSensorEnabled
    }
}
