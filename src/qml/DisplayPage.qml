/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import org.asteroid.settings
import Nemo.Configuration
import Nemo.Mce

// Settings > Display (stock prefs_display.xml, DisplaySettingsFragment):
// Change watch face, Adjust brightness, Screen timeout, Always-on screen,
// then this watch's own: Always-on brightness, Burn-in protection and
// Nightstand. Screen timeout is the whole time the screen stays on, as on
// stock: mce turns it off (or to the always-on screen) after its dim timeout
// plus its blank timeout. The stock choices, 15 s recommended, a longer one
// asking first; a choice T sets the blank timeout to 5 s (stock's dim to
// off) and the dim timeout to T - 5. Other values on the watch show as the
// nearest choice and stay as they are until one is chosen.
SettingsPage {
    id: page
    objectName: "displayPage"
    title: qsTrId("id-display-page")

    DisplaySettings { id: displaySettings }
    MceChargerType { id: mceChargerType }
    MceConfigValue {
        id: dimTimeout
        key: "/system/osso/dsm/display/display_dim_timeout"
    }
    MceConfigValue {
        id: blankTimeout
        key: "/system/osso/dsm/display/display_blank_timeout"
    }
    ConfigurationValue {
        id: alwaysOnDisplay
        key: "/org/asteroidos/settings/always-on-display"
        defaultValue: true
    }
    ConfigurationValue {
        id: nightstandEnabled
        key: "/desktop/asteroid/nightstand/enabled"
        defaultValue: true
    }
    // How bright the always-on screen is: the launcher hands it to the
    // panel (its AOD brightness step: low 6, medium 8, the image's default,
    // high 12)
    ConfigurationValue {
        id: aodBrightness
        key: "/org/asteroidos/settings/always-on-brightness"
        defaultValue: "medium"
    }
    ConfigurationValue {
        id: bipLevel
        key: "/org/asteroidos/settings/burn-in-protection-level"
        defaultValue: DeviceSpecs.needsBurnInProtection ? 1.0 : 0.0
    }

    readonly property var timeouts: [10, 15, 30]
    readonly property int recommendedTimeout: 15
    // stock's dim to off
    readonly property int blankSeconds: 5
    readonly property bool timeoutKnown: dimTimeout.valid && blankTimeout.valid
    // how long the screen stays on now, and the choice nearest to it
    readonly property int screenOn: timeoutKnown ? Number(dimTimeout.value) + Number(blankTimeout.value) : 0
    readonly property int timeoutIndex: {
        var best = 0
        for (var i = 1; i < timeouts.length; i++)
            if (Math.abs(timeouts[i] - screenOn) < Math.abs(timeouts[best] - screenOn))
                best = i
        return best
    }
    function applyTimeout(s) {
        if (Number(blankTimeout.value) !== blankSeconds)
            blankTimeout.value = blankSeconds
        dimTimeout.value = s - blankSeconds
    }
    function timeoutLabel(s) {
        //% "%1 seconds"
        return qsTrId("id-seconds").arg(s)
    }
    readonly property var aodLabels: [qsTrId("id-low"), qsTrId("id-medium"), qsTrId("id-high")]
    readonly property var aodValues: ["low", "medium", "high"]
    readonly property var bipLabels: [qsTrId("id-off"), qsTrId("id-low"), qsTrId("id-medium"), qsTrId("id-high")]
    readonly property var bipValues: [0.0, 0.25, 0.5, 1.0]

    // the always-on screen as the switch sets it: the intent in dconf, and
    // mce's low power mode unless Nightstand holds it on the charger
    function setAlwaysOn(on) {
        alwaysOnDisplay.value = on
        if (!nightstandEnabled.value || mceChargerType.type == MceChargerType.None)
            displaySettings.lowPowerModeEnabled = on
    }

    function chooseTimeout() {
        var labels = []
        for (var i = 0; i < timeouts.length; i++)
            labels.push(timeouts[i] === recommendedTimeout
                        //% "%1 seconds (recommended)"
                        ? qsTrId("id-seconds-recommended").arg(timeouts[i])
                        : timeoutLabel(timeouts[i]))
        var chooser = app.choose(qsTrId("id-screen-timeout"), labels, timeoutIndex,
                                 function (i) {
            var s = page.timeouts[i]
            if (s <= page.recommendedTimeout || s <= page.screenOn) {
                page.applyTimeout(s)
                return true
            }
            //% "Change screen timeout"
            confirm.ask(qsTrId("id-screen-timeout-confirm"),
                        //% "%1 reduces battery life"
                        qsTrId("id-reduces-battery").arg(page.timeoutLabel(s)),
                        function () { page.applyTimeout(s); chooser.pop() })
            return false
        })
    }

    SettingsChip {
        objectName: "watchfaceItem"
        //% "Change watch face"
        title: qsTrId("id-change-watchface")
        onClicked: layerStack.push(watchfaceLayer)
    }
    SettingsChip {
        objectName: "brightnessItem"
        //% "Adjust brightness"
        title: qsTrId("id-adjust-brightness")
        onClicked: layerStack.push(brightnessLayer)
    }
    SettingsChip {
        objectName: "timeoutItem"
        visible: page.timeoutKnown
        //% "Screen timeout"
        title: qsTrId("id-screen-timeout")
        summary: page.timeoutKnown ? page.timeoutLabel(page.timeouts[page.timeoutIndex]) : ""
        onClicked: page.chooseTimeout()
    }
    SettingsChip {
        objectName: "aodSwitch"
        //% "Always-on screen"
        title: qsTrId("id-always-on-screen")
        control: "toggle"
        checked: alwaysOnDisplay.value
        onClicked: {
            if (alwaysOnDisplay.value) {
                page.setAlwaysOn(false)
                return
            }
            //% "Always-on screen reduces battery life."
            confirm.ask(qsTrId("id-aod-confirm"),
                        //% "Turn on?"
                        qsTrId("id-turn-on"),
                        function () { page.setAlwaysOn(true) })
        }
    }
    SettingsChip {
        objectName: "aodBrightnessItem"
        visible: alwaysOnDisplay.value
        title: qsTrId("id-always-on-brightness")
        summary: page.aodLabels[Math.max(0, page.aodValues.indexOf(aodBrightness.value))]
        onClicked: app.choose(qsTrId("id-always-on-brightness"), page.aodLabels,
                              Math.max(0, page.aodValues.indexOf(aodBrightness.value)),
                              function (i) { aodBrightness.value = page.aodValues[i] })
    }
    SettingsChip {
        objectName: "burnInItem"
        visible: DeviceSpecs.needsBurnInProtection
        //% "Burn-in protection"
        title: qsTrId("id-burn-in")
        summary: page.bipLabels[Math.max(0, page.bipValues.indexOf(Number(bipLevel.value)))]
        onClicked: app.choose(qsTrId("id-burn-in"), page.bipLabels,
                              page.bipValues.indexOf(Number(bipLevel.value)),
                              function (i) { bipLevel.value = page.bipValues[i] })
    }
    SettingsChip {
        objectName: "nightstandItem"
        title: qsTrId("id-nightstand-page")
        //% "On"
        summary: nightstandEnabled.value ? qsTrId("id-on")
                 : qsTrId("id-off")
        onClicked: layerStack.push(nightstandLayer)
    }
}
