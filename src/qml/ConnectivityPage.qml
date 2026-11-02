/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils

// Settings > Connectivity (stock prefs_connectivity.xml): Bluetooth, Wi-Fi.
// No Mobile (the modem stays in low power mode, no plan), NFC, Airplane mode
// or Private DNS on this watch.
SettingsPage {
    objectName: "connectivityPage"
    title: qsTrId("id-connectivity-page")

    SettingsChip {
        objectName: "bluetoothItem"
        title: qsTrId("id-bluetooth-page")
        iconName: "ios-bluetooth-outline"
        onClicked: layerStack.push(bluetoothLayer)
    }
    SettingsChip {
        objectName: "wifiItem"
        visible: DeviceSpecs.hasWlan
        //% "Wi-Fi"
        title: qsTrId("id-wifi-title")
        iconName: "ios-wifi-outline"
        onClicked: layerStack.push(wifiLayer)
    }
}
