/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Nemo.Configuration
import Connman
import org.asteroid.settings
import "BtIcons.js" as BtIcons

// Settings > Connectivity > Bluetooth as stock (prefs_bluetooth_ingestion.xml,
// BluetoothSettingsFragmentBase, orders 100 to 400):
//   Bluetooth           the switch first; off asks "Turn off Bluetooth?" (in
//                       airplane mode "Bluetooth off in airplane mode",
//                       which also remembers to keep it off next time),
//                       on asks nothing and says "Turning on..." meanwhile
//   Pair new device     the scan page (BluetoothScanPage)
//   Devices             one row per paired device: its name, "Connected" /
//                       "Disconnected" / "Connecting…" / "Pairing…", the icon
//                       of its class; a tap opens its page (Connect or
//                       Disconnect, Forget)
//   Answer calls on watch  with "Audio plays through watch speaker"
// The rows under the switch stay and grey out while Bluetooth is off. The
// devices are BlueZ's (BluetoothDevices, signals only, no polling).
SettingsPage {
    id: page
    objectName: "bluetoothPage"
    title: qsTrId("id-bluetooth-page")

    BluetoothStatus { id: btStatus }
    BluetoothDevices { id: devices; filter: "paired" }
    NetworkManager { id: connman }
    // the call audio of the watch (HFP): stock's switch is on by default
    // (bluetooth_disabled_profiles without the HFP bit)
    ConfigurationValue {
        id: callsOnWatch
        key: "/org/asteroidos/btsyncd/calls-on-watch"
        defaultValue: true
    }
    ConfigurationValue {
        id: btOffInAirplane
        key: "/org/asteroidos/settings/bluetooth-off-in-airplane"
        defaultValue: false
    }

    readonly property bool on: btStatus.powered
    readonly property bool callsOn: callsOnWatch.value === true || callsOnWatch.value === "true"

    function stateText(connected, connecting, pairing) {
        if (pairing)
            //% "Pairing…"
            return qsTrId("id-bluetooth-pairing")
        if (connecting)
            //% "Connecting…"
            return qsTrId("id-bluetooth-connecting")
        if (connected)
            //% "Connected"
            return qsTrId("id-bluetooth-device-connected")
        //% "Disconnected"
        return qsTrId("id-bluetooth-device-disconnected")
    }

    Component { id: scanLayer; BluetoothScanPage { } }
    Component { id: deviceLayer; BluetoothDevicePage { } }

    SettingsChip {
        id: btSwitch
        objectName: "bluetoothSwitch"
        title: qsTrId("id-bluetooth-page")
        control: "toggle"
        checked: btStatus.powered
        //% "Turning on..."
        summary: btStatus.powered || !turningOn ? "" : qsTrId("id-bluetooth-turning-on")
        property bool turningOn: false
        onClicked: {
            if (!btStatus.powered) {
                turningOn = true
                if (connman.offlineMode)
                    btOffInAirplane.value = false
                btStatus.powered = true
                return
            }
            if (connman.offlineMode)
                //% "Bluetooth off in airplane mode"
                confirm.ask(qsTrId("id-bluetooth-off-airplane-title"),
                            //% "Turning off Bluetooth disconnects your device from the phone. Your device will remember to keep it off next time you are in airplane mode"
                            qsTrId("id-bluetooth-off-airplane-message"),
                            function () { btOffInAirplane.value = true; btStatus.powered = false })
            else
                //% "Turn off Bluetooth?"
                confirm.ask(qsTrId("id-bluetooth-off-title"),
                            //% "Watch will be disconnected from the phone. Turning off Bluetooth for extended periods of time will use more battery power."
                            qsTrId("id-bluetooth-off-message"),
                            function () { btStatus.powered = false })
        }
        Connections {
            target: btStatus
            function onPoweredChanged() { if (btStatus.powered) btSwitch.turningOn = false }
        }
    }
    SettingsChip {
        objectName: "bluetoothPairItem"
        //% "Pair new device"
        title: qsTrId("id-bluetooth-pair-new")
        iconName: "ios-search-outline"
        active: page.on
        onClicked: layerStack.push(scanLayer)
    }
    SettingsCategory {
        objectName: "devicesCategory"
        //% "Devices"
        text: qsTrId("id-bluetooth-devices")
    }
    Repeater {
        id: deviceRows
        model: devices
        delegate: SettingsChip {
            objectName: "bluetoothDevice"
            active: page.on
            title: model.name
            summary: page.stateText(model.connected, model.connecting, model.pairing)
            iconName: BtIcons.deviceIcon(model.icon)
            onClicked: layerStack.push(deviceLayer, { devices: devices, devicePath: model.path })
        }
    }
    SettingsChip {
        objectName: "answerCallsSwitch"
        //% "Answer calls on watch"
        title: qsTrId("id-bluetooth-answer-calls")
        control: "toggle"
        checked: page.callsOn
        active: page.on
        onClicked: callsOnWatch.value = !page.callsOn
    }
    SettingsText {
        objectName: "answerCallsText"
        //% "Audio plays through watch speaker"
        text: qsTrId("id-bluetooth-answer-calls-text")
        color: page.on ? Theme.color.onSurfaceVariant
                       : Qt.rgba(Theme.color.onSurface.r, Theme.color.onSurface.g, Theme.color.onSurface.b, Theme.alpha.disabledContent)
    }
}
