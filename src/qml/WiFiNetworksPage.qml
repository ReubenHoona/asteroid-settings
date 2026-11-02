/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// Wi-Fi > Add network (the networks in range not saved yet: a tap connects,
// asking for the password) or Wi-Fi > Saved networks (a tap opens the
// network: disconnect, autoconnect, forget), as the stock pages.
SettingsPage {
    id: page
    objectName: saved ? "wifiSavedPage" : "wifiAddPage"
    title: saved ? qsTrId("id-wifi-saved-networks") : qsTrId("id-wifi-add")

    property var model: null
    property bool saved: false
    property var connectionDialog: null
    property int shown: 0

    function recount() {
        var n = 0
        for (var i = 0; i < networks.count; i++) {
            var it = networks.itemAt(i)
            if (it && it.visible)
                n++
        }
        shown = n
    }

    Repeater {
        id: networks
        model: page.model
        onCountChanged: Qt.callLater(page.recount)
        delegate: SettingsChip {
            visible: page.saved ? modelData.favorite : !modelData.favorite
            onVisibleChanged: Qt.callLater(page.recount)
            title: modelData.name ? modelData.name : qsTrId("id-wifi-hiddennetwork")
            summary: modelData.connected ? qsTrId("id-wifi-connected")
                     //% "Saved"
                     : modelData.favorite ? qsTrId("id-wifi-saved")
                     //% "Available"
                     : qsTrId("id-wifi-available")
            iconName: "ios-wifi-outline"
            onClicked: {
                layerStack.push(page.connectionDialog, { modelData: modelData })
                if (!page.saved && !modelData.connected)
                    modelData.requestConnect()
            }
        }
    }
    SettingsText {
        objectName: "wifiNone"
        visible: page.shown === 0
        horizontalAlignment: Text.AlignHCenter
        text: page.saved
              //% "No saved networks"
              ? qsTrId("id-wifi-none-saved")
              //% "No networks found"
              : qsTrId("id-wifi-none")
    }
}
