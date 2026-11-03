/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// Wi-Fi > Saved networks as stock (WifiSavedNetworkFragment,
// SavedNetworkPreference): the saved networks by name only; a tap opens one
// (WiFiSavedNetworkPage: Forget). connman lists a saved network only while
// it is in range, where stock lists every one it has.
SettingsPage {
    id: page
    objectName: "wifiSavedPage"
    title: qsTrId("id-wifi-saved-networks")

    property var model: null
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

    Component { id: networkLayer; WiFiSavedNetworkPage { } }

    Repeater {
        id: networks
        model: page.model
        onCountChanged: Qt.callLater(page.recount)
        delegate: SettingsChip {
            visible: modelData.favorite
            onVisibleChanged: Qt.callLater(page.recount)
            title: modelData.name ? modelData.name : qsTrId("id-wifi-hiddennetwork")
            onClicked: layerStack.push(networkLayer, { service: modelData })
        }
    }
    SettingsChip {
        objectName: "wifiNoneSaved"
        visible: page.shown === 0
        clickable: false
        title: qsTrId("id-wifi-none-saved")
    }
}
