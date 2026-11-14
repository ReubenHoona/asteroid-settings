/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// System > Input methods as stock CP3A (InputMethodPreference:52-55,
// PixelWatchNavRouteCollector$init$10:81-88, SmartReplyGroupPreference:
// 169-187): Smart Reply, the enabled keyboards, and Manage keyboards (the
// plus row), which opens "Available virtual keyboard". Smart Reply is a
// switch here (stock offers AI Generated / Basic / None where the Pixel flag
// allows; this watch has the one kind, the replies the phone sends):
// /org/asteroidos/notifications/smart-reply, on by default, shows the reply
// chips on notifications. The keyboards are the two this watch has, the
// typing keyboard and Handwriting; each can be left out of the keyboard
// switcher (/org/asteroidos/keyboard/typing-enabled, handwriting-enabled).
SettingsPage {
    id: page
    objectName: "inputMethodsPage"
    //% "Input methods"
    title: qsTrId("id-input-methods-page")

    ConfigurationValue {
        id: smartReply
        key: "/org/asteroidos/notifications/smart-reply"
        defaultValue: true
    }
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

    SettingsChip {
        objectName: "smartReplySwitch"
        //% "Smart Reply"
        title: qsTrId("id-smart-reply")
        control: "toggle"
        checked: smartReply.value
        onClicked: smartReply.value = !smartReply.value
    }
    SettingsChip {
        objectName: "typingKeyboardRow"
        visible: typing.value
        clickable: false
        //% "Keyboard"
        title: qsTrId("id-keyboard-typing")
    }
    SettingsChip {
        objectName: "handwritingKeyboardRow"
        visible: handwriting.value
        clickable: false
        //% "Handwriting"
        title: qsTrId("id-keyboard-handwriting")
    }
    SettingsChip {
        objectName: "manageKeyboardsItem"
        //% "Manage keyboards"
        title: qsTrId("id-manage-keyboards")
        iconName: "ios-add"
        onClicked: layerStack.push(manageKeyboardsLayer)
    }
}
