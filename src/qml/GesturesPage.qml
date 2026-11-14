/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings
import Nemo.Configuration

// Settings > Gestures (stock PixelWatchNavRouteCollector$init$6.java:44-56;
// the Pixel Watch 2 has the Buttons page, so Rotate-to-wake and Screenshot
// are on Buttons, not here): Tilt-to-wake (mce's wrist gesture; turning it
// on asks first, as stock), Touch-to-wake (mce's tap gesture action, the
// touch panel's wake taps) and Long press watch face (the launcher opens
// its picker on a long press of the face while it is on). One-handed
// gestures and Raise to talk are the assistant's and not built.
// Bedtime, Theater and Battery saver hold tilt-to-wake off, Bedtime and
// Theater touch-to-wake: greyed out, off, with the mode as the summary, as
// stock. Touch lock moved to Display in CP3A.
SettingsPage {
    objectName: "gesturesPage"
    title: qsTrId("id-gestures-page")

    TiltToWake { id: tiltToWake }
    TapToWake { id: tapToWake }

    // stock Global gesture_touch_and_hold_watchface_enabled, default on;
    // the launcher ignores a long press on the face while it is false
    ConfigurationValue {
        id: longPressFace
        key: "/org/asteroidos/ux/long-press-face"
        defaultValue: true
    }

    SettingsChip {
        objectName: "tiltSwitch"
        active: tiltToWake.available && modeState.tiltHolder === ""
        title: qsTrId("id-tilt-to-wake")
        summary: modeState.summary(modeState.tiltHolder)
        control: "toggle"
        checked: tiltToWake.enabled && modeState.tiltHolder === ""
        onClicked: {
            if (tiltToWake.enabled) {
                tiltToWake.enabled = false
                return
            }
            // stock enable_tilt_to_wake_dialog_title / enable_tilt_to_wake
            //% "Turn on tilt-to-wake?"
            confirm.ask(qsTrId("id-tilt-confirm-title"),
                        //% "Tilt-to-wake reduces battery life."
                        qsTrId("id-tilt-confirm"),
                        function () { tiltToWake.enabled = true })
        }
    }
    SettingsChip {
        objectName: "touchSwitch"
        //% "Touch-to-wake"
        title: qsTrId("id-touch-to-wake")
        active: modeState.touchHolder === ""
        summary: modeState.summary(modeState.touchHolder)
        control: "toggle"
        checked: tapToWake.enabled && modeState.touchHolder === ""
        onClicked: tapToWake.enabled = !tapToWake.enabled
    }
    // TouchAndHoldToEditWatchfacePreference.java:140-152: a switch with a
    // caption; turning it off asks "Turn off?" first
    SettingsChip {
        objectName: "longPressSwitch"
        //% "Long press watch face"
        title: qsTrId("id-long-press-face")
        control: "toggle"
        checked: longPressFace.value !== false && longPressFace.value !== "false"
        onClicked: {
            if (!checked) {
                longPressFace.value = true
                return
            }
            //% "Turn off?"
            confirm.ask(qsTrId("id-turn-off"),
                        //% "You can still change and edit watch faces using Settings > Display > Change watch face."
                        qsTrId("id-long-press-face-off"),
                        function () { longPressFace.value = false })
        }
    }
    SettingsText {
        objectName: "longPressCaption"
        //% "Hold the watch face to change or edit it"
        text: qsTrId("id-long-press-face-explain")
    }
}
