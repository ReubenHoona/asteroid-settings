/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.utils

// Whether a Wi-Fi network has no internet, for the summary "No internet"
// (stock AccessPointPreference.updateValues: a saved network whose
// configuration has no internet access). connman's one-shot online check
// (connman-main.conf) moves a connected service from "ready" to "online"; one
// that stays "ready" is a network without internet, and eos-wifi-policy
// (CHECK_WAIT_S, 20 s after the connect) then writes its name to
// /run/eos-wifi-policy/no-internet. The state of the connected network is that
// file while the service is "ready"; a network seen so is remembered by name
// (`memory`, the page keeps it in dconf through changed()) and a saved
// network that is not connected shows "No internet" from that memory until it
// comes online again. One single-shot timer, only while a connected network
// is "ready" and the page is open; nothing polls.
Item {
    id: st
    objectName: "wifiInternetState"

    property var service: null
    // the names remembered as without internet
    property var memory: []
    // the policy's state file
    property string stateFile: "/run/eos-wifi-policy/no-internet"
    // CHECK_WAIT_S of eos-wifi-policy plus a second
    property int waitMs: 21000

    property bool observed: false
    readonly property bool ready: !!service && service.connected && service.state === "ready"
    readonly property bool connectedNoInternet: ready && observed
    readonly property bool rememberedNoInternet: !!service && !service.connected && service.favorite && memory.indexOf(service.name) >= 0

    // a name to remember (noInternet true) or to forget (false)
    signal changed(string name, bool noInternet)

    function check() {
        if (!ready) {
            observed = false
            return
        }
        observed = FileInfo.exists(stateFile)
        if (observed && memory.indexOf(service.name) < 0)
            changed(service.name, true)
    }
    function refresh() {
        if (!service)
            return
        if (service.connected && service.state === "online") {
            observed = false
            if (memory.indexOf(service.name) >= 0)
                changed(service.name, false)
        } else if (ready) {
            check()
        } else {
            observed = false
        }
    }

    Connections {
        target: st.service
        function onStateChanged() { st.refresh() }
        function onConnectedChanged() { st.refresh() }
    }
    onServiceChanged: refresh()
    Component.onCompleted: refresh()
    // the file shows 20 s after the connect: look once then
    Timer {
        interval: st.waitMs
        running: st.ready && !st.observed
        repeat: false
        onTriggered: st.check()
    }
}
