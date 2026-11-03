/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// The network the watch is on, as stock (prefs_wifi_current_network.xml,
// WifiCurrentNetworkFragment): its name as the title, then only what it is:
// IP address, IPv6 addresses and MAC address ("Unavailable" when there is
// none). Stock has no Disconnect here; Forget is under Saved networks.
SettingsPage {
    id: page
    objectName: "wifiCurrentPage"
    title: service && service.name ? service.name : qsTrId("id-wifi-hiddennetwork")

    property var service: null

    function addressOf(map) {
        //% "Unavailable"
        return map && map["Address"] ? String(map["Address"]) : qsTrId("id-wifi-unavailable")
    }

    SettingsChip {
        objectName: "wifiIp"
        clickable: false
        //% "IP address"
        title: qsTrId("id-wifi-ip")
        summary: page.addressOf(page.service ? page.service.ipv4 : null)
    }
    SettingsChip {
        objectName: "wifiIpv6"
        clickable: false
        //% "IPv6 addresses"
        title: qsTrId("id-wifi-ipv6")
        summary: page.addressOf(page.service ? page.service.ipv6 : null)
    }
    SettingsChip {
        objectName: "wifiMac"
        clickable: false
        //% "MAC address"
        title: qsTrId("id-wifi-mac")
        summary: page.addressOf(page.service ? page.service.ethernet : null)
    }
}
