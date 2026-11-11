/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

/*
 * Settings > Vibration, in stock CP3A order (the vibration preferenceFactories
 * of ClockworkNavRouteCollector):
 * - Silence watch (stock: off the wrist or charging; this watch knows the
 *   charger: asteroid-btsyncd's quiet-on-charger) and its caption;
 * - Vibration & haptics: the master for every vibration
 *   (/desktop/asteroid/vibration; stock VibrationSwitchPreference on
 *   vibrate_on, title pref_vibrationEnabled);
 * - the category Interactive haptics with Touch feedback (taps, switches,
 *   keys: /org/asteroidos/ux/haptics, stock HapticsTouchVibrationSwitch-
 *   Preference on haptic_feedback_intensity, default on) and Using crown
 *   (crown ticks, focus clicks and end bumps: /org/asteroidos/ux/haptics-crown,
 *   stock HapticsCrownVibrationSwitchPreference on
 *   hardware_haptic_feedback_intensity). Both are greyed while the master is
 *   off and still show their own value (HapticsCrownVibrationSwitch-
 *   Preference$$ExternalSyntheticLambda0: enabled = master, checked =
 *   intensity > 0). No mode holds them.
 * Using crown is the user's choice 1 (PLAN.md section 4): off by default
 * here, on in stock (config_defaultHapticFeedbackIntensity 3). The
 * org.asteroid.controls Haptics singleton reads the three keys: touch class =
 * master and Touch feedback, crown class = master and Using crown.
 */
SettingsPage {
    id: page
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
    ConfigurationValue {
        id: touchFeedback
        key: "/org/asteroidos/ux/haptics"
        defaultValue: true
    }
    ConfigurationValue {
        id: crownHaptics
        key: "/org/asteroidos/ux/haptics-crown"
        defaultValue: false
    }

    function on(v) { return v === true || v === "true" }
    readonly property bool masterOn: on(vibration.value)

    /*
     * The sample stock plays when one of these switches is turned on
     * (VibratorExtKt.vibrateSample), as ngfd events (meta-eos64
     * events.d/vib-preview.ini, the stock sample patterns):
     * - Vibration & haptics: vib_preview_master (TICK) at once, touch usage
     *   (VibrationSwitchPreference.java:116-119, :145);
     * - Touch feedback: vib_preview_touch 100 ms later, touch usage, only with
     *   the master on (HapticsTouchVibrationSwitchPreference.java:162-181);
     * - Using crown: vib_preview_crown (click) 100 ms later, hardware
     *   feedback usage, only with the master on
     *   (HapticsCrownVibrationSwitchPreference.java:162-181, raw
     *   rotary_vibration_setting_sample).
     * Haptics plays each in its class (touch or crown), so it needs the new
     * value: if dconf has not handed it to Haptics yet, the sample waits for
     * Haptics' enabledChanged, for at most 1 s. Nothing runs unless a switch
     * was just turned on.
     */
    QtObject {
        id: sample
        property string event: ""
        property bool crown: false
        readonly property int delay: 100
        readonly property int patience: 1000

        function start(ev, isCrown, ms) {
            event = ev
            crown = isCrown
            sampleGiveUp.restart()
            if (ms > 0) {
                sampleDelay.interval = ms
                sampleDelay.restart()
            } else {
                sampleDelay.stop()
                tryPlay()
            }
        }
        function tryPlay() {
            if (event === "" || sampleDelay.running)
                return
            if (!(crown ? Haptics.crownEnabled : Haptics.enabled))
                return
            var ev = event
            event = ""
            sampleGiveUp.stop()
            Haptics.playAs(ev, crown ? Haptics.Crown : Haptics.Touch)
        }
    }
    Timer { id: sampleDelay; onTriggered: sample.tryPlay() }
    Timer { id: sampleGiveUp; interval: sample.patience; onTriggered: sample.event = "" }
    Connections {
        target: Haptics
        enabled: sample.event !== ""
        function onEnabledChanged() { sample.tryPlay() }
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
    SettingsChip {
        objectName: "vibrationSwitch"
        //% "Vibration & haptics"
        title: qsTrId("id-vibration-haptics")
        control: "toggle"
        checked: page.masterOn
        onClicked: {
            var now = !page.masterOn
            vibration.value = now
            if (now)
                sample.start("vib_preview_master", false, 0)
        }
    }
    //% "Interactive haptics"
    SettingsCategory { objectName: "hapticsCategory"; text: qsTrId("id-interactive-haptics") }
    SettingsChip {
        objectName: "touchFeedbackSwitch"
        //% "Touch feedback"
        title: qsTrId("id-touch-feedback")
        control: "toggle"
        active: page.masterOn
        checked: page.on(touchFeedback.value)
        onClicked: {
            var now = !page.on(touchFeedback.value)
            touchFeedback.value = now
            if (now && page.masterOn)
                sample.start("vib_preview_touch", false, sample.delay)
        }
    }
    SettingsChip {
        objectName: "crownHapticsSwitch"
        //% "Using crown"
        title: qsTrId("id-using-crown")
        control: "toggle"
        active: page.masterOn
        checked: page.on(crownHaptics.value)
        onClicked: {
            var now = !page.on(crownHaptics.value)
            crownHaptics.value = now
            if (now && page.masterOn)
                sample.start("vib_preview_crown", true, sample.delay)
        }
    }
}
