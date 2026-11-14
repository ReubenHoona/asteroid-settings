/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Security (settings-b-07, accessibility-lock-security-09). Stock
// CP3A's legacy SecuritySettingsFragment: Screen lock (summary Pattern, PIN
// or Off; a radio list Pattern / PIN / None) and Lock screen now (only while
// a PIN or pattern is set). Device administration, Watch Unlock and Trust
// agents are Google features and stay out.
// The lock itself is the launcher's keyguard (W3-launcher-a11y-security): it
// keeps the kind in lock-type ("none", "pin", "pattern") and runs the set up
// flows, so Settings only asks. A choice writes lock-request =
// "<kind>@<ms>" (pin, pattern or none; none asks for the current credential
// first, as stock) and ends Settings so that the flow shows over the face;
// Lock screen now writes lock-now = "lock@<ms>" the same way.
SettingsPage {
    id: page
    objectName: "securityPage"
    title: qsTrId("id-security-page")

    ConfigurationValue {
        id: lockType
        key: "/org/asteroidos/security/lock-type"
        defaultValue: "none"
    }
    ConfigurationValue {
        id: lockRequest
        key: "/org/asteroidos/security/lock-request"
        defaultValue: ""
    }
    ConfigurationValue {
        id: lockNow
        key: "/org/asteroidos/security/lock-now"
        defaultValue: ""
    }

    // the list is Pattern, PIN, None, as stock
    readonly property var kinds: ["pattern", "pin", "none"]
    readonly property var kindNames: [
        //% "Pattern"
        qsTrId("id-lock-pattern"),
        //% "PIN"
        qsTrId("id-lock-pin"),
        //% "None"
        qsTrId("id-lock-none")]
    readonly property int current: {
        var i = kinds.indexOf(String(lockType.value))
        return i < 0 ? 2 : i
    }
    readonly property bool locked: current !== 2

    // the summary of the row: Pattern, PIN or Off
    readonly property string summaryText: locked ? kindNames[current]
                                                 : qsTrId("id-off")

    function request(text) {
        lockRequest.value = text + "@" + Date.now()
        closeTimer.restart()
    }
    function lockNowAndLeave() {
        lockNow.value = "lock@" + Date.now()
        closeTimer.restart()
    }
    Timer {
        id: closeTimer
        interval: 150
        onTriggered: app.closeApp()
    }

    SettingsChip {
        objectName: "screenLockItem"
        //% "Screen lock"
        title: qsTrId("id-screen-lock")
        summary: page.summaryText
        onClicked: app.choose(qsTrId("id-screen-lock"), page.kindNames, page.current,
                              function (i) {
                                  if (i !== page.current)
                                      page.request(page.kinds[i])
                              })
    }
    SettingsChip {
        objectName: "lockNowItem"
        visible: page.locked
        //% "Lock screen now"
        title: qsTrId("id-lock-now")
        onClicked: confirm.ask(qsTrId("id-lock-now"), "", function () { page.lockNowAndLeave() })
    }
}
