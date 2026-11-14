/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Connman
import Nemo.Configuration
import "BtIcons.js" as BtIcons
import "WiFiMemory.js" as WiFiMemory

// Settings > Connectivity > Wi-Fi as stock (prefs_wifi.xml, WifiSettingsImpl).
// The switch is the setting, Automatic or Off, not the radio: with Automatic
// eos-wifi-policy turns the radio on and off as Wear OS does (off while the
// phone is connected over Bluetooth), with Off it stays off. The setting is
// /org/asteroidos/eos-wifi/enabled, which the policy applies and keeps in step
// with the quick panel; until it is written it follows the policy's own mark.
// While the setting is Automatic: the network the watch is on ("Connected", a
// tap shows its addresses) or else the last one it used ("Last used", no
// tap), Add network and Saved networks. About Wi-Fi says what the policy does.
// While this page is open the radio stays up, as stock's setWifiHoldUp: a
// time stamp in /org/asteroidos/eos-wifi/settings-open every 20 s, which the
// policy takes as a reason for Wi-Fi for 45 s.
SettingsPage {
    id: page
    objectName: "wifiPage"
    title: qsTrId("id-wifi-title")

    readonly property bool on: wifiEnabled.value === true || wifiEnabled.value === "true"
    property string connectedName: ""
    property int savedCount: 0

    function serviceName(s) {
        //% "Hidden network"
        return s.name ? s.name : qsTrId("id-wifi-hiddennetwork")
    }
    function secured(s) {
        return s.security && s.security.length > 0 && s.security[0] !== "none"
    }
    function recount() {
        var name = "", saved = 0
        for (var i = 0; i < services.count; i++) {
            var it = services.itemAt(i)
            if (!it)
                continue
            if (it.isConnected && name === "")
                name = it.title
            if (it.isFavorite)
                saved++
        }
        connectedName = name
        savedCount = saved
        if (name !== "" && lastUsed.value !== name)
            lastUsed.value = name
    }
    function setOn(v) {
        wifiEnabled.value = v
        // the radio at once, as stock's switch; the policy runs it from here
        wifiStatus.powered = v
        // stock shows this until its OK (show_wifi_bluetooth_alert)
        if (!(btFirstShown.value === true || btFirstShown.value === "true"))
            //% "Bluetooth first"
            confirm.tell(qsTrId("id-wifi-bluetooth-first"),
                         //% "To save battery, the watch chooses Bluetooth over Wi-Fi."
                         qsTrId("id-wifi-bluetooth-first-message"),
                         function () { btFirstShown.value = true })
    }

    NetworkTechnology {
        id: wifiStatus
        path: "/net/connman/technology/wifi"
        onPoweredChanged: if (wifiStatus.powered) wifiModel.requestScan()
    }
    TechnologyModel {
        id: wifiModel
        name: "wifi"
    }
    ConfigurationValue {
        id: wifiEnabled
        key: "/org/asteroidos/eos-wifi/enabled"
        defaultValue: !FileInfo.exists("/var/lib/eos/wifi-user-off")
    }
    ConfigurationValue {
        id: settingsOpen
        key: "/org/asteroidos/eos-wifi/settings-open"
        defaultValue: "0"
    }
    ConfigurationValue {
        id: lastUsed
        key: "/org/asteroidos/eos-wifi/last-used"
        defaultValue: ""
    }
    ConfigurationValue {
        id: btFirstShown
        key: "/org/asteroidos/eos-wifi/bluetooth-first-shown"
        defaultValue: false
    }
    // the networks seen without internet (WiFiInternetState)
    ConfigurationValue {
        id: noNet
        key: "/org/asteroidos/eos-wifi/no-internet"
        defaultValue: ""
    }
    readonly property var noNetNames: WiFiMemory.parse(noNet.value)
    function remember(name, on) {
        noNet.value = WiFiMemory.update(noNet.value, name, on)
    }
    Timer {
        interval: 20000
        repeat: true
        triggeredOnStart: true
        running: page.on
        onTriggered: settingsOpen.value = String(Math.floor(Date.now() / 1000))
    }
    Component.onCompleted: if (wifiStatus.powered) wifiModel.requestScan()
    Component.onDestruction: settingsOpen.value = "0"

    Component { id: addLayer; WiFiNetworksPage { } }
    Component { id: savedLayer; WiFiSavedPage { } }
    Component { id: currentLayer; WiFiCurrentNetworkPage { } }
    Component { id: connectionDialog; WiFiConnectionDialog { } }

    SettingsChip {
        objectName: "wifiSwitch"
        title: qsTrId("id-wifi-title")
        summary: page.on
                 //% "Automatic"
                 ? qsTrId("id-wifi-automatic")
                 //% "Off"
                 : qsTrId("id-wifi-mode-off")
        control: "toggle"
        checked: page.on
        onClicked: page.setOn(!page.on)
    }
    Repeater {
        id: services
        model: wifiModel
        onCountChanged: Qt.callLater(page.recount)
        delegate: SettingsChip {
            objectName: "wifiCurrent"
            readonly property bool isConnected: modelData.connected
            readonly property bool isFavorite: modelData.favorite
            onIsConnectedChanged: Qt.callLater(page.recount)
            onIsFavoriteChanged: Qt.callLater(page.recount)
            visible: page.on && modelData.connected && page.serviceName(modelData) === page.connectedName
            title: page.serviceName(modelData)
            //% "No internet"
            summary: net.connectedNoInternet ? qsTrId("id-wifi-no-internet") : qsTrId("id-wifi-connected")
            iconName: BtIcons.wifiIcon(app.iconDir, modelData.strength, page.secured(modelData))
            WiFiInternetState {
                id: net
                service: modelData
                memory: page.noNetNames
                onChanged: (name, noInternet) => page.remember(name, noInternet)
            }
            onClicked: layerStack.push(currentLayer, { service: modelData })
        }
    }
    SettingsChip {
        objectName: "wifiLastUsed"
        visible: page.on && page.connectedName === "" && lastUsed.value !== ""
        title: lastUsed.value
        //% "Last used"
        summary: qsTrId("id-wifi-last-used")
        iconName: "ios-wifi-outline"
        clickable: false
    }
    SettingsChip {
        objectName: "wifiAdd"
        visible: page.on
        //% "Add network"
        title: qsTrId("id-wifi-add")
        iconName: "ios-add"
        onClicked: layerStack.push(addLayer, { model: wifiModel, connectionDialog: connectionDialog })
    }
    SettingsChip {
        objectName: "wifiSaved"
        visible: page.on
        //% "Saved networks"
        title: qsTrId("id-wifi-saved-networks")
        //% "No saved networks"
        summary: page.savedCount === 0 ? qsTrId("id-wifi-none-saved") : ""
        iconName: "ios-bookmark-outline"
        onClicked: layerStack.push(savedLayer, { model: wifiModel })
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
