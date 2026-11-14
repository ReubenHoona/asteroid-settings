/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Apps & notifications > Assistant (assistant-voice-22). Stock's assistant
// settings (qta/qtg: addPressAndHold, addGeneral, addAbout, addTurnOff), in
// its order: Press & hold (a switch, "Hold down side button to talk"), the
// header General, Speech output (a switch with its caption), the voice
// recognition of this watch (Voice recognition, kept), About and Turn off
// Assistant, which asks first ("Turn off Assistant?" with the stock
// message). Our assistant is not Gemini or Google Assistant: the labels name
// "Assistant".
// Keys:
//   /org/asteroidos/assistant/enabled        b  true. Off: a side button hold
//                                              does nothing and the app entry
//                                              is hidden (launcher)
//   /org/asteroidos/assistant/press-and-hold b  true, the side button hold
//   /org/asteroidos/assistant/speak          b  Speech output, the assistant
//                                              speaks its answers; off until
//                                              a speech engine ships
//   /org/asteroidos/voice/recognition        s  "watch", "auto", "phone": the
//                                              assistant and asteroid-btsyncd
//                                              read it each time: "watch"
//                                              (also unset or anything else)
//                                              the watch's own recogniser,
//                                              the phone's only when the
//                                              watch's cannot load; "auto"
//                                              the phone's while it is
//                                              connected and can listen,
//                                              else the watch's; "phone" the
//                                              phone's only
SettingsPage {
    id: page
    objectName: "assistantPage"
    title: qsTrId("id-assistant-page")

    ConfigurationValue {
        id: recognition
        key: "/org/asteroidos/voice/recognition"
        defaultValue: ""
    }
    ConfigurationValue {
        id: assistantEnabled
        key: "/org/asteroidos/assistant/enabled"
        defaultValue: true
    }
    ConfigurationValue {
        id: pressAndHold
        key: "/org/asteroidos/assistant/press-and-hold"
        defaultValue: true
    }
    ConfigurationValue {
        id: speak
        key: "/org/asteroidos/assistant/speak"
        defaultValue: false
    }

    Component { id: aboutLayer; AssistantAboutPage { } }

    readonly property bool on: assistantEnabled.value !== false && assistantEnabled.value !== "false"

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
        objectName: "pressAndHoldSwitch"
        active: page.on
        //% "Press & hold"
        title: qsTrId("id-assistant-press-hold")
        control: "toggle"
        checked: page.on && pressAndHold.value !== false && pressAndHold.value !== "false"
        onClicked: pressAndHold.value = !checked
    }
    SettingsText {
        objectName: "pressAndHoldCaption"
        //% "Hold down side button to talk"
        text: qsTrId("id-assistant-press-hold-explain")
    }
    SettingsCategory {
        objectName: "generalCategory"
        //% "General"
        text: qsTrId("id-general-page")
    }
    SettingsChip {
        objectName: "speechOutputSwitch"
        active: page.on
        //% "Speech output"
        title: qsTrId("id-speech-output")
        control: "toggle"
        checked: page.on && (speak.value === true || speak.value === "true")
        onClicked: speak.value = !checked
    }
    SettingsText {
        objectName: "speechOutputCaption"
        //% "Assistant will speak responses, including when Do Not Disturb is on"
        text: qsTrId("id-speech-output-explain")
    }
    SettingsChip {
        objectName: "recognitionItem"
        active: page.on
        //% "Voice recognition"
        title: qsTrId("id-voice-recognition")
        summary: page.labels[page.current]
        onClicked: app.choose(qsTrId("id-voice-recognition"), page.labels, page.current,
                              function (i) { recognition.value = page.values[i] }, page.explanations)
    }
    SettingsChip {
        objectName: "aboutItem"
        title: qsTrId("id-about-page")
        onClicked: layerStack.push(aboutLayer)
    }
    SettingsChip {
        objectName: "turnOffItem"
        //% "Turn off Assistant"
        title: page.on ? qsTrId("id-assistant-turn-off")
                       //% "Turn on Assistant"
                       : qsTrId("id-assistant-turn-on")
        onClicked: {
            if (!page.on) {
                assistantEnabled.value = true
                return
            }
            //% "Turn off Assistant?"
            confirm.ask(qsTrId("id-assistant-turn-off-title"),
                        //% "When turned off, you won't be able to use Assistant to do things like set alarms and timers, message your contacts, and more"
                        qsTrId("id-assistant-turn-off-message"),
                        function () { assistantEnabled.value = false })
        }
    }
}
