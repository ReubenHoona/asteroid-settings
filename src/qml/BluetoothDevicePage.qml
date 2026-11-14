/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// A paired device (stock BondedBluetoothDeviceFragment,
// prefs_bluetooth_bonded_device.xml): its name as the title, Connect or
// Disconnect (by its state), Forget, Cancel. Stock's LE Audio switch and the
// audio device type row are hidden on CP3A for most devices and need
// profiles this watch does not have.
SettingsPage {
    id: page
    objectName: "bluetoothDevicePage"
    title: info.name !== undefined ? info.name : ""

    // the model of the Bluetooth page and the device's path
    property var devices: null
    property string devicePath: ""
    // the device's state, re-read when anything about a device changes
    readonly property var info: {
        if (!devices)
            return ({})
        devices.revision
        return devices.device(devicePath)
    }
    readonly property bool gone: devices !== null && info.name === undefined
    onGoneChanged: if (gone && layerStack.currentLayer === page) layerStack.pop(layerStack.currentLayer)

    SettingsChip {
        objectName: "bluetoothConnectItem"
        title: info.connected
               //% "Disconnect"
               ? qsTrId("id-bluetooth-disconnect")
               //% "Connect"
               : qsTrId("id-bluetooth-connect")
        summary: info.connecting ? qsTrId("id-bluetooth-connecting") : ""
        active: !info.connecting
        onClicked: {
            if (info.connected)
                page.devices.disconnectDevice(page.devicePath)
            else
                page.devices.connectDevice(page.devicePath)
        }
    }
    SettingsChip {
        objectName: "bluetoothForgetItem"
        //% "Forget"
        title: qsTrId("id-bluetooth-forget")
        onClicked: {
            // back first (stock finishes at once); the page leaves by itself
            // too when BlueZ drops the device, which must not pop twice
            var d = page.devices
            var p = page.devicePath
            layerStack.pop(layerStack.currentLayer)
            d.forget(p)
        }
    }
    SettingsChip {
        objectName: "bluetoothCancelItem"
        //% "Cancel"
        title: qsTrId("id-bluetooth-pair-cancel")
        onClicked: layerStack.pop(layerStack.currentLayer)
    }
}
