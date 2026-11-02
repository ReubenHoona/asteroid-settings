/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Nemo.DBus

// Settings > Connectivity > Bluetooth (stock prefs_bluetooth.xml): the
// paired phone with its state (asteroid-btsyncd's phone status), then the
// Bluetooth switch, last as on the stock watch; turning it off asks first
// with the stock words. Pairing happens from the phone (Gadgetbridge), so
// there is no "Pair new device".
SettingsPage {
    id: page
    objectName: "bluetoothPage"
    title: qsTrId("id-bluetooth-page")

    BluetoothStatus { id: btStatus }

    property bool phoneConnected: false
    property int phoneBattery: -1

    DBusInterface {
        id: phoneDBus
        bus: DBus.SessionBus
        service: "org.asteroidos.btsyncd"
        path: "/org/asteroidos/btsyncd/phone"
        iface: "org.asteroidos.btsyncd.Phone"
        signalsEnabled: true

        function rcConnectedChanged(connected) {
            page.phoneConnected = connected
        }
        function rcBatteryChanged(level, charging) {
            page.phoneBattery = level
        }
    }
    Component.onCompleted: {
        phoneDBus.typedCall("Connected", [], function (c) { page.phoneConnected = c })
        phoneDBus.typedCall("BatteryLevel", [], function (l) { page.phoneBattery = l })
    }

    SettingsChip {
        objectName: "phoneItem"
        visible: btStatus.powered
        //% "Phone"
        title: qsTrId("id-bluetooth-phone")
        iconName: "ios-phone-portrait"
        clickable: false
        summary: !(page.phoneConnected || btStatus.connected) ? qsTrId("id-disconnected")
                 //% "Connected, %1% battery"
                 : page.phoneBattery >= 0 ? qsTrId("id-bluetooth-phone-battery").arg(page.phoneBattery)
                 : qsTrId("id-connected")
    }
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
                btStatus.powered = true
                return
            }
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
}
