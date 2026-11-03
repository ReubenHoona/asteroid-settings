/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// Wi-Fi > Add network as stock (prefs_wifi_add.xml, WifiAddNetworkFragment,
// AccessPointPreference): the network the watch is on first, then every
// network in range, saved or not (no 802.1X and no hidden ones, as stock),
// each with its state: Connecting…, Connected, Wrong password, Connection
// failure, Saved, or nothing. A tap connects: a saved or an open network at
// once, a new secured one asks for its password first (WiFiConnectionDialog:
// "Network password required", Enter on watch); a failed connect opens that
// page as stock's (Retry, Open on watch, Forget). Stock's last row, "Add
// hidden network", only says to use the phone's Wear OS app: not here.
SettingsPage {
    id: page
    objectName: "wifiAddPage"
    title: qsTrId("id-wifi-add")

    property var model: null
    property var connectionDialog: null
    property int shown: 0

    function usable(s) {
        return s.name !== "" && !(s.security && s.security.indexOf("ieee8021x") >= 0)
    }
    function secured(s) {
        return s.security && s.security.length > 0 && s.security[0] !== "none"
    }
    function stateText(s) {
        if (s.state === "association" || s.state === "configuration")
            //% "Connecting…"
            return qsTrId("id-wifi-connecting")
        if (s.connected)
            return qsTrId("id-wifi-connected")
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
        property var service: null
        onVisibleChanged: Qt.callLater(page.recount)
        title: service ? service.name : ""
        summary: service ? page.stateText(service) : ""
        iconName: service && page.secured(service) ? "ios-lock-outline" : "ios-wifi-outline"
        clickable: !!service && !service.connected
        onClicked: page.choose(service)
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
}
