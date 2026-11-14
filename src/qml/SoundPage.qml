/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings
import Nemo.Configuration

/*
 * Settings > Sound in stock CP3A order (SoundScreenViewModel,
 * ClockworkNavRouteCollector$init$65.java):
 * - the switch Mute ring & notifications (MuteRingAndNotificationSwitch-
 *   Preference: ringer VIBRATE on, NORMAL off; no caption) on
 *   /org/asteroidos/sound/mute-ring-notifications, which ngfd's profile plugin
 *   reads to drop the sounds of notifications (W1-engine-haptics, default
 *   true);
 * - sliders with their own header label, Ring volume, Notification volume,
 *   Alarm volume (stream steps and lowest step of AudioService:
 *   MAX_STREAM_VOLUME {call 5, ring 7, alarm 7, notification 7} and
 *   MIN_STREAM_VOLUME {call 1}; the alarm starts at 0 as stock's
 *   config_audio_alarm_min_vol), kept as percent of the maximum in
 *   /org/asteroidos/sound/<role>-volume, the defaults those of AOSP
 *   (ring 5 and notification 5 of 7 as config_audio_ring_vol_default and
 *   config_audio_notif_vol_default, alarm 6 of 7, call 4 of 5);
 * - the switch Mute alarm with its caption (MuteAlarmSwitchPreference,
 *   mute_alarm_stream_with_ringer_mode_user_preference, default off) on
 *   /org/asteroidos/sound/mute-alarm, honoured by the alarm;
 * - Media volume, the watch's main volume (PulseAudio's, 0-100 in tens), and
 *   Call volume;
 * - the switches Screen unlocking sound and Charging sounds (stock Global
 *   screen_unlock_sound_enabled and wear_charging_sounds_enabled, both on)
 *   on /org/asteroidos/sound/screen-unlock and .../charging, read by whatever
 *   plays them.
 * Hidden until /org/asteroidos/sound/volume-control-supported is true (CR-31):
 * Ring, Notification and Alarm volume and Mute alarm, which no reader honours
 * yet.
 * Not built: Accessibility volume (no screen reader stream yet).
 * Every volume step plays volume_step (volume_step_max at the maximum) on its
 * own stream (VolumeStepSound, haptics-sounds-14), and every slider step the
 * haptic tick of the Wear slider (SettingsSlider, haptics-sounds-04). Muted
 * from the quick panel the media volume is zero; a step up clears the mute,
 * as the quick panel's slider does.
 */
SettingsPage {
    id: page
    objectName: "soundPage"
    title: qsTrId("id-sound-page")

    // the per-stream sliders: steps and lowest step, defaults in percent
    readonly property var streams: ({
        "ring":         { "from": 0, "to": 7, "percent": 71 },
        "notification": { "from": 0, "to": 7, "percent": 71 },
        "alarm":        { "from": 0, "to": 7, "percent": 86 },
        "call":         { "from": 1, "to": 5, "percent": 80 }
    })
    function on(v) { return v === true || v === "true" }
    // percent of the maximum <-> step of the stream
    function stepOf(role, percent) {
        var s = streams[role]
        var n = Number(percent)
        if (isNaN(n))
            n = s.percent
        return Math.max(s.from, Math.min(s.to, Math.round(n * s.to / 100)))
    }
    function percentOf(role, step) {
        return Math.round(step * 100 / streams[role].to)
    }
    function setStream(role, conf, step) {
        conf.value = percentOf(role, step)
        stepSound.step(role, step === streams[role].to)
    }

    VolumeControl { id: volumeControl }
    VolumeStepSound { id: stepSound; objectName: "volumeStepSound" }
    ConfigurationValue {
        id: preMuteLevel
        key: "/desktop/asteroid/pre-mute-level"
        defaultValue: 80
    }
    ConfigurationValue {
        id: muteRing
        key: "/org/asteroidos/sound/mute-ring-notifications"
        defaultValue: true
    }
    // gate (CR-31): the ring, notification and alarm volumes and Mute alarm
    // do nothing until ngfd's profile plug-in reads them; its package sets
    // this true. Call volume (btsyncd) and Media volume stay.
    ConfigurationValue { id: volumeControlSupported; key: "/org/asteroidos/sound/volume-control-supported"; defaultValue: false }
    readonly property bool streamsOn: on(volumeControlSupported.value)
    ConfigurationValue { id: ringVolume; key: "/org/asteroidos/sound/ring-volume"; defaultValue: page.streams.ring.percent }
    ConfigurationValue { id: notificationVolume; key: "/org/asteroidos/sound/notification-volume"; defaultValue: page.streams.notification.percent }
    ConfigurationValue { id: alarmVolume; key: "/org/asteroidos/sound/alarm-volume"; defaultValue: page.streams.alarm.percent }
    ConfigurationValue { id: callVolume; key: "/org/asteroidos/sound/call-volume"; defaultValue: page.streams.call.percent }
    ConfigurationValue { id: muteAlarm; key: "/org/asteroidos/sound/mute-alarm"; defaultValue: false }
    ConfigurationValue { id: unlockSound; key: "/org/asteroidos/sound/screen-unlock"; defaultValue: true }
    ConfigurationValue { id: chargingSounds; key: "/org/asteroidos/sound/charging"; defaultValue: true }

    SettingsChip {
        objectName: "muteRingSwitch"
        //% "Mute ring & notifications"
        title: qsTrId("id-mute-ring-notifications")
        control: "toggle"
        checked: page.on(muteRing.value)
        onClicked: muteRing.value = !page.on(muteRing.value)
    }

    SettingsCategory {
        objectName: "ringVolumeCategory"
        visible: page.streamsOn
        //% "Ring volume"
        text: qsTrId("id-ring-volume")
    }
    SettingsSlider {
        objectName: "ringVolumeSlider"
        visible: page.streamsOn
        from: page.streams.ring.from
        to: page.streams.ring.to
        stepSize: 1
        value: page.stepOf("ring", ringVolume.value)
        onMoved: (newValue) => page.setStream("ring", ringVolume, newValue)
    }
    SettingsCategory {
        objectName: "notificationVolumeCategory"
        visible: page.streamsOn
        //% "Notification volume"
        text: qsTrId("id-notification-volume")
    }
    SettingsSlider {
        objectName: "notificationVolumeSlider"
        visible: page.streamsOn
        from: page.streams.notification.from
        to: page.streams.notification.to
        stepSize: 1
        value: page.stepOf("notification", notificationVolume.value)
        onMoved: (newValue) => page.setStream("notification", notificationVolume, newValue)
    }
    SettingsCategory {
        objectName: "alarmVolumeCategory"
        visible: page.streamsOn
        //% "Alarm volume"
        text: qsTrId("id-alarm-volume")
    }
    SettingsSlider {
        objectName: "alarmVolumeSlider"
        visible: page.streamsOn
        from: page.streams.alarm.from
        to: page.streams.alarm.to
        stepSize: 1
        value: page.stepOf("alarm", alarmVolume.value)
        onMoved: (newValue) => page.setStream("alarm", alarmVolume, newValue)
    }

    SettingsChip {
        objectName: "muteAlarmSwitch"
        visible: page.streamsOn
        //% "Mute alarm"
        title: qsTrId("id-mute-alarm")
        control: "toggle"
        checked: page.on(muteAlarm.value)
        onClicked: muteAlarm.value = !page.on(muteAlarm.value)
    }
    SettingsText {
        objectName: "muteAlarmCaption"
        visible: page.streamsOn
        //% "Silences alarm when Mute ring is enabled while worn. Watch will still vibrate"
        text: qsTrId("id-mute-alarm-explain")
    }

    //% "Media volume"
    SettingsCategory { objectName: "mediaVolumeCategory"; text: qsTrId("id-media-volume") }
    SettingsSlider {
        objectName: "volumeSlider"
        from: 0
        to: 100
        stepSize: 10
        value: volumeControl.volume
        onMoved: (newValue) => {
            if (newValue > 0 && preMuteLevel.value > 0)
                preMuteLevel.value = 0
            volumeControl.volume = newValue
            stepSound.step("media", newValue === 100)
        }
    }

    SettingsCategory {
        objectName: "callVolumeCategory"
        //% "Call volume"
        text: qsTrId("id-call-volume")
    }
    SettingsSlider {
        objectName: "callVolumeSlider"
        from: page.streams.call.from
        to: page.streams.call.to
        stepSize: 1
        value: page.stepOf("call", callVolume.value)
        onMoved: (newValue) => page.setStream("call", callVolume, newValue)
    }

    SettingsChip {
        objectName: "unlockSoundSwitch"
        //% "Screen unlocking sound"
        title: qsTrId("id-screen-unlock-sound")
        control: "toggle"
        checked: page.on(unlockSound.value)
        onClicked: unlockSound.value = !page.on(unlockSound.value)
    }
    SettingsChip {
        objectName: "chargingSoundsSwitch"
        //% "Charging sounds"
        title: qsTrId("id-charging-sounds")
        control: "toggle"
        checked: page.on(chargingSounds.value)
        onClicked: chargingSounds.value = !page.on(chargingSounds.value)
    }
}
