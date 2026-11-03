/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// A saved network as stock (prefs_wifi_saved_network_details.xml): its name
// as the title and Forget, which asks first ("Forget network %1?", ✕ / ✓).
// Stock's "Enable Wi-Fi MAC randomization" is hidden where the device cannot
// do it (isConnectedMacRandomizationSupported), as connman here cannot.
SettingsPage {
    id: page
    objectName: "wifiSavedNetworkPage"
    title: service && service.name ? service.name : qsTrId("id-wifi-hiddennetwork")

    property var service: null

    SettingsChip {
        objectName: "wifiForget"
        //% "Forget"
        title: qsTrId("id-wifi-forget")
        iconName: "ios-trash-outline"
        onClicked: confirm.ask(
                       //% "Forget network %1?"
                       qsTrId("id-wifi-forget-confirm").arg(page.title), "",
                       function () {
                           page.service.remove()
                           layerStack.pop(layerStack.currentLayer)
                       })
    }
}
