/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * The round image toggle of the stock Wrist orientation page (CheckableImage
 * View, 80 dp = 160 px circle: wrist_orientation_setting.xml:48-52,
 * settings_wrist_orientation_image_size 80dp). The fill is primary when
 * checked and the surface colour when not
 * (wear_material_button_background.xml: colorPrimary checked, colorSurface
 * otherwise; Theme has no plain surface role, so surfaceContainer) and moves
 * with the fast effects spring. The artwork is drawn here, not copied: a
 * forearm with the watch on it seen from above (kind "wrist": left or right
 * wrist) and the watch from above with its crown on one side (kind "crown").
 *
 *   WristToggle { kind: "wrist"; onLeft: true; checked: wristLeft; onClicked: ... }
 */
Item {
    id: toggle

    property bool checked: false
    /* "wrist" or "crown" */
    property string kind: "wrist"
    /* the left wrist, or the crown on the left */
    property bool onLeft: true
    /* the content description (stock left_wrist_description and so on) */
    property string description: ""

    signal clicked()

    width: Theme.dp(80)
    height: width

    function d(x) { return Theme.dp(x) }

    readonly property color fill: checked ? Theme.color.primary : Theme.color.surfaceContainer
    readonly property color body: checked ? Theme.color.primaryContainer : Theme.color.outline
    readonly property color accent: checked ? Theme.color.onPrimary : Theme.color.primary

    Accessible.role: Accessible.RadioButton
    Accessible.name: toggle.description
    Accessible.checkable: true
    Accessible.checked: toggle.checked

    Rectangle {
        id: disc
        objectName: "wristToggleDisc"
        anchors.fill: parent
        radius: width / 2
        color: toggle.fill
        Behavior on color {
            ColorAnimation {
                duration: Motion.springDuration(Motion.standard.fastEffects.stiffness)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.springEasing
            }
        }
    }

    // the artwork in a 56 dp square in the middle of the circle
    Item {
        id: art
        width: toggle.d(56)
        height: width
        anchors.centerIn: parent

        // a left wrist: the forearm comes from the left; the right wrist is its mirror
        Item {
            id: wrist
            visible: toggle.kind === "wrist"
            anchors.fill: parent
            transform: Scale {
                origin.x: art.width / 2
                xScale: toggle.onLeft ? 1 : -1
            }
            Rectangle {
                x: 0; y: toggle.d(20); width: toggle.d(40); height: toggle.d(16); radius: toggle.d(8)
                color: toggle.body
            }
            Rectangle {
                x: toggle.d(34); y: toggle.d(15); width: toggle.d(22); height: toggle.d(26); radius: toggle.d(11)
                color: toggle.body
            }
            // the watch on the wrist
            Rectangle {
                x: toggle.d(18); y: toggle.d(13); width: toggle.d(15); height: toggle.d(30); radius: toggle.d(4)
                color: Theme.color.background
                border.width: Math.max(1, toggle.d(1.5))
                border.color: toggle.accent
            }
        }

        // the watch from above, the crown on its left or right edge
        Item {
            id: crown
            visible: toggle.kind === "crown"
            anchors.fill: parent
            Rectangle {
                x: toggle.d(12); y: toggle.d(6); width: toggle.d(32); height: toggle.d(44); radius: toggle.d(9)
                color: toggle.body
            }
            Rectangle {
                x: toggle.d(15); y: toggle.d(9); width: toggle.d(26); height: toggle.d(38); radius: toggle.d(6)
                color: Theme.color.background
            }
            Rectangle {
                objectName: "wristToggleCrown"
                x: toggle.onLeft ? toggle.d(6) : toggle.d(43)
                y: toggle.d(20); width: toggle.d(7); height: toggle.d(16); radius: toggle.d(2)
                color: toggle.accent
            }
        }
    }

    MouseArea {
        id: area
        objectName: "wristToggleArea"
        anchors.fill: parent
        onClicked: toggle.clicked()
        Ripple {
            radius: disc.radius
            color: toggle.checked ? Theme.color.onPrimary : Theme.color.onSurface
            pressed: area.pressed
            pressX: area.mouseX
            pressY: area.mouseY
        }
    }
}
