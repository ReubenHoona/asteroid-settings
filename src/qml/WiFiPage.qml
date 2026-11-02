/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Connman

// Settings > Connectivity > Wi-Fi (stock prefs_wifi.xml): the switch, the
// network the watch is on, Add network (the networks in range), Saved
// networks and About Wi-Fi, which says what eos-wifi-policy does with it
// (the stock text lists when Wi-Fi turns itself on and off).
SettingsPage {
    id: page
    objectName: "wifiPage"
    title: qsTrId("id-wifi-title")

    NetworkTechnology {
        id: wifiStatus
        path: "/net/connman/technology/wifi"
        onPoweredChanged: if (wifiStatus.powered) wifiModel.requestScan()
    }
    TechnologyModel {
        id: wifiModel
        name: "wifi"
    }
    Component.onCompleted: if (wifiStatus.powered) wifiModel.requestScan()

    Component { id: networksLayer; WiFiNetworksPage { } }
    Component { id: connectionDialog; WiFiConnectionDialog { } }

    SettingsChip {
        objectName: "wifiSwitch"
        title: qsTrId("id-wifi-title")
        control: "toggle"
        checked: wifiStatus.powered
        onClicked: wifiStatus.powered = !wifiStatus.powered
    }
    Repeater {
        model: wifiModel
        delegate: SettingsChip {
            objectName: "wifiCurrent"
            visible: wifiStatus.powered && modelData.connected
            //% "Hidden network"
            title: modelData.name ? modelData.name : qsTrId("id-wifi-hiddennetwork")
            //% "Connected"
            summary: qsTrId("id-wifi-connected")
            iconName: "ios-wifi"
            onClicked: layerStack.push(connectionDialog, { modelData: modelData })
        }
    }
    SettingsChip {
        objectName: "wifiAdd"
        visible: wifiStatus.powered
        //% "Add network"
        title: qsTrId("id-wifi-add")
        iconName: "ios-add"
        onClicked: layerStack.push(networksLayer, { model: wifiModel, saved: false, connectionDialog: connectionDialog })
    }
    SettingsChip {
        objectName: "wifiSaved"
        visible: wifiStatus.powered
        //% "Saved networks"
        title: qsTrId("id-wifi-saved-networks")
        iconName: "ios-bookmark-outline"
        onClicked: layerStack.push(networksLayer, { model: wifiModel, saved: true, connectionDialog: connectionDialog })
    }
    SettingsChip {
        objectName: "wifiAbout"
        //% "About Wi-Fi"
        title: qsTrId("id-wifi-about")
        iconName: "ios-information-circle-outline"
        onClicked: confirm.tell(qsTrId("id-wifi-about"),
                                //% "When Wi-Fi is on, your watch turns it off to save battery while it is connected to your phone, and back on when it needs it: \n\n• The phone is away\n• An app needs the internet\n• A lot of data is moving\n\nIf you turn Wi-Fi off here, it stays off."
                                qsTrId("id-wifi-about-message"))
    }
}
