/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.DBus

/*
 * The screen of the factory reset (stock ShuttingDialogProvider$ShuttingScreen,
 * ShuttingScreen$$inlined$ConstraintLayout$5:97-174, $2$5:65-108): black,
 * full screen, the text "Resetting..." in titleLarge (titleMedium when it
 * does not fit), primaryDim, at most 2 lines, 89.6 % of the width, centred;
 * it fades in over 300 ms after 100 ms; an indeterminate arc 81.24 % of the
 * screen high round it (ArcProgressIndicator). It cannot be cancelled: it
 * takes every touch and Settings has no way back from it. Stock holds a
 * 30 s screen-on wake lock; here mce is asked for the display on and a
 * blanking pause that ends after 30 s (one shot, only during a reset).
 * start() asks the system to wipe: the user unit eos-factory-reset-request
 * hands the request to the root helper, which empties the user data and
 * reboots into the first run. The arc animates only while the display is on.
 */
Item {
    id: screen
    objectName: "factoryResetScreen"

    /* a reset was asked for (the screen stays until the watch restarts) */
    property bool running: false
    /* the stock wake lock: 30 s */
    property int holdMs: 30000
    readonly property alias title: titleLabel

    visible: running
    enabled: running

    function start() {
        if (running)
            return
        running = true
        fade.restart()
        mce.call("req_display_state_on", [])
        mce.call("req_display_blanking_pause", [])
        holdTimer.restart()
        userSystemd.call("StartUnit", ["eos-factory-reset-request.service", "replace"])
    }

    DBusInterface {
        id: mce
        bus: DBus.SystemBus
        service: "com.nokia.mce"
        path: "/com/nokia/mce/request"
        iface: "com.nokia.mce.request"
    }
    DBusInterface {
        id: userSystemd
        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        path: "/org/freedesktop/systemd1"
        iface: "org.freedesktop.systemd1.Manager"
    }
    Timer {
        id: holdTimer
        interval: screen.holdMs
        onTriggered: mce.call("req_display_cancel_blanking_pause", [])
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.color.background
    }
    // takes every touch: nothing under the screen can be reached
    MouseArea {
        anchors.fill: parent
        preventStealing: true
        onPressed: (mouse) => mouse.accepted = true
    }
    ArcProgressIndicator {
        id: arc
        objectName: "factoryResetArc"
        anchors.fill: parent
    }
    Label {
        id: titleLabel
        objectName: "factoryResetTitle"
        anchors.centerIn: parent
        width: parent.width * 0.896
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        maximumLineCount: 2
        role: "titleLarge"
        fontSizeMode: Text.Fit
        // titleMedium is the smaller stock fallback (32 px)
        minimumPixelSize: Math.round(Theme.type.titleMedium.pixelSize)
        color: Theme.color.primaryDim
        //% "Resetting..."
        text: qsTrId("id-factory-resetting")
        opacity: 0
        clip: false
    }
    // fades in over 300 ms after 100 ms (stock AnimatedVisibility)
    SequentialAnimation {
        id: fade
        PauseAnimation { duration: Motion.duration(100) }
        NumberAnimation {
            target: titleLabel
            property: "opacity"
            from: 0
            to: 1
            duration: Motion.duration(300)
        }
    }
}
