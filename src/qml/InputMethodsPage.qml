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
    // the typing keyboard's two options (CR-24; WearKeyboard reads both)
    ConfigurationValue {
        id: keyPopup
        key: "/org/asteroidos/ux/keyboard-popup"
        defaultValue: true
    }
    ConfigurationValue {
        id: keyGlide
        key: "/org/asteroidos/ux/keyboard-glide"
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
    // stock Gboard's Popup on keypress and Glide typing (setting_popup_on_
    // keypress_title, setting_gesture_input_title and _summary): options of
    // the typing keyboard, so they show while it is on
    SettingsChip {
        objectName: "keyPopupSwitch"
        visible: typing.value
        //% "Popup on keypress"
        title: qsTrId("id-keyboard-popup")
        control: "toggle"
        checked: keyPopup.value
        onClicked: keyPopup.value = !keyPopup.value
    }
    SettingsChip {
        objectName: "keyGlideSwitch"
        visible: typing.value
        //% "Glide typing"
        title: qsTrId("id-keyboard-glide")
        control: "toggle"
        checked: keyGlide.value
        onClicked: keyGlide.value = !keyGlide.value
    }
    SettingsText {
        objectName: "keyGlideCaption"
        visible: typing.value
        //% "Input a word by sliding through the letters"
        text: qsTrId("id-keyboard-glide-explain")
    }
    SettingsChip {
        objectName: "manageKeyboardsItem"
        //% "Manage keyboards"
        title: qsTrId("id-manage-keyboards")
        iconName: "ios-add"
        onClicked: layerStack.push(manageKeyboardsLayer)
    }
}
