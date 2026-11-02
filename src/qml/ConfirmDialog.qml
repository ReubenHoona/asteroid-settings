/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * Wear Material's alert dialog (WearAlertDialog), as the stock settings ask
 * before a change that costs battery or cannot be undone: a title, a
 * message, and two round buttons under them, ✕ and ✓. It covers the
 * screen (taps outside the buttons do nothing); ✕ closes it.
 *
 *   confirm.ask(qsTrId("id-aod-confirm"), qsTrId("id-turn-on"), function () { ... })
 */
Item {
    id: dialog

    property string title: ""
    property string message: ""
    /* only ✓: an explanation (About Wi-Fi) */
    property bool infoOnly: false
    property var _accept: null
    property var _reject: null
    readonly property bool shown: visible

    anchors.fill: parent
    visible: false
    opacity: 0
    z: 900

    function ask(title, message, onAccept, onReject) {
        dialog.title = title || ""
        dialog.message = message || ""
        _accept = onAccept || null
        _reject = onReject || null
        infoOnly = false
        visible = true
        flick.contentY = 0
        fadeIn.restart()
    }
    function tell(title, message) {
        ask(title, message)
        infoOnly = true
    }
    function accept() {
        var f = _accept
        close()
        if (f)
            f()
    }
    function reject() {
        var f = _reject
        close()
        if (f)
            f()
    }
    function close() {
        _accept = null
        _reject = null
        visible = false
        opacity = 0
    }

    NumberAnimation { id: fadeIn; target: dialog; property: "opacity"; from: 0; to: 1; duration: 150 }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
    }
    // the dialog takes every touch while it is up
    MouseArea { anchors.fill: parent }

    // the title, the message and the buttons scroll together, as a long
    // stock dialog does; a short one sits in the middle
    Flickable {
        id: flick
        objectName: "dialogFlickable"
        anchors.fill: parent
        contentHeight: Math.max(height, content.height + Dims.h(24))
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: content
            y: Math.max(Dims.h(14), (flick.height - height) / 2)
            anchors.horizontalCenter: parent.horizontalCenter
            width: Dims.w(76)
            spacing: Dims.h(3)
            Label {
                objectName: "dialogTitle"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                clip: false
                text: dialog.title
                font.pixelSize: Dims.l(7.4)
                font.styleName: "SemiCondensed Medium"
            }
            Label {
                objectName: "dialogMessage"
                visible: text !== ""
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                clip: false
                color: "#c4c7c5"
                text: dialog.message
                font.pixelSize: Dims.l(6.2)
            }
            Item { width: 1; height: Dims.h(2) }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Dims.w(6)

                MouseArea {
                    id: no
                    objectName: "dialogNo"
                    visible: !dialog.infoOnly
                    width: Dims.l(19)
                    height: width
                    onClicked: dialog.reject()
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: no.pressed ? "#3a3a3d" : "#262628"
                    }
                    Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.5
                        height: width
                        name: "ios-close"
                    }
                }
                MouseArea {
                    id: yes
                    objectName: "dialogYes"
                    width: Dims.l(19)
                    height: width
                    onClicked: dialog.accept()
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: yes.pressed ? "#c2d7fb" : "#a8c7fa"
                    }
                    Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.5
                        height: width
                        name: "ios-checkmark"
                        color: "#062e6f"
                    }
                }
            }
        }
    }
}
