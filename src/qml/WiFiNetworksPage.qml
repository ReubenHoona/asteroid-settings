/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import "BtIcons.js" as BtIcons
import "WiFiMemory.js" as WiFiMemory

// Wi-Fi > Add network as stock (prefs_wifi_add.xml, WifiAddNetworkFragment,
// AccessPointPreference): the network the watch is on first, then every
// network in range, saved or not (no 802.1X and no hidden ones, as stock),
// each with its signal level icon (the fan with 0 to 4 arcs filled, a lock
// when secured) and its state: Connecting…, Connected (No internet when the
// online check failed), Wrong password, Connection failure, No internet
// (a saved network last seen without), Saved, or nothing. A tap connects: a
// saved or an open network at once, a new secured one asks for its password
// first (WiFiConnectionDialog: "Network password required", Enter on watch,
// then the keyboard at once); a security this watch cannot use (WEP) says
// "Access Point has unsupported security" instead; a failed connect opens
// that page as stock's (Retry, Open on watch, Forget). The last row is
// "Add hidden network" (see WiFiHiddenPage).
SettingsPage {
    id: page
    objectName: "wifiAddPage"
    title: qsTrId("id-wifi-add")

    property var model: null
    property var connectionDialog: null
    property int shown: 0

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

    Component { id: hiddenLayer; WiFiHiddenPage { } }

    function usable(s) {
        return s.name !== "" && !(s.security && s.security.indexOf("ieee8021x") >= 0)
    }
    function secured(s) {
        return s.security && s.security.length > 0 && s.security[0] !== "none"
    }
    // WEP and anything else connman lists that is not open, PSK/SAE or WPS
    // (stock: generateConfigForSecuredAp throws UnsupportedOperationException)
    function unsupported(s) {
        if (!secured(s))
            return false
        for (var i = 0; i < s.security.length; i++) {
            var t = s.security[i]
            if (t !== "psk" && t !== "sae" && t !== "wps" && t !== "none")
                return true
        }
        return false
    }
    function stateText(s, net) {
        if (s.state === "association" || s.state === "configuration")
            //% "Connecting…"
            return qsTrId("id-wifi-connecting")
        if (s.connected)
            //% "No internet"
            return net && net.connectedNoInternet ? qsTrId("id-wifi-no-internet") : qsTrId("id-wifi-connected")
        if (net && net.rememberedNoInternet)
            return qsTrId("id-wifi-no-internet")
        if (s.error === "invalid-key")
            //% "Wrong password"
            return qsTrId("id-wifi-wrong-password")
        if (s.state === "failure")
            //% "Connection failure"
            return qsTrId("id-wifi-connection-failure")
        if (s.favorite)
            //% "Saved"
            return qsTrId("id-wifi-saved")
        return ""
    }
    function choose(s) {
        if (s.connected)
            return
        if (!s.favorite && unsupported(s)) {
            //% "Access Point has unsupported security"
            confirm.tell("", qsTrId("id-wifi-unsupported-security"))
            return
        }
        if (s.favorite || !secured(s))
            s.requestConnect()
        else
            layerStack.push(page.connectionDialog, { modelData: s, failed: false })
    }
    function recount() {
        var n = 0
        for (var r = 0; r < 2; r++) {
            var rep = r === 0 ? active : others
            for (var i = 0; i < rep.count; i++) {
                var it = rep.itemAt(i)
                if (it && it.visible)
                    n++
            }
        }
        shown = n
    }

    // (a plain property, not a required one: that would take modelData away)
    component NetworkChip: SettingsChip {
        id: chip
        property var service: null
        onVisibleChanged: Qt.callLater(page.recount)
        title: service ? service.name : ""
        summary: service ? page.stateText(service, net) : ""
        iconName: service ? BtIcons.wifiIcon(app.iconDir, service.strength, page.secured(service)) : ""
        clickable: !!service && !service.connected
        onClicked: page.choose(service)
        WiFiInternetState {
            id: net
            service: chip.service
            memory: page.noNetNames
            onChanged: (name, noInternet) => page.remember(name, noInternet)
        }
        Connections {
            target: service
            function onConnectRequestFailed(error) {
                if (layerStack.currentLayer === page)
                    layerStack.push(page.connectionDialog, { modelData: service, failed: true })
            }
        }
    }
    // stock's pref_active_ap group, then pref_available_networks_group
    Repeater {
        id: active
        model: page.model
        onCountChanged: Qt.callLater(page.recount)
        delegate: NetworkChip {
            service: modelData
            visible: modelData.connected && page.usable(modelData)
        }
    }
    Repeater {
        id: others
        model: page.model
        onCountChanged: Qt.callLater(page.recount)
        delegate: NetworkChip {
            service: modelData
            visible: !modelData.connected && page.usable(modelData)
        }
    }
    SettingsText {
        objectName: "wifiNone"
        visible: page.shown === 0
        horizontalAlignment: Text.AlignHCenter
        //% "No networks found"
        text: qsTrId("id-wifi-none")
    }
    // stock's last row (prefs_wifi_add.xml pref_wifi_add_network)
    SettingsChip {
        objectName: "wifiAddHidden"
        //% "Add hidden network"
        title: qsTrId("id-wifi-add-hidden")
        iconName: "ios-add"
        onClicked: layerStack.push(hiddenLayer)
    }
}
