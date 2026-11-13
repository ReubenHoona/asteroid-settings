/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * The stock CP3A Settings slider (SliderItem, the Wear Material 3 Slider),
 * px on the 384 px Pixel Watch 2 (2 px per dp):
 * - a 52 dp (104 px) row, CornerLarge (a pill at this height), container
 *   surfaceContainer #2F3036 (SliderKt.java:116, SliderTokens.java:28-31);
 * - decrease and increase buttons 48 dp (96 px) wide and the row's height,
 *   each a 24 dp (48 px) Remove / Add glyph in onSurface #E8E7EE (38 % when
 *   disabled or at its end), with a bounded ripple
 *   (SliderDefaults.java:73-93,172-206; materialcore SliderKt.java:40). The
 *   glyphs are drawn here: 28 px strokes 4 px thick with round ends
 *   (inferred from the 24 dp Material glyph proportions);
 * - between them the bar, 12 dp tall: the selected part 12 dp (24 px) and
 *   fully round in primary #DBE2F9; the rest 4 dp (8 px) tall, radius 2 dp,
 *   black at 30 % (#212226 on the container); the selected fraction
 *   animates 150 ms with (0, 0, 0, 1) (SliderKt$$ExternalSyntheticLambda2.java:37-62,
 *   SliderKt$$ExternalSyntheticLambda9.java:112,143, SliderTokens.java:45-50);
 * - segmented sliders only (stock SliderUiState.segmented): a 4 dp (8 px)
 *   separator dot at every step boundary, primaryContainer #404759 on the
 *   selected part and primary at 50 % on the rest, and a selected part that
 *   ends 6 dp past its step's dot. A plain slider (the default, as stock's
 *   SliderPreference) is a bare bar: stock draws n - 1 dots with
 *   n = segmented ? steps + 1 : 1 (SliderKt$$ExternalSyntheticLambda6.java:67).
 *   Segmented in stock: Brightness (SliderController$Brightness$$ExternalSyntheticLambda0.java:44,
 *   copy$default mask 527 sets it true) and Audio balance; not segmented: the
 *   volume streams (constructor mask 16239 has bit 8192, so false:
 *   MediaVolumeSliderPreference.java:65, SliderItemAdapter.java:402) and
 *   Vibration (16237, then copy$default 663 with false).
 *
 *   SettingsSlider { from: 0; to: 100; stepSize: 10; value: level; onMoved: (v) => level = v }
 *   SettingsSlider { segmented: true; ... }   // Brightness
 */
Item {
    id: slider

    property real from: 0
    property real to: 100
    property real stepSize: 10
    property real value: 0
    property bool active: true
    // stock SliderUiState.segmented: step dots and the longer selected part
    property bool segmented: false
    property alias edgeEffect: edge.enabled
    readonly property int steps: Math.max(1, Math.round((to - from) / stepSize))
    readonly property real position: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0
    // the bar's segments: one when not segmented, so no dots
    readonly property int segments: segmented ? steps : 1

    signal moved(real newValue)

    function stepBy(n) {
        var v = Math.max(from, Math.min(to, Math.round((value - from) / stepSize + n) * stepSize + from))
        // a press that moves nothing plays nothing; the step onto the first
        // or last value is GESTURE_END (click 1.0), every other SEGMENT_FREQUENT_TICK
        // (tick 1.0), both touch class (SliderKt$$ExternalSyntheticLambda8.java:20-40)
        if (v === value)
            return
        if (v === from || v === to)
            Haptics.gestureEnd()
        else
            Haptics.segmentTick()
        moved(v)
    }

    function _a(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    readonly property color iconColor: Theme.color.onSurface
    readonly property color iconDisabledColor: _a(Theme.color.onSurface, Theme.alpha.disabledContent)

    width: parent ? parent.width : Theme.dp(172)
    height: Theme.size.slider

    EdgeEffect { id: edge; item: slider }
    transform: Scale {
        origin.x: slider.width / 2
        origin.y: slider.height / 2
        xScale: edge.scale
        yScale: edge.scale
    }

    Rectangle {
        id: container
        objectName: "sliderContainer"
        anchors.fill: parent
        radius: Math.min(Theme.shape.large, height / 2)
        color: slider.active ? Theme.color.surfaceContainer : slider._a(Theme.color.onSurface, Theme.alpha.disabledContainer)
        opacity: edge.alpha
    }

    // a 28 x 4 px stroke with round ends: the minus, and the plus with a turned copy
    component Glyph: Item {
        property bool plus: false
        property color color
        width: Theme.size.iconSmall
        height: width
        Rectangle {
            anchors.centerIn: parent
            width: Theme.dp(14)
            height: Theme.dp(2)
            radius: height / 2
            color: parent.color
        }
        Rectangle {
            visible: parent.plus
            anchors.centerIn: parent
            width: Theme.dp(2)
            height: Theme.dp(14)
            radius: width / 2
            color: parent.color
        }
    }

    Item {
        opacity: edge.alpha
        anchors.fill: parent

        MouseArea {
            id: minus
            objectName: "sliderMinus"
            enabled: slider.active
            width: Theme.size.sliderButtonWidth
            height: parent.height
            anchors.left: parent.left
            onClicked: slider.stepBy(-1)
            Ripple {
                radius: container.radius
                color: slider.iconColor
                pressed: minus.pressed
                pressX: minus.mouseX
                pressY: minus.mouseY
            }
            Glyph {
                objectName: "sliderMinusGlyph"
                anchors.centerIn: parent
                color: slider.active && slider.value > slider.from ? slider.iconColor : slider.iconDisabledColor
            }
        }

        MouseArea {
            id: plus
            objectName: "sliderPlus"
            enabled: slider.active
            width: Theme.size.sliderButtonWidth
            height: parent.height
            anchors.right: parent.right
            onClicked: slider.stepBy(1)
            Ripple {
                radius: container.radius
                color: slider.iconColor
                pressed: plus.pressed
                pressX: plus.mouseX
                pressY: plus.mouseY
            }
            Glyph {
                objectName: "sliderPlusGlyph"
                anchors.centerIn: parent
                plus: true
                color: slider.active && slider.value < slider.to ? slider.iconColor : slider.iconDisabledColor
            }
        }

        // the bar: the selected part, the rest, and (segmented) a dot at each step boundary
        Item {
            id: bar
            objectName: "sliderBar"
            anchors {
                left: minus.right
                right: plus.left
                verticalCenter: parent.verticalCenter
            }
            height: Theme.size.sliderSelectedBar
            // stock animates the fraction (animateFloatAsState, 150 ms,
            // EasingStandardDecelerate: SliderKt$$ExternalSyntheticLambda9.java:112)
            property real shownPosition: slider.position
            Behavior on shownPosition {
                NumberAnimation {
                    duration: Motion.duration(150)
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.easing.standardDecelerate
                }
            }
            // the dots lie on a track 2 dp longer at each end
            // (SliderKt$$ExternalSyntheticLambda2.java:60-62)
            readonly property real dotInset: Theme.dp(2)
            // the selected length (SliderKt$$ExternalSyntheticLambda2.java:37):
            // W * f, or segmented with f > 0: 4 dp + (W + 4 dp) * f, so that its
            // round end (6 dp) is centred on the dot of its step
            readonly property real shownLength: slider.segmented && shownPosition > 0
                ? Theme.dp(4) + (width + 2 * dotInset) * shownPosition
                : width * shownPosition
            // stock clips the bar to its pill (Lambda9.java:143): at most the bar
            readonly property real shownWidth: Math.min(width, shownLength)

            Rectangle {
                id: unselected
                objectName: "sliderUnselected"
                anchors.verticalCenter: parent.verticalCenter
                x: bar.shownWidth
                width: Math.max(0, bar.width - x)
                height: Theme.size.sliderUnselectedBar
                radius: Theme.dp(2)
                color: Qt.rgba(0, 0, 0, Theme.alpha.sliderUnselected)
            }
            Rectangle {
                id: selected
                objectName: "sliderSelected"
                width: bar.shownWidth
                height: parent.height
                radius: height / 2
                visible: width > 0
                color: slider.active ? Theme.color.primary : slider.iconDisabledColor
            }
            Repeater {
                objectName: "sliderSeparators"
                model: slider.segments - 1
                Rectangle {
                    required property int index
                    // dot k of n at (W + 4 dp) * k / n - 2 dp, in the selection
                    // colour when k / n <= f (SliderKt$$ExternalSyntheticLambda2.java:61-62)
                    readonly property real at: (bar.width + 2 * bar.dotInset) * (index + 1) / slider.segments - bar.dotInset
                    readonly property bool inSelection: (index + 1) / slider.segments <= bar.shownPosition + 1e-9
                    x: at - width / 2
                    y: (bar.height - height) / 2
                    width: Theme.size.sliderStepDot
                    height: width
                    radius: width / 2
                    color: inSelection ? Theme.color.primaryContainer
                                       : slider._a(Theme.color.primary, 0.5)
                }
            }
        }
    }
}
