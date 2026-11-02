/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A Wear OS settings row (Wear Material's WearChipButton): a pill 52 dp
 * high (104 px on the 384 px screen at 320 dpi) across the list, a 24 dp
 * icon 14 dp in, the title and under it the current value (summary), and
 * at the end an inline control: a switch (control: "toggle"), a radio
 * mark ("radio") or nothing. A tap anywhere on the chip clicks it. Near
 * the top and bottom of the round screen it shrinks and fades as it
 * scrolls (EdgeEffect, Wear OS's 0.7 and 0.5).
 *
 *   SettingsChip {
 *       iconName: "ios-sunny-outline"
 *       title: qsTrId("id-brightness")
 *       summary: "Normal"
 *       onClicked: layerStack.push(brightnessLayer)
 *   }
 */
Item {
    id: chip

    property string title: ""
    property string summary: ""
    property string iconName: ""
    /* "none", "toggle" or "radio" */
    property string control: "none"
    property bool checked: false
    /* false: greyed out, taps do nothing (stock: a mode holds it, e.g. Theater mode) */
    property bool active: true
    /* false: an information row (About), not a button */
    property bool clickable: true
    property alias edgeEffect: edge.enabled
    /* the chip grows from this height with its text */
    property real minHeight: Dims.h(27)
    readonly property bool pressed: area.pressed

    signal clicked()

    width: parent ? parent.width : Dims.w(89.6)
    height: Math.max(minHeight, texts.implicitHeight + Dims.h(3.6) * 2)
    opacity: active ? 1.0 : 0.38

    EdgeEffect { id: edge; item: chip }
    transform: Scale {
        origin.x: chip.width / 2
        origin.y: chip.height / 2
        xScale: edge.scale
        yScale: edge.scale
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Math.min(height / 2, Dims.h(13.5))
        color: area.pressed ? "#3a3a3d" : "#262628"
        opacity: edge.alpha
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Icon {
        id: icon
        visible: chip.iconName !== ""
        name: chip.iconName
        width: Dims.l(12.5)
        height: width
        opacity: edge.alpha
        anchors {
            left: parent.left
            leftMargin: Dims.w(7.3)
            verticalCenter: parent.verticalCenter
        }
    }

    Column {
        id: texts
        opacity: edge.alpha
        anchors {
            left: icon.visible ? icon.right : parent.left
            leftMargin: icon.visible ? Dims.w(4.2) : Dims.w(7.3)
            right: controlItem.visible ? controlItem.left : parent.right
            rightMargin: controlItem.visible ? Dims.w(3) : Dims.w(7.3)
            verticalCenter: parent.verticalCenter
        }
        Label {
            id: titleLabel
            width: parent.width
            text: chip.title
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
            clip: false
            font.pixelSize: Dims.l(7.4)
            font.styleName: "SemiCondensed Medium"
        }
        Label {
            id: summaryLabel
            width: parent.width
            visible: chip.summary !== ""
            text: chip.summary
            color: "#c4c7c5"
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            clip: false
            font.pixelSize: Dims.l(6.3)
        }
    }

    Item {
        id: controlItem
        visible: chip.control !== "none"
        width: chip.control === "toggle" ? Dims.l(12) : Dims.l(7.5)
        height: Dims.l(7.5)
        opacity: edge.alpha
        anchors {
            right: parent.right
            rightMargin: Dims.w(6)
            verticalCenter: parent.verticalCenter
        }

        // Wear Material's switch: a track, the thumb at the end of it
        Rectangle {
            id: track
            objectName: "chipSwitch"
            visible: chip.control === "toggle"
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: Dims.l(7)
            radius: height / 2
            color: chip.checked ? "#a8c7fa" : "transparent"
            border.width: chip.checked ? 0 : Math.max(1, Dims.l(0.6))
            border.color: "#8e918f"
            Behavior on color { ColorAnimation { duration: 100 } }
            Rectangle {
                width: chip.checked ? track.height * 0.72 : track.height * 0.5
                height: width
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: chip.checked ? track.width - width - (track.height - width) / 2
                                : (track.height - width) / 2
                color: chip.checked ? "#062e6f" : "#8e918f"
                Behavior on x { NumberAnimation { duration: 100 } }
            }
        }

        // the radio mark of a choice list
        Rectangle {
            objectName: "chipRadio"
            visible: chip.control === "radio"
            anchors.centerIn: parent
            width: Dims.l(6.2)
            height: width
            radius: width / 2
            color: "transparent"
            border.width: Math.max(1, Dims.l(0.6))
            border.color: chip.checked ? "#a8c7fa" : "#8e918f"
            Rectangle {
                anchors.centerIn: parent
                visible: chip.checked
                width: parent.width * 0.5
                height: width
                radius: width / 2
                color: "#a8c7fa"
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: chip.active && chip.clickable
        onClicked: chip.clicked()
    }
}
