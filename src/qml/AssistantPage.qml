/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Apps & notifications > Assistant (stock prefs_apps.xml keeps the assistant's
// settings there): Voice recognition, which recogniser hears what is said to
// the assistant and the keyboard's microphone. The assistant and
// asteroid-btsyncd read dconf /org/asteroidos/voice/recognition each time:
// "watch" (also unset or anything else) the watch's own, the phone's only
// when the watch's cannot load; "auto" the phone's while it is connected and
// can listen, else the watch's; "phone" the phone's only.
SettingsPage {
    id: page
    objectName: "assistantPage"
    title: qsTrId("id-assistant-page")

    ConfigurationValue {
        id: recognition
        key: "/org/asteroidos/voice/recognition"
        defaultValue: ""
    }

    readonly property var values: ["watch", "auto", "phone"]
    readonly property var labels: [
        //% "On the watch"
        qsTrId("id-recognition-watch"),
        //% "Phone when connected"
        qsTrId("id-recognition-auto"),
        //% "Phone only"
        qsTrId("id-recognition-phone")
    ]
    readonly property var explanations: [
        //% "Works without the phone"
        qsTrId("id-recognition-watch-explain"),
        //% "The watch when the phone is away"
        qsTrId("id-recognition-auto-explain"),
        //% "Needs the phone"
        qsTrId("id-recognition-phone-explain")
    ]
    readonly property int current: Math.max(0, values.indexOf(String(recognition.value)))

    SettingsChip {
        objectName: "recognitionItem"
        //% "Voice recognition"
        title: qsTrId("id-voice-recognition")
        summary: page.labels[page.current]
        onClicked: app.choose(qsTrId("id-voice-recognition"), page.labels, page.current,
                              function (i) { recognition.value = page.values[i] }, page.explanations)
    }
}
