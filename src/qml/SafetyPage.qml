/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Safety & Emergency (settings-b-09, apps-misc-08). Stock opens
// the Personal Safety app: "Get help fast" with Emergency SOS ("You can call
// for help by quickly pressing the crown 5 times or more"), Ways to start SOS
// (Automatically call, Touch & hold to call), Who to call for help and the
// Countdown alarm (Play a sound). Fall Detection, Car Crash Detection, Safety
// Check, Emergency Sharing, Medical info and Emergency contacts need a
// Google account and stay out.
// The crown press count, the countdown screen and the call are the
// launcher's (W2-launcher-power-system, "Emergency SOS"); it reads
//   /org/asteroidos/safety/sos-enabled        b  true
//   /org/asteroidos/safety/sos-start          s  "auto" (the countdown ends in
//                                                the call) or "hold" (touch
//                                                and hold to call)
//   /org/asteroidos/safety/sos-number         s  "" (the local emergency
//                                                number) or the number to call
//   /org/asteroidos/safety/sos-countdown-sound b false
// Nothing here dials: the page only keeps the choices.
SettingsPage {
    id: page
    objectName: "safetyPage"
    title: qsTrId("id-safety-page")

    ConfigurationValue {
        id: sosEnabled
        key: "/org/asteroidos/safety/sos-enabled"
        defaultValue: true
    }
    ConfigurationValue {
        id: sosStart
        key: "/org/asteroidos/safety/sos-start"
        defaultValue: "auto"
    }
    ConfigurationValue {
        id: sosNumber
        key: "/org/asteroidos/safety/sos-number"
        defaultValue: ""
    }
    ConfigurationValue {
        id: countdownSound
        key: "/org/asteroidos/safety/sos-countdown-sound"
        defaultValue: false
    }

    Component { id: numberLayer; SosNumberPage { } }

    readonly property bool on: sosEnabled.value !== false && sosEnabled.value !== "false"
    readonly property var starts: ["auto", "hold"]
    readonly property var startNames: [
        //% "Automatically call"
        qsTrId("id-sos-auto"),
        //% "Touch & hold to call"
        qsTrId("id-sos-hold")]
    readonly property int startIndex: String(sosStart.value) === "hold" ? 1 : 0

    SettingsCategory {
        objectName: "getHelpCategory"
        //% "Get help fast"
        text: qsTrId("id-sos-get-help")
    }
    SettingsChip {
        objectName: "sosSwitch"
        //% "Emergency SOS"
        title: qsTrId("id-sos-title")
        control: "toggle"
        checked: page.on
        onClicked: sosEnabled.value = !page.on
    }
    SettingsText {
        objectName: "sosCaption"
        //% "You can call for help by quickly pressing the crown 5 times or more"
        text: qsTrId("id-sos-summary")
    }
    SettingsChip {
        objectName: "sosStartItem"
        active: page.on
        //% "Ways to start SOS"
        title: qsTrId("id-sos-ways")
        summary: page.startNames[page.startIndex]
        onClicked: app.choose(qsTrId("id-sos-ways"), page.startNames, page.startIndex,
                              function (i) { sosStart.value = page.starts[i] })
    }
    SettingsChip {
        objectName: "sosNumberItem"
        active: page.on
        //% "Who to call for help"
        title: qsTrId("id-sos-who")
        //% "Local emergency number"
        summary: String(sosNumber.value) !== "" ? String(sosNumber.value) : qsTrId("id-sos-local-number")
        onClicked: layerStack.push(numberLayer)
    }
    SettingsChip {
        objectName: "sosSoundSwitch"
        active: page.on
        //% "Countdown alarm"
        title: qsTrId("id-sos-sound")
        //% "Play a sound"
        summary: qsTrId("id-sos-sound-explain")
        control: "toggle"
        checked: countdownSound.value === true || countdownSound.value === "true"
        onClicked: countdownSound.value = !checked
    }
}
