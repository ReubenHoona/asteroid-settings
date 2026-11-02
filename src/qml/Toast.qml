/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A short message near the bottom of the screen for two seconds, as the
 * stock settings show a toast ("You are now a developer!").
 */
Item {
    id: toast
    property string text: ""
    anchors.fill: parent
    z: 950
    visible: opacity > 0
    opacity: 0

    function show(message) {
        text = message
        fade.stop()
        opacity = 1
        timer.restart()
    }

    Timer { id: timer; interval: 2000; onTriggered: fade.start() }
    NumberAnimation { id: fade; target: toast; property: "opacity"; to: 0; duration: 200 }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Dims.h(12)
        width: Math.min(Dims.w(70), label.implicitWidth + Dims.w(10))
        height: label.height + Dims.h(5)
        radius: Math.min(height / 2, Dims.h(8))
        color: "#3c4043"
        Label {
            id: label
            objectName: "toastText"
            anchors.centerIn: parent
            width: Math.min(Dims.w(60), implicitWidth)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            clip: false
            text: toast.text
            font.pixelSize: Dims.l(5.6)
        }
    }
}
