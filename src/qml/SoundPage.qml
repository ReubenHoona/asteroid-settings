/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings
import Nemo.Configuration

// Settings > Sound (stock prefs_sound.xml): "Media volume" and its inline
// slider, the watch's one volume (PulseAudio's main volume; each step plays
// the notification sound). Muted from the quick panel the volume is zero;
// a step up clears the mute, as the quick panel's slider does.
SettingsPage {
    objectName: "soundPage"
    title: qsTrId("id-sound-page")

    VolumeControl { id: volumeControl }
    ConfigurationValue {
        id: preMuteLevel
        key: "/desktop/asteroid/pre-mute-level"
        defaultValue: 80
    }

    //% "Media volume"
    SettingsCategory { text: qsTrId("id-media-volume") }
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
        }
    }
}
