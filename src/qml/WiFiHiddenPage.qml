/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings

// Wi-Fi > Add network > Add hidden network. Stock's row (the last one of the
// list, the add icon) only says "To add a new network, open the Google Pixel
// Watch app on your phone" with Open on phone; there is no phone app that can
// take the name of a hidden network here (the relay's wifipw act answers a
// password for a name the watch already knows), so this is the gap's own
// alternative: a form on the watch, as stock's keyboard rows are: the name,
// the security (None, WPA/WPA2/WPA3, WEP) and, unless None, the password;
// Connect hands them to connman (Manager.ConnectService with the name as
// bytes), which probes for the network, creates the service and connects it.
SettingsPage {
    id: page
    objectName: "wifiHiddenPage"
    //% "Add hidden network"
    title: qsTrId("id-wifi-add-hidden")

    // connman's Security values
    readonly property var securityValues: ["psk", "none", "wep"]
    readonly property var securityLabels: [
        //% "WPA/WPA2/WPA3"
        qsTrId("id-wifi-security-psk"),
        //% "None"
        qsTrId("id-wifi-security-none"),
        //% "WEP"
        qsTrId("id-wifi-security-wep")]
    property int securityIndex: 0
    readonly property string security: securityValues[securityIndex]
    readonly property bool secured: security !== "none"
    readonly property bool valid: nameField.text.length > 0 && nameField.text.length <= 32
                                  && (!secured || passwordField.text.length >= (security === "psk" ? 8 : 5))

    HiddenWifi {
        id: hidden
        onFinished: (ok, error) => {
            if (ok) {
                // connman is connecting it: back to the list, where it shows
                layerStack.pop(layerStack.currentLayer)
                return
            }
            confirm.tell(error.indexOf("InvalidKey") >= 0
                         ? qsTrId("id-wifi-wrong-password")
                         //% "Wi-Fi connection failure"
                         : qsTrId("id-wifi-failure"), "")
        }
    }

    TextField {
        id: nameField
        objectName: "wifiHiddenName"
        width: parent.width
        //% "Network name"
        previewText: qsTrId("id-wifi-hidden-name")
    }
    SettingsChip {
        objectName: "wifiHiddenSecurity"
        //% "Security"
        title: qsTrId("id-wifi-hidden-security")
        summary: page.securityLabels[page.securityIndex]
        onClicked: app.choose(qsTrId("id-wifi-hidden-security"), page.securityLabels, page.securityIndex,
                              function (i) { page.securityIndex = i })
    }
    TextField {
        id: passwordField
        objectName: "wifiHiddenPassword"
        visible: page.secured
        width: parent.width
        echoMode: TextInput.Password
        //% "password"
        previewText: qsTrId("id-wifi-password-hint")
    }
    SettingsChip {
        objectName: "wifiHiddenConnect"
        //% "Connect"
        title: qsTrId("id-wifi-connect")
        summary: hidden.busy ? qsTrId("id-wifi-connecting") : ""
        iconName: "ios-checkmark"
        active: page.valid && !hidden.busy
        onClicked: hidden.connectNetwork(nameField.text, page.security, passwordField.text)
    }
}
