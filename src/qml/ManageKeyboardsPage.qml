/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Input methods > Manage keyboards as stock CP3A: the category "Available
// virtual keyboard" and one switch per keyboard. The last one that is on
// stays on (a watch with no keyboard could not type), so its switch is
// greyed.
SettingsPage {
    id: page
    objectName: "manageKeyboardsPage"
    //% "Manage keyboards"
    title: qsTrId("id-manage-keyboards")

    ConfigurationValue {
        id: typing
        key: "/org/asteroidos/keyboard/typing-enabled"
        defaultValue: true
    }
    ConfigurationValue {
        id: handwriting
        key: "/org/asteroidos/keyboard/handwriting-enabled"
        defaultValue: true
    }

    SettingsCategory {
        //% "Available virtual keyboard"
        text: qsTrId("id-available-keyboards")
    }
    SettingsChip {
        objectName: "typingKeyboardSwitch"
        //% "Keyboard"
        title: qsTrId("id-keyboard-typing")
        control: "toggle"
        active: !typing.value || handwriting.value
        checked: typing.value
        onClicked: typing.value = !typing.value
    }
    SettingsChip {
        objectName: "handwritingKeyboardSwitch"
        //% "Handwriting"
        title: qsTrId("id-keyboard-handwriting")
        control: "toggle"
        active: !handwriting.value || typing.value
        checked: handwriting.value
        onClicked: handwriting.value = !handwriting.value
    }
}
