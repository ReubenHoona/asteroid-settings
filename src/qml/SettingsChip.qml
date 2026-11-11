/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A stock CP3A Settings row, on the Wear Material 3 Button of
 * org.asteroid.controls (px on the 384 px Pixel Watch 2, 2 px per dp):
 * - a navigation row is a FilledTonalButton (ButtonItemKt.java:110,133):
 *   container surfaceContainer #2F3036, label labelMedium (30 px) in
 *   onSurface #E8E7EE, second line labelSmall (26 px) in onSurfaceVariant
 *   #CECDD4, icon 26 dp (52 px) in primary #DBE2F9, padding 14/6/14/6 dp
 *   (28/12 px), 6 dp (12 px) from the icon to the text, at least 52 dp
 *   (104 px) tall (FilledButtonTokens.java:7,31-38, ButtonDefaults.java:21-33);
 * - control "toggle" is a SwitchButton row and "radio" a RadioButton row
 *   (SwitchButtonTokens.java:51-61,90-97, RadioButtonTokens.java:53-64):
 *   padding 14/8/14/8 dp (16 px above and below), the control in a 32 x 24 dp
 *   (64 x 48 px) slot 6 dp (12 px) after the text and 14 dp (28 px) from the
 *   end; checked: container primaryContainer #404759, text onPrimaryContainer
 *   #D9E0F7, second line at 90 %; the row colours move with the slow effects
 *   spring (stiffness 260, about 412 ms), the switch and the radio dot with
 *   the fast effects spring (1400, about 177 ms); a tap plays TOGGLE_ON /
 *   TOGGLE_OFF or CONTEXT_CLICK, which Touch feedback governs
 *   (SwitchButtonKt$$ExternalSyntheticLambda0.java:18,
 *   RadioButtonKt$$ExternalSyntheticLambda0.java:17);
 * - disabled (active: false): container onSurface at 12 %, content onSurface
 *   at 38 %, the same size (FilledButtonTokens.java:26-28);
 * - an information row (clickable: false) is a Button with a transparent
 *   container, 16 dp (32 px) corners, content onSurface, icon onSurface at
 *   38 % (InfoChipItemKt.java:55-69);
 * - the label takes at most 5 lines with no second line and no control,
 *   else 3; the second line at most 2
 *   (ButtonItemKt$$ExternalSyntheticLambda0.java:87,100,
 *   RadioButtonItemKt$$ExternalSyntheticLambda3.java:85).
 * Near the top and bottom of the round screen it shrinks and fades as it
 * scrolls (EdgeEffect, the ScalingLazyColumn 0.7 and 0.5).
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
    /* the row grows from this height with its text: 52 dp */
    property real minHeight: Theme.size.button
    readonly property bool pressed: button.pressed
    /* the Button inside (tests, and rows that need more) */
    readonly property alias button: button
    readonly property bool selectable: control === "toggle" || control === "radio"
    readonly property bool _on: selectable && checked

    signal clicked()

    function _a(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    /* the stock colours of the row in its state */
    readonly property color containerColor: !clickable ? "transparent"
        : !active ? _a(Theme.color.onSurface, Theme.alpha.disabledContainer)
        : _on ? Theme.color.primaryContainer : Theme.color.surfaceContainer
    readonly property color titleColor: !active ? _a(Theme.color.onSurface, Theme.alpha.disabledContent)
        : _on ? Theme.color.onPrimaryContainer : Theme.color.onSurface
    readonly property color summaryColor: !active ? _a(Theme.color.onSurface, Theme.alpha.disabledContent)
        : _on ? _a(Theme.color.onPrimaryContainer, Theme.alpha.secondaryOnChecked)
        : Theme.color.onSurfaceVariant
    readonly property color iconColor: (!clickable || !active)
        ? _a(Theme.color.onSurface, Theme.alpha.disabledContent) : Theme.color.primary
    /* the radio ring and dot: primary selected, outline not, onSurface 12 % disabled */
    readonly property color radioColor: !active ? _a(Theme.color.onSurface, Theme.alpha.disabledContainer)
        : checked ? Theme.color.primary : Theme.color.outline
    /* the slow effects spring of SwitchButton and RadioButton rows (412 ms) */
    readonly property int colorDuration: Motion.springDuration(Motion.standard.slowEffects.stiffness)
    /* the fast effects spring of the switch and the radio dot (177 ms) */
    readonly property int controlDuration: Motion.springDuration(Motion.standard.fastEffects.stiffness)

    width: parent ? parent.width : Theme.dp(172)
    height: Math.max(minHeight, button.implicitHeight)

    EdgeEffect { id: edge; item: chip }
    transform: Scale {
        origin.x: chip.width / 2
        origin.y: chip.height / 2
        xScale: edge.scale
        yScale: edge.scale
    }

    Button {
        id: button
        anchors.fill: parent
        opacity: edge.alpha
        enabled: chip.active && chip.clickable
        variant: "tonal"
        text: chip.title
        secondaryText: chip.summary
        iconName: chip.iconName
        horizontalPadding: Theme.space.xl
        verticalPadding: chip.selectable ? Theme.space.m : Theme.space.s
        iconSize: Theme.size.icon
        iconSpacing: Theme.space.s
        minimumHeight: chip.minHeight
        radius: chip.clickable ? Theme.shape.large : Theme.dp(16)
        maximumLineCount: chip.summary === "" && chip.control === "none" ? 5 : 3
        secondaryMaximumLineCount: 2
        trailingWidth: chip.selectable ? Theme.dp(32) : 0
        trailingSpacing: Theme.space.s

        containerColor: chip.containerColor
        contentColor: chip.titleColor
        secondaryContentColor: chip.summaryColor
        iconColor: chip.iconColor
        Behavior on containerColor {
            enabled: chip.selectable
            ColorAnimation { duration: chip.colorDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.springEasing }
        }
        Behavior on contentColor {
            enabled: chip.selectable
            ColorAnimation { duration: chip.colorDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.springEasing }
        }
        Behavior on secondaryContentColor {
            enabled: chip.selectable
            ColorAnimation { duration: chip.colorDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.springEasing }
        }

        Accessible.role: chip.control === "toggle" ? Accessible.CheckBox
                       : chip.control === "radio" ? Accessible.RadioButton
                       : chip.clickable ? Accessible.Button : Accessible.StaticText
        Accessible.checkable: chip.selectable
        Accessible.checked: chip.checked

        onClicked: {
            if (chip.control === "toggle") {
                if (typeof Haptics.toggle === "function")
                    Haptics.toggle(!chip.checked)
            } else if (chip.control === "radio" && !chip.checked) {
                if (typeof Haptics.select === "function")
                    Haptics.select()
            }
            chip.clicked()
        }

        // the switch of a SwitchButton (org.asteroid.controls Switch: a
        // 64 x 44 px track with a 4 px border, the thumb 24 -> 36 px, its
        // centre 22 -> 42 px, the tick, 177 ms)
        Switch {
            id: chipSwitch
            objectName: "chipSwitch"
            visible: chip.control === "toggle"
            anchors.centerIn: parent
            checked: chip.checked
            enabled: chip.active
            toggleOnClick: false
        }

        // the radio of a RadioButton: ring 20 dp (40 px) outside with a 2 dp
        // (4 px) stroke, dot 10 dp (20 px) growing with the fast effects spring
        Item {
            id: chipRadio
            objectName: "chipRadio"
            visible: chip.control === "radio"
            anchors.centerIn: parent
            width: Theme.dp(32)
            height: Theme.dp(24)
            property real dotScale: chip.checked ? 1 : 0
            Behavior on dotScale {
                NumberAnimation {
                    duration: chip.controlDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.springEasing
                }
            }
            Rectangle {
                objectName: "chipRadioRing"
                anchors.centerIn: parent
                width: Theme.size.radio
                height: width
                radius: width / 2
                color: "transparent"
                border.width: Theme.size.radioStroke
                border.color: chip.radioColor
            }
            Rectangle {
                objectName: "chipRadioDot"
                anchors.centerIn: parent
                width: Theme.size.radioDot
                height: width
                radius: width / 2
                color: chip.radioColor
                scale: chipRadio.dotScale
                visible: chipRadio.dotScale > 0
            }
        }
    }
}
