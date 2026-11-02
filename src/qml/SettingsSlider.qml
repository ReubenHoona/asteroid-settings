/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * Wear Material's inline slider (WearInlineSlider): a chip with "−" at the
 * start, "+" at the end and the level between them as a bar, cut into
 * segments when there are few steps. The −/+ taps step it; the crown keeps
 * scrolling the page, as on the stock watch. A tap asks for the next value
 * (moved(newValue)); the owner sets its backend and value follows it.
 *
 *   SettingsSlider { from: 0; to: 100; stepSize: 10; value: v; onMoved: (newValue) => v = newValue }
 */
Item {
    id: slider

    property real from: 0
    property real to: 100
    property real stepSize: 10
    property real value: 0
    property bool active: true
    property alias edgeEffect: edge.enabled
    readonly property int steps: Math.max(1, Math.round((to - from) / stepSize))
    readonly property real position: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

    signal moved(real newValue)

    function stepBy(n) {
        var v = Math.max(from, Math.min(to, Math.round((value - from) / stepSize + n) * stepSize + from))
        if (v === value) {
            Haptics.limit()
            return
        }
        Haptics.tick()
        moved(v)
    }

    width: parent ? parent.width : Dims.w(89.6)
    height: Dims.h(27)
    opacity: active ? 1.0 : 0.38

    EdgeEffect { id: edge; item: slider }
    transform: Scale {
        origin.x: slider.width / 2
        origin.y: slider.height / 2
        xScale: edge.scale
        yScale: edge.scale
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "#262628"
        opacity: edge.alpha
    }

    Item {
        opacity: edge.alpha
        anchors.fill: parent

        MouseArea {
            id: minus
            objectName: "sliderMinus"
            enabled: slider.active
            width: parent.height
            height: parent.height
            anchors.left: parent.left
            onClicked: slider.stepBy(-1)
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.62
                height: width
                radius: width / 2
                color: minus.pressed ? "#3a3a3d" : "transparent"
            }
            Rectangle {
                anchors.centerIn: parent
                width: Dims.l(5.5)
                height: Math.max(2, Dims.l(0.8))
                radius: height / 2
                color: "#ffffff"
            }
        }

        MouseArea {
            id: plus
            objectName: "sliderPlus"
            enabled: slider.active
            width: parent.height
            height: parent.height
            anchors.right: parent.right
            onClicked: slider.stepBy(1)
            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.62
                height: width
                radius: width / 2
                color: plus.pressed ? "#3a3a3d" : "transparent"
            }
            Rectangle {
                anchors.centerIn: parent
                width: Dims.l(5.5)
                height: Math.max(2, Dims.l(0.8))
                radius: height / 2
                color: "#ffffff"
            }
            Rectangle {
                anchors.centerIn: parent
                width: Math.max(2, Dims.l(0.8))
                height: Dims.l(5.5)
                radius: width / 2
                color: "#ffffff"
            }
        }

        // the level: segments when there are few steps, else one bar
        Item {
            id: bar
            anchors {
                left: minus.right
                right: plus.left
                verticalCenter: parent.verticalCenter
            }
            height: Dims.l(2.2)
            readonly property bool segmented: slider.steps <= 10
            readonly property real gap: segmented ? Dims.l(1) : 0

            Repeater {
                model: bar.segmented ? slider.steps : 1
                Rectangle {
                    readonly property real w: (bar.width - bar.gap * (slider.steps - 1)) / slider.steps
                    x: bar.segmented ? index * (w + bar.gap) : 0
                    width: bar.segmented ? w : bar.width
                    height: bar.height
                    radius: height / 2
                    color: "#4a4a4d"
                    Rectangle {
                        height: parent.height
                        radius: height / 2
                        color: "#a8c7fa"
                        width: bar.segmented ? (index < Math.round(slider.position * slider.steps) ? parent.width : 0)
                                             : parent.width * slider.position
                    }
                }
            }
        }
    }
}
