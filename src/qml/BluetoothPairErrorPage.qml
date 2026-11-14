/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// A pairing that failed (stock BluetoothSettingsFragmentBase, the
// mReconnectDialog: WearAlertDialog "Couldn't connect with %1$s", the message
// "Make sure device is turned on, in range and searching for a Bluetooth
// connection." and two chips, Try again and Cancel).
SettingsPage {
    id: page
    objectName: "bluetoothPairErrorPage"
    //% "Couldn't connect with %1"
    title: qsTrId("id-bluetooth-pair-error").arg(deviceName)

    property var devices: null
    property string devicePath: ""
    property string deviceName: ""

    SettingsText {
        objectName: "bluetoothPairErrorText"
        horizontalAlignment: Text.AlignHCenter
        //% "Make sure device is turned on, in range and searching for a Bluetooth connection."
        text: qsTrId("id-bluetooth-pair-failed")
    }
    SettingsChip {
        objectName: "bluetoothPairRetry"
        //% "Try again"
        title: qsTrId("id-bluetooth-pair-retry")
        iconName: "ios-refresh"
        onClicked: {
            var d = page.devices
            var p = page.devicePath
            layerStack.pop(layerStack.currentLayer)
            if (d)
                d.pair(p)
        }
    }
    SettingsChip {
        objectName: "bluetoothPairCancel"
        //% "Cancel"
        title: qsTrId("id-bluetooth-pair-cancel")
        iconName: "ios-close"
        onClicked: layerStack.pop(layerStack.currentLayer)
    }
}
