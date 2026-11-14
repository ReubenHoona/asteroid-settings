/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Nemo.Configuration
import Connman

// Settings > Connectivity as stock (prefs_connectivity.xml, orders 10 to 80):
// Bluetooth (10), Share heart rate (15), Wi-Fi (30), Mobile (40), Airplane
// mode (70, a switch row, no icon). No NFC (60) and no Private DNS (80) on
// this watch. Stock's Airplane mode switch sends the change to the airplane
// service, greys the switch 100 ms later and enables it again 2000 ms after
// the tap (ConnectivitySettingsFragment delayAPMDisable / delayAPMEnable).
// Here the service is connman's offline mode (what the quick settings tile
// does): it turns Wi-Fi and the modem off, and Bluetooth stays on as on
// Wear OS (bluetooth_airplane_mode_toast) unless the person turned it off
// in airplane mode (Bluetooth page: "Bluetooth off in airplane mode").
SettingsPage {
    id: page
    objectName: "connectivityPage"
    title: qsTrId("id-connectivity-page")

    NetworkManager { id: connman }
    BluetoothStatus { id: btStatus }
    // "keep Bluetooth off next time you are in airplane mode" (Bluetooth page)
    ConfigurationValue {
        id: btOffInAirplane
        key: "/org/asteroidos/settings/bluetooth-off-in-airplane"
        defaultValue: false
    }
    // Mobile: the quick settings tile's key (on = Automatic) and "On" (always)
    ConfigurationValue {
        id: mobileEnabled
        key: "/org/asteroidos/settings/mobile-enabled"
        defaultValue: true
    }
    ConfigurationValue {
        id: mobileAlways
        key: "/org/asteroidos/settings/mobile-always-on"
        defaultValue: false
    }

    // the switch is greyed from 100 ms to 2000 ms after a tap (stock)
    property bool apmBusy: false
    function setAirplane(on) {
        connman.offlineMode = on
        apmDisable.restart()
        apmEnable.restart()
        if (on)
            btRestore.restart()
    }
    Timer {
        id: apmDisable
        interval: 100
        onTriggered: page.apmBusy = true
    }
    Timer {
        id: apmEnable
        interval: 2000
        onTriggered: page.apmBusy = false
    }
    // connman's offline mode powers Bluetooth down with the rest; it comes
    // back unless the person chose otherwise (the launcher's tile does the same)
    Timer {
        id: btRestore
        interval: 1500
        onTriggered: if (connman.offlineMode && !btStatus.powered && btOffInAirplane.value !== true)
                         btStatus.powered = true
    }

    readonly property string mobileSummary: !(mobileEnabled.value === true || mobileEnabled.value === "true")
                                            //% "Off"
                                            ? qsTrId("id-wifi-mode-off")
                                            : (mobileAlways.value === true || mobileAlways.value === "true")
                                              //% "On"
                                              ? qsTrId("id-mobile-on")
                                              //% "Automatic"
                                              : qsTrId("id-wifi-automatic")

    Component { id: shareHeartRateLayer; ShareHeartRatePage { } }
    Component { id: mobileLayer; MobilePage { } }

    SettingsChip {
        objectName: "bluetoothItem"
        title: qsTrId("id-bluetooth-page")
        iconName: "ios-bluetooth-outline"
        onClicked: layerStack.push(bluetoothLayer)
    }
    SettingsChip {
        objectName: "shareHeartRateItem"
        //% "Share heart rate"
        title: qsTrId("id-share-heart-rate")
        iconName: "ios-heart-outline"
        onClicked: layerStack.push(shareHeartRateLayer)
    }
    SettingsChip {
        objectName: "wifiItem"
        visible: DeviceSpecs.hasWlan
        //% "Wi-Fi"
        title: qsTrId("id-wifi-title")
        iconName: "ios-wifi-outline"
        onClicked: layerStack.push(wifiLayer)
    }
    SettingsChip {
        objectName: "mobileItem"
        //% "Mobile"
        title: qsTrId("id-mobile-title")
        summary: page.mobileSummary
        iconName: app.iconDir + "eos-settings-cellular"
        onClicked: layerStack.push(mobileLayer)
    }
    SettingsChip {
        objectName: "airplaneSwitch"
        //% "Airplane mode"
        title: qsTrId("id-airplane-mode")
        control: "toggle"
        checked: connman.offlineMode
        active: !page.apmBusy
        onClicked: page.setAirplane(!connman.offlineMode)
    }
}
