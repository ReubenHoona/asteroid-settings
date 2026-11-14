/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings
import Nemo.Configuration
import Nemo.Mce

// Settings > Display, the rows of stock CP3A in stock's order
// (PixelWatchNavRouteCollector$init$4.java:36-52): Change watch face,
// (Color theme, W3-qa-color-theme: stock shows it once a theme is set),
// Brightness, Display size & text, Screen timeout, Go to watch face,
// Always-on screen, right under it Always-on when off wrist (the user's
// choice 3), Wrist orientation, Touch lock. No other rows: the Extra dim,
// Always-on brightness, Burn-in protection and Nightstand rows went with
// DECISIONS Q53, Q20 and Q34 (stock has none; the launcher keeps reading
// their dconf keys). A mode that holds the brightness or the always-on
// screen greys it out with the mode as its summary ("Bedtime mode is on"),
// the switch showing it off, as stock.
//
// Screen timeout is the whole time the screen stays on, as on stock: mce
// turns it off (or to the always-on screen) after its dim timeout plus its
// blank timeout. Stock has no dim phase (config_maximumScreenDimDuration 0),
// the choices are 10 s (recommended), 15 s and 30 s, a longer one than the
// recommended asking first. A choice T sets the dim timeout to T and the
// blank timeout to 0, and the face (lock screen) blank timeout to 0 as well (mce
// adds it to the dim timeout there), so the screen stays on for T on the face
// and in apps (wake-sleep-display-09/10).
// Other values on the watch show as the nearest choice and stay as they are
// until one is chosen.
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
    // mce spells it "locksreen": the blank timeout on the watch face (the
    // lock screen), which mce applies after the dim step (display.c mdy_blanking_schedule_off
    // runs in DIM), so the face stays on for dim + this, as the apps do
    MceConfigValue {
        id: faceBlankTimeout
        key: "/system/osso/dsm/display/display_blank_from_locksreen_timeout"
    }
    ConfigurationValue {
        id: alwaysOnDisplay
        key: "/org/asteroidos/settings/always-on-display"
        defaultValue: true
    }
    // Always-on when off wrist (choice 3): true, the user's "never off";
    // false, stock's: ambient ends 60 s off the wrist or on the charger
    ConfigurationValue {
        id: alwaysOnOffWrist
        key: "/org/asteroidos/settings/always-on-off-wrist"
        defaultValue: true
    }
    ConfigurationValue {
        id: nightstandEnabled
        key: "/desktop/asteroid/nightstand/enabled"
        defaultValue: true
    }
    // Go to watch face (stock Settings.Global wear_activity_auto_resume_
    // timeout_ms, default 60000): the launcher reads it (AppLifecycle)
    ConfigurationValue {
        id: goToFace
        key: "/org/asteroidos/settings/go-to-watch-face-ms"
        defaultValue: 60000
    }
    // Change watch face: "picker@<ms>", the pattern of the Health app's
    // ui/open; the launcher goes to the face and opens its picker
    ConfigurationValue {
        id: openFacePicker
        key: "/org/asteroidos/launcher/open-face-picker"
        defaultValue: ""
    }

    // stock default_screen_timeout_entries_v2 (VALUES.tsv: 10000|15000|30000),
    // default_screen_timeout_value_ms 10000
    readonly property var timeouts: [10, 15, 30]
    readonly property int recommendedTimeout: 10
    // stock has no dim phase: the blank timeout is 0 (wake-sleep-display-10)
    readonly property int blankSeconds: 0
    readonly property bool timeoutKnown: dimTimeout.valid && blankTimeout.valid
    // how long the screen stays on now, and the choice nearest to it
    readonly property int screenOn: timeoutKnown ? Number(dimTimeout.value) + Number(blankTimeout.value) : 0
    readonly property int timeoutIndex: nearest(timeouts, screenOn)
    function nearest(values, v) {
        var best = 0
        for (var i = 1; i < values.length; i++)
            if (Math.abs(values[i] - v) < Math.abs(values[best] - v))
                best = i
        return best
    }
    function applyTimeout(s) {
        if (Number(blankTimeout.value) !== blankSeconds)
            blankTimeout.value = blankSeconds
        dimTimeout.value = s
        faceBlankTimeout.value = blankSeconds
    }
    function timeoutLabel(s) {
        //% "%n seconds"
        return qsTrId("id-seconds", s)
    }
    // the option as stock lists and summarises it: the recommended one
    // says so (pref_screenTimeout_default_value)
    function timeoutOption(s) {
        return s === recommendedTimeout
               //% "%n seconds (recommended)"
               ? qsTrId("id-seconds-recommended", s)
               : timeoutLabel(s)
    }

    // Go to watch face: activity_auto_resume_timeout_values_ms, in the
    // order of activity_auto_resume_timeout_labels
    readonly property var goToFaceValues: [0, 15000, 30000, 60000, 120000, 300000, 86400000]
    readonly property var goToFaceLabels: [
        //% "Immediately"
        qsTrId("id-go-immediately"),
        //% "After 15 seconds"
        qsTrId("id-go-15s"),
        //% "After 30 seconds"
        qsTrId("id-go-30s"),
        //% "After 1 minute"
        qsTrId("id-go-1m"),
        //% "After 2 minutes"
        qsTrId("id-go-2m"),
        //% "After 5 minutes"
        qsTrId("id-go-5m"),
        //% "Never"
        qsTrId("id-go-never")
    ]
    readonly property int goToFaceIndex: nearest(goToFaceValues, Number(goToFace.value))

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
            labels.push(timeoutOption(timeouts[i]))
        var chooser = app.choose(qsTrId("id-screen-timeout"), labels, timeoutIndex,
                                 function (i) {
            var s = page.timeouts[i]
            // stock asks for every choice above the recommended one
            // (ScreenTimeoutEntryPreference.java:89), also when it is
            // shorter than today's
            if (s <= page.recommendedTimeout) {
                page.applyTimeout(s)
                return true
            }
            //% "Change screen timeout"
            confirm.ask(qsTrId("id-screen-timeout-confirm"),
                        //% "%1 reduces battery life"
                        qsTrId("id-reduces-battery").arg(page.timeoutLabel(s)),
                        function () { page.applyTimeout(s); chooser.pop() })
            return false
        }, [],
        //% "When display will turn off after inactivity"
        qsTrId("id-screen-timeout-message"))
    }

    function chooseGoToFace() {
        app.choose(qsTrId("id-go-to-watch-face"), goToFaceLabels, goToFaceIndex,
                   function (i) { goToFace.value = page.goToFaceValues[i] }, [],
                   //% "Return to the watch face after inactivity"
                   qsTrId("id-go-to-watch-face-message"))
    }

    // stock goes to the watch face and opens the picker over it (Home +
    // CHOOSE_FACE); the launcher does that on the key, then Settings ends
    function changeWatchFace() {
        openFacePicker.value = "picker@" + Date.now()
        closeTimer.restart()
    }
    Timer {
        id: closeTimer
        interval: 150
        onTriggered: app.closeApp()
    }

    SettingsChip {
        objectName: "watchfaceItem"
        //% "Change watch face"
        title: qsTrId("id-change-watchface")
        onClicked: page.changeWatchFace()
    }
    SettingsChip {
        objectName: "brightnessItem"
        title: qsTrId("id-brightness")
        active: modeState.brightnessHolder === ""
        summary: modeState.summary(modeState.brightnessHolder)
        onClicked: layerStack.push(brightnessLayer)
    }
    SettingsChip {
        objectName: "displaySizeItem"
        title: qsTrId("id-display-size-page")
        onClicked: layerStack.push(displaySizeLayer)
    }
    SettingsChip {
        objectName: "timeoutItem"
        visible: page.timeoutKnown
        title: qsTrId("id-screen-timeout")
        summary: page.timeoutKnown ? page.timeoutOption(page.timeouts[page.timeoutIndex]) : ""
        onClicked: page.chooseTimeout()
    }
    SettingsChip {
        objectName: "goToFaceItem"
        title: qsTrId("id-go-to-watch-face")
        summary: page.goToFaceLabels[page.goToFaceIndex]
        onClicked: page.chooseGoToFace()
    }
    // Always-on screen (choice 3; stock AlwaysOnScreenPreference): off at
    // once; on after stock's question, title "Turn on always-on screen?" and
    // text "Always-on screen reduces battery life." (enable_ambient_screen_
    // dialog_title, enable_ambient_screen: AlwaysOnScreenPreference.java:
    // 145-146). A mode holds it greyed, showing off, with the mode as its
    // summary (:55-75), Bedtime first, then Battery saver, then Theater
    // (ModeState).
    SettingsChip {
        objectName: "aodSwitch"
        //% "Always-on screen"
        title: qsTrId("id-always-on-screen")
        control: "toggle"
        active: modeState.alwaysOnHolder === ""
        summary: modeState.summary(modeState.alwaysOnHolder)
        checked: alwaysOnDisplay.value && active
        onClicked: {
            if (alwaysOnDisplay.value) {
                page.setAlwaysOn(false)
                return
            }
            //% "Turn on always-on screen?"
            confirm.ask(qsTrId("id-aod-confirm-title"),
                        //% "Always-on screen reduces battery life."
                        qsTrId("id-aod-confirm"),
                        function () { page.setAlwaysOn(true) })
        }
    }
    // Always-on when off wrist (choice 3, DECISIONS Q9): one switch for off
    // the wrist and on the charger, as stock ends ambient on one timer for
    // both (60 s, ro.ambient.plugged_timeout_min 1). On, the user's value:
    // the always-on screen never goes black. Off, stock's: the launcher ends
    // ambient 60 s after the watch leaves the wrist or is plugged in
    // (W2-launcher-ambient). Caption in the pattern of stock's "Silence when
    // off wrist" caption. Greyed while Always-on screen is off; a mode holds
    // it as it holds Always-on screen (greyed, showing off, the same summary).
    SettingsChip {
        objectName: "aodOffWristSwitch"
        //% "Always-on when off wrist"
        title: qsTrId("id-aod-off-wrist")
        control: "toggle"
        active: modeState.alwaysOnHolder === "" && !!alwaysOnDisplay.value
        summary: modeState.summary(modeState.alwaysOnHolder)
        checked: !!alwaysOnOffWrist.value && modeState.alwaysOnHolder === ""
        onClicked: alwaysOnOffWrist.value = !alwaysOnOffWrist.value
    }
    SettingsText {
        objectName: "aodOffWristCaption"
        //% "Always-on screen stays on when watch is off wrist or charging"
        text: qsTrId("id-aod-off-wrist-explain")
    }
    // plain button rows, no summary (WristOrientationPreference.java:56,
    // TouchLockPreference.java:35)
    SettingsChip {
        objectName: "wristOrientationItem"
        //% "Wrist orientation"
        title: qsTrId("id-wrist-orientation")
        onClicked: layerStack.push(wristOrientationLayer)
    }
    SettingsChip {
        objectName: "touchLockItem"
        //% "Touch lock"
        title: qsTrId("id-touch-lock")
        onClicked: layerStack.push(touchLockLayer)
    }
}
