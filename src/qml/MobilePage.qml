/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import Connman

// Settings > Connectivity > Mobile as stock's first rows (prefs_cellular.xml,
// MobileConnectionSettingsFragment, the LTE watch's page), built UI-first:
// the choices only write dconf keys, nothing here touches the modem (its
// consumer waits for the LTE milestone, M7).
//   Mobile        On / Automatic / Off, each with stock's question
//                 (pref_cellularToggle_*_diaglogTitle / Message); "Mobile
//                 cannot be turned on in airplane mode" while Airplane mode
//                 is on. Keys: the quick settings tile's mobile-enabled
//                 (true = Automatic or On, default true as the tile has it)
//                 and mobile-always-on (true = On).
//   Data roaming  asks "Attention / Allow data usage when roaming? Roaming
//                 charges may apply." when turned on, off at once.
// Stock's other rows (Data usage, SIM status, Call forwarding, Default SMS
// app, Phone number, Voicemail, Advanced, eSIM profiles) read the modem and
// the SIM: they come with M7.
SettingsPage {
    id: page
    objectName: "mobilePage"
    //% "Mobile"
    title: qsTrId("id-mobile-title")

    NetworkManager { id: connman }
    ConfigurationValue {
        id: mobileEnabled
        key: "/org/asteroidos/settings/mobile-enabled"
        defaultValue: true
    }
    ConfigurationValue {
        id: mobileAlways
        key: "/org/asteroidos/settings/mobile-always-on"
        defaultValue: false
    }
    ConfigurationValue {
        id: dataRoaming
        key: "/org/asteroidos/settings/data-roaming"
        defaultValue: false
    }

    // stock's order in the choice: On, Automatic, Off
    readonly property var labels: [
        //% "On"
        qsTrId("id-mobile-on"),
        //% "Automatic"
        qsTrId("id-wifi-automatic"),
        //% "Off"
        qsTrId("id-wifi-mode-off")]
    readonly property bool enabled_: mobileEnabled.value === true || mobileEnabled.value === "true"
    readonly property bool always: mobileAlways.value === true || mobileAlways.value === "true"
    readonly property int modeIndex: !enabled_ ? 2 : always ? 0 : 1
    readonly property bool roaming: dataRoaming.value === true || dataRoaming.value === "true"

    function applyMode(i) {
        mobileEnabled.value = i !== 2
        mobileAlways.value = i === 0
    }
    function chooseMode() {
        var chooser = app.choose(qsTrId("id-mobile-title"), page.labels, page.modeIndex, function (i) {
            if (i === page.modeIndex)
                return true
            if (i !== 2 && connman.offlineMode) {
                confirm.tell(qsTrId("id-mobile-title"),
                             //% "Mobile cannot be turned on in airplane mode"
                             qsTrId("id-mobile-no-airplane"))
                return false
            }
            var title, message
            if (i === 0) {
                //% "Turn on cellular?"
                title = qsTrId("id-mobile-on-title")
                //% "Make calls and send messages through your watch's mobile network. Turning on cellular for extended periods of time will use more battery power"
                message = qsTrId("id-mobile-on-message")
            } else if (i === 1) {
                //% "Turn cellular to automatic?"
                title = qsTrId("id-mobile-auto-title")
                //% "Watch will turn off mobile network when there is a Bluetooth connection to the phone or Wi-Fi to save battery power"
                message = qsTrId("id-mobile-auto-message")
            } else {
                //% "Turn off cellular?"
                title = qsTrId("id-mobile-off-title")
                //% "You won't be able to use apps that require a network connection"
                message = qsTrId("id-mobile-off-message")
            }
            confirm.ask(title, message, function () { page.applyMode(i); chooser.pop() })
            return false
        })
    }

    SettingsChip {
        objectName: "mobileModeItem"
        title: qsTrId("id-mobile-title")
        summary: page.labels[page.modeIndex]
        onClicked: page.chooseMode()
    }
    SettingsChip {
        objectName: "dataRoamingSwitch"
        //% "Data roaming"
        title: qsTrId("id-data-roaming")
        control: "toggle"
        checked: page.roaming
        onClicked: {
            if (page.roaming) {
                dataRoaming.value = false
                return
            }
            //% "Attention"
            confirm.ask(qsTrId("id-data-roaming-title"),
                        //% "Allow data usage when roaming? Roaming charges may apply."
                        qsTrId("id-data-roaming-message"),
                        function () { dataRoaming.value = true })
        }
    }
}
