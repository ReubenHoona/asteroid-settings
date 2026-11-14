/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Safety & Emergency > Who to call for help (apps-misc-08): the number the
// SOS countdown calls, through the phone. Left empty it is the local
// emergency number. Only a dialable number is kept (digits, +, * and #).
SettingsPage {
    id: page
    objectName: "sosNumberPage"
    title: qsTrId("id-sos-who")

    ConfigurationValue {
        id: sosNumber
        key: "/org/asteroidos/safety/sos-number"
        defaultValue: ""
    }

    readonly property bool custom: String(sosNumber.value) !== ""

    // what is kept of an entered number
    function clean(text) {
        return String(text).replace(/[^0-9+*#]/g, "")
    }

    TextField {
        id: entry
        objectName: "sosNumberField"
        width: parent.width
        //% "Phone number"
        previewText: qsTrId("id-sos-number-hint")
        inputMethodHints: Qt.ImhDialableCharactersOnly
        text: String(sosNumber.value)
        onTextChanged: {
            var kept = page.clean(text)
            if (kept !== String(sosNumber.value) && (text === kept || text === ""))
                sosNumber.value = kept
        }
    }
    SettingsText {
        objectName: "sosNumberCaption"
        //% "Leave empty to call the local emergency number"
        text: qsTrId("id-sos-number-explain")
    }
    SettingsChip {
        objectName: "sosLocalItem"
        visible: page.custom
        //% "Use local emergency number"
        title: qsTrId("id-sos-use-local")
        onClicked: {
            sosNumber.value = ""
            entry.text = ""
        }
    }
}
