/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import Nemo.Ngf

/*
 * Settings > Vibration, in stock CP3A order (the vibration preferenceFactories
 * of ClockworkNavRouteCollector):
 * - Silence watch (stock: off the wrist or charging) and its caption. The
 *   switch writes /org/asteroidos/notifications/silence-off-wrist (CR-10;
 *   the launcher and asteroid-btsyncd read it); the retired quiet-on-charger
 *   of image 44 is read only to show the earlier choice while the new key is
 *   unset, and is never written again;
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
 * - Silence (settings-a-33): stock's title is "Silence when off wrist" with
 *   "Notifications won't sound or vibrate when watch is off wrist or charging"
 *   (SilenceWhenNotWornSwitchPreference, shown where an off-body sensor
 *   exists); until the watch has off-wrist detection (the hub's off-body
 *   sensor: /org/asteroidos/sensors/off-body-available true) the row is the
 *   charger-only "Silence watch while charging". One key either way.
 * - Ring vibration, Notification vibration and Alarm vibration (settings-a-35,
 *   calls-14): sliders of 4 steps, Off, then 1 to 3 (stock
 *   config_vibration_supported_intensity_levels 3, defaults 3 = High), after the
 *   master and before Interactive haptics (CallVibrationSliderPreference,
 *   NotificationVibrationSliderPreference, AlarmVibrationSliderPreference,
 *   ControllerFactory.Vibration, shown on the Pixel Watch:
 *   config_show_*_vibration_setting). Each writes
 *   /org/asteroidos/vibration/{ring,notification,alarm}-intensity, which ngfd's
 *   ffmemless plugin reads as the class level (W1-engine-haptics: 0 off, 1 to
 *   3 scale the gain by 1.4^(level - 3)). Greyed while the master is off.
 *   A step plays the class sample 100 ms later, at the level just chosen,
 *   only with the master on and the new level above 0, cancelling a running
 *   sample first (SliderController$Vibration.handleValueChange:327-340,
 *   VibratorExtKt.vibrateSample; haptics-sounds-19): vib_preview_ring (3
 *   slow rises 250 ms apart), vib_preview_notification (two quick rises and
 *   a spin) and vib_preview_alarm (3 spins 150 ms apart).
 * Using crown is the user's choice 1 (PLAN.md section 4): off by default
 * here, on in stock (config_defaultHapticFeedbackIntensity 3). The
 * org.asteroid.controls Haptics singleton reads the three keys: touch class =
 * master and Touch feedback, crown class = master and Using crown.
 */
SettingsPage {
    id: page
    objectName: "vibrationPage"
    title: qsTrId("id-vibration-page")

    // CR-10: the switch's key; unset until the user first turns it
    ConfigurationValue {
        id: silenceOffWrist
        key: "/org/asteroidos/notifications/silence-off-wrist"
        defaultValue: undefined
    }
    // retired (image 44): read to seed the switch while silence-off-wrist is
    // unset, never written
    ConfigurationValue {
        id: quietOnCharger
        key: "/org/asteroidos/notifications/quiet-on-charger"
        defaultValue: undefined
    }
    ConfigurationValue {
        id: vibration
        key: "/desktop/asteroid/vibration"
        defaultValue: true
    }
    ConfigurationValue {
        id: offBodyAvailable
        key: "/org/asteroidos/sensors/off-body-available"
        defaultValue: false
    }
    ConfigurationValue { id: ringIntensity; key: "/org/asteroidos/vibration/ring-intensity"; defaultValue: 3 }
    ConfigurationValue { id: notificationIntensity; key: "/org/asteroidos/vibration/notification-intensity"; defaultValue: 3 }
    ConfigurationValue { id: alarmIntensity; key: "/org/asteroidos/vibration/alarm-intensity"; defaultValue: 3 }
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
    readonly property bool offBody: on(offBodyAvailable.value)
    function isSet(v) { return v !== undefined && v !== null }
    // silence-off-wrist, else the earlier quiet-on-charger, else on (default)
    readonly property bool silenceOn: isSet(silenceOffWrist.value) ? on(silenceOffWrist.value)
                                    : isSet(quietOnCharger.value) ? on(quietOnCharger.value) : true
    // a stored intensity, 0 (off) to 3 (high)
    function level(v) {
        var n = Number(v)
        return isNaN(n) ? 3 : Math.max(0, Math.min(3, Math.round(n)))
    }

    // the class samples of the three sliders: one feedback object, so a new
    // sample cuts a running one
    property string previewEvent: ""
    NonGraphicalFeedback { id: preview; objectName: "vibrationPreviewFeedback" }
    Timer {
        id: previewDelay
        interval: sample.delay
        onTriggered: {
            preview.stop()
            preview.event = page.previewEvent
            preview.play()
        }
    }
    function previewVibration(name, newLevel) {
        if (!masterOn || newLevel <= 0)
            return
        previewEvent = "vib_preview_" + name
        previewDelay.restart()
    }

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
        title: page.offBody
               //% "Silence when off wrist"
               ? qsTrId("id-silence-off-wrist")
               //% "Silence watch while charging"
               : qsTrId("id-quiet-on-charger")
        control: "toggle"
        checked: page.silenceOn
        onClicked: silenceOffWrist.value = !page.silenceOn
    }
    SettingsText {
        objectName: "quietCaption"
        text: page.offBody
              //% "Notifications won't sound or vibrate when watch is off wrist or charging"
              ? qsTrId("id-silence-off-wrist-explain")
              //% "Notifications won't sound or vibrate while the watch is charging"
              : qsTrId("id-quiet-on-charger-explain")
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
    SettingsCategory {
        objectName: "ringVibrationCategory"
        //% "Ring vibration"
        text: qsTrId("id-ring-vibration")
    }
    SettingsSlider {
        objectName: "ringVibrationSlider"
        from: 0
        to: 3
        stepSize: 1
        active: page.masterOn
        value: page.level(ringIntensity.value)
        onMoved: (newValue) => {
            ringIntensity.value = newValue
            page.previewVibration("ring", newValue)
        }
    }
    SettingsCategory {
        objectName: "notificationVibrationCategory"
        //% "Notification vibration"
        text: qsTrId("id-notification-vibration")
    }
    SettingsSlider {
        objectName: "notificationVibrationSlider"
        from: 0
        to: 3
        stepSize: 1
        active: page.masterOn
        value: page.level(notificationIntensity.value)
        onMoved: (newValue) => {
            notificationIntensity.value = newValue
            page.previewVibration("notification", newValue)
        }
    }
    SettingsCategory {
        objectName: "alarmVibrationCategory"
        //% "Alarm vibration"
        text: qsTrId("id-alarm-vibration")
    }
    SettingsSlider {
        objectName: "alarmVibrationSlider"
        from: 0
        to: 3
        stepSize: 1
        active: page.masterOn
        value: page.level(alarmIntensity.value)
        onMoved: (newValue) => {
            alarmIntensity.value = newValue
            page.previewVibration("alarm", newValue)
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
