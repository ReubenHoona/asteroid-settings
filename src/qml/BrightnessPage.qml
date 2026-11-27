/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings
import Nemo.Configuration

// Display > Brightness (stock prefs_adaptive_brightness.xml and the
// Brightness slider, SliderController.java:350-420): one segmented slider,
// Adaptive brightness under it. As the Wear OS 6 emulator draws it (S24,
// NEWLOOK-61 N61-43): no title and no header over the slider, the time,
// then the stepper from y 84 and the Adaptive brightness row from y 196.
// CP3A drew a header over the slider: SliderController$Brightness$$
// ExternalSyntheticLambda0.java:26-31 picks pref_fixed_brightness
// (pref_adaptive_brightness when adaptive) for the headerLabel of
// SliderUiState.copy$default, which SliderItemKt.java:110 draws. Its words
// stay as the slider's name for the screen reader.
// - Adaptive brightness off, "Fixed brightness": 5 steps of 6, 12,
//   24, 48 and 100 % (the Pixel Watch overlay's brightness_percentages
//   100|48|24|12|6, shown smallest first), the state "%s percent screen
//   brightness".
// - Adaptive brightness on, "Adaptive brightness": 3 steps Dim,
//   Normal and Bright (screen_brightness_for_als 1, 2, 3).
// The slider runs 0 to the step count with the value on the step (1 to n),
// as stock's SliderUiState (min 0, max n, value i + 1), so the first step
// already fills a part of the bar. mce's display_brightness is the level in
// percent of max_display_brightness_levels (100 on this watch): with
// adaptive brightness off it is the panel level, with it on it picks one of
// mce's light sensor curves (/etc/mce/20als-defaults.ini, lux to percent),
// so the three adaptive steps are three levels of that scale. Stock's three
// curves are in the vendor display config, out of reach (wake-sleep-display
// E28), so the levels are data, not code (C-06): the dconf key
// /org/asteroidos/settings/adaptive-brightness-levels, three whole percents
// from Dim to Bright ("[20, 50, 85]" or "20,50,85"), which the image can
// set in its dconf defaults once they are tuned on the panel (R5-settings
// TEST.txt); anything else (not three, not rising, outside 1 to 100) is
// the built-in 20, 50, 85. Normal is the image default of mce's
// display_brightness (50). What is stored reads back as the nearest step.
SettingsPage {
    id: page
    objectName: "brightnessPage"
    // no title: the first row at y 84 (SettingsPage)

    DisplaySettings { id: displaySettings }

    readonly property bool adaptive: displaySettings.ambientLightSensorEnabled
    // brightness_percentages of ClockworkSettingsOverlayPixelWatch, reversed
    readonly property var fixedPercents: [6, 12, 24, 48, 100]
    // Dim, Normal, Bright: levels of mce's brightness scale, from the
    // dconf key when it holds three rising percents (C-06)
    readonly property var defaultAdaptivePercents: [20, 50, 85]
    ConfigurationValue {
        id: adaptiveLevels
        key: "/org/asteroidos/settings/adaptive-brightness-levels"
        defaultValue: page.defaultAdaptivePercents
    }
    function parseLevels(v) {
        var parts = []
        if (Array.isArray(v) || (v && typeof v === "object" && v.length !== undefined)) {
            for (var i = 0; i < v.length; i++)
                parts.push(v[i])
        } else if (typeof v === "string") {
            parts = v.replace(/[\[\]\s]/g, "").split(/[,;]/)
        } else {
            return null
        }
        if (parts.length !== 3)
            return null
        var out = []
        for (var j = 0; j < 3; j++) {
            var n = Number(parts[j])
            if (String(parts[j]).trim() === "" || !isFinite(n) || Math.round(n) !== n || n < 1 || n > 100)
                return null
            if (j > 0 && n <= out[j - 1])
                return null
            out.push(n)
        }
        return out
    }
    readonly property var adaptivePercents: parseLevels(adaptiveLevels.value) || defaultAdaptivePercents
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

    SettingsSlider {
        objectName: "brightnessSlider"
        // stock Brightness is a segmented slider
        // (SliderController$Brightness$$ExternalSyntheticLambda0.java:44,
        // copy$default mask 527)
        segmented: true
        // CP3A's header words, for the screen reader only
        Accessible.name: page.adaptive
                         //% "Adaptive brightness"
                         ? qsTrId("id-adaptive-brightness")
                         //% "Fixed brightness"
                         : qsTrId("id-fixed-brightness")
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
