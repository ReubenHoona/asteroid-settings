/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings

// Display > Brightness (stock prefs_adaptive_brightness.xml and the
// Brightness slider, SliderController.java:350-420): one segmented slider
// with a header, Adaptive brightness under it.
// - Adaptive brightness off, header "Fixed brightness": 5 steps of 6, 12,
//   24, 48 and 100 % (the Pixel Watch overlay's brightness_percentages
//   100|48|24|12|6, shown smallest first), the state "%s percent screen
//   brightness".
// - Adaptive brightness on, header "Adaptive brightness": 3 steps Dim,
//   Normal and Bright (screen_brightness_for_als 1, 2, 3).
// The slider runs 0 to the step count with the value on the step (1 to n),
// as stock's SliderUiState (min 0, max n, value i + 1), so the first step
// already fills a part of the bar. mce's display_brightness is the level in
// percent of max_display_brightness_levels (100 on this watch): with
// adaptive brightness off it is the panel level, with it on mce scales its
// light sensor curve by it, so the three adaptive steps are three levels of
// that scale (20, 50, 85 %; the stock curve is the vendor's, so these are
// to be tuned on the watch; Normal is the image default of 50). What is
// stored reads back as the nearest step.
SettingsPage {
    id: page
    objectName: "brightnessPage"
    title: qsTrId("id-brightness")

    DisplaySettings { id: displaySettings }

    readonly property bool adaptive: displaySettings.ambientLightSensorEnabled
    // brightness_percentages of ClockworkSettingsOverlayPixelWatch, reversed
    readonly property var fixedPercents: [6, 12, 24, 48, 100]
    // Dim, Normal, Bright: levels of mce's brightness scale
    readonly property var adaptivePercents: [20, 50, 85]
    readonly property var adaptiveLabels: [
        //% "Dim"
        qsTrId("id-brightness-dim"),
        //% "Normal"
        qsTrId("id-brightness-normal"),
        //% "Bright"
        qsTrId("id-brightness-bright")
    ]
    readonly property var percents: adaptive ? adaptivePercents : fixedPercents
    // mce's level as a percent of its scale
    readonly property real maximum: Math.max(1, displaySettings.maximumBrightness)
    readonly property real storedPercent: displaySettings.brightness * 100 / maximum
    // the step (1 to n) nearest to what mce has
    readonly property int step: {
        var best = 0
        for (var i = 1; i < percents.length; i++)
            if (Math.abs(percents[i] - storedPercent) < Math.abs(percents[best] - storedPercent))
                best = i
        return best + 1
    }
    // the level that sets a step: percent of the scale, never below mce's 1
    function levelOf(percent) {
        return Math.max(1, Math.round(percent * maximum / 100))
    }

    SettingsCategory {
        objectName: "brightnessHeader"
        text: page.adaptive
              //% "Adaptive brightness"
              ? qsTrId("id-adaptive-brightness")
              //% "Fixed brightness"
              : qsTrId("id-fixed-brightness")
    }
    SettingsSlider {
        objectName: "brightnessSlider"
        // stock Brightness is a segmented slider
        // (SliderController$Brightness$$ExternalSyntheticLambda0.java:44,
        // copy$default mask 527)
        segmented: true
        from: 0
        to: page.percents.length
        lowest: 1
        stepSize: 1
        value: page.step
        decreaseDescription: qsTrId("id-decrease-brightness")
        increaseDescription: qsTrId("id-increase-brightness")
        valueDescription: page.adaptive
                          ? page.adaptiveLabels[page.step - 1]
                          //% "%1 percent screen brightness"
                          : qsTrId("id-brightness-state").arg(page.percents[page.step - 1])
        onMoved: (newValue) => displaySettings.brightness = page.levelOf(page.percents[newValue - 1])
    }
    SettingsChip {
        objectName: "adaptiveSwitch"
        title: qsTrId("id-adaptive-brightness")
        control: "toggle"
        checked: displaySettings.ambientLightSensorEnabled
        onClicked: displaySettings.ambientLightSensorEnabled = !displaySettings.ambientLightSensorEnabled
    }
}
