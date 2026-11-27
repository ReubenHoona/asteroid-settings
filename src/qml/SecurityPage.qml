/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.DBus

// Settings > Security (settings-b-07, accessibility-lock-security-09). Stock
// CP3A's legacy SecuritySettingsFragment: Screen lock (summary Pattern, PIN
// or Off; a radio list Pattern / PIN / None) and Lock screen now (only while
// a PIN or pattern is set). Device administration, Watch Unlock and Trust
// agents are Google features and stay out.
// The lock is the launcher's (W3-launcher-a11y-security). Settings asks its
// session bus object org.asteroidos.launcher.Lock (CR-06): State() says what
// is in force, StateChanged(s) keeps this page right, Lock() is "Lock screen
// now". A choice in the list starts the set-up flow (LockFlowPage: the
// current credential first, as stock; the new one twice; None asks for the
// current one) which calls Verify, SetPin, SetPattern and Clear. No dconf key
// is involved (FP-S2 removed security/lock-type, lock-request and lock-now).
SettingsPage {
    id: page
    objectName: "securityPage"
    title: qsTrId("id-security-page")

    // the session name of the launcher (CR-01)
    DBusInterface {
        id: lock
        bus: DBus.SessionBus
        service: "org.asteroidos.launcher"
        path: "/org/asteroidos/launcher/lock"
        iface: "org.asteroidos.launcher.Lock"
        signalsEnabled: true
        // Nemo.DBus connects a signal to the function rc<Signal>
        function rcStateChanged(state) { page.setKind(state) }
    }

    // the credential kind in force: "none", "pin" or "pattern"; "" until the launcher has answered
    property string kindNow: ""
    readonly property bool known: kindNow !== ""

    function setKind(k) {
        var s = String(k)
        kindNow = (s === "pin" || s === "pattern") ? s : "none"
    }
    function refresh() {
        lock.typedCall("State", [], function (r) { page.setKind(r) }, function () { page.kindNow = "" })
    }
    Component.onCompleted: refresh()

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
        var i = kinds.indexOf(kindNow)
        return i < 0 ? 2 : i
    }
    readonly property bool locked: current !== 2

    // the summary of the row: Pattern, PIN or Off
    readonly property string summaryText: !known ? "" : (locked ? kindNames[current] : qsTrId("id-off"))

    // the set-up flow for the kind chosen in the list (the one in force is not asked again)
    function startFlow(kind) {
        layerStack.push(lockFlowLayer, { "kind": kind, "oldKind": page.kindNow,
                                         "finished": function (k) { page.setKind(k) } })
    }
    function lockNowAndLeave() {
        lock.typedCall("Lock", [], function () {}, function () {})
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
        onClicked: {
            if (!page.known) {
                // the launcher did not answer (yet): ask again and say so
                page.refresh()
                //% "Screen lock is not available"
                toast.show(qsTrId("id-lock-unavailable"))
                return
            }
            app.choose(qsTrId("id-screen-lock"), page.kindNames, page.current,
                       function (i) {
                           if (i !== page.current)
                               page.startFlow(page.kinds[i])
                       })
        }
    }
    SettingsChip {
        objectName: "lockNowItem"
        visible: page.locked
        //% "Lock screen now"
        title: qsTrId("id-lock-now")
        onClicked: confirm.ask(qsTrId("id-lock-now"), "", function () { page.lockNowAndLeave() })
    }
}
