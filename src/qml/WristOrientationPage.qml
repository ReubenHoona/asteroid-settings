/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import Nemo.DBus

/*
 * Settings > Display > Wrist orientation, stock's own page
 * (wrist_orientation_setting.xml, WristOrientationFragment), px on the
 * 384 px screen (2 px per dp): one vertical scroll page, padding top 16.64 %
 * of the height (64 px), bottom 36.46 % (140 px), sides 5.2 % of the width
 * (20 px; settings_top_margin_top_element_title, settings_bottom_margin_
 * standard, settings_dialog_horizontal_margin). The title "Wrist
 * orientation" (Title3, 16 sp: titleMedium) centred between 7.3 % margins
 * (28 px); "Wrist" (Body4, 14 sp: bodyMedium) 12 dp above and the two 80 dp
 * round toggles 4 dp under it, 8 dp apart (4 dp each side), each with its
 * caption "Left" / "Right" (Caption2, 12 sp: bodySmall) 8 dp below; "Crown"
 * 16 dp above, the same two toggles. A tap on the one that is chosen does
 * nothing; the other applies at once, no question.
 *
 * The choice is one number, the stock wear_wrist_orientation_mode:
 *   0 left wrist, crown on the right (the default)   1 left wrist, crown left
 *   2 right wrist, crown on the right                3 right wrist, crown left
 * written to /org/asteroidos/settings/wrist-orientation-mode; the launcher
 * and the sensor hub flip the display and the crown from it (W3). A crown
 * change holds the screen on for 1 s (stock's FULL_WAKE_LOCK for 1000 ms,
 * ON_AFTER_RELEASE): mce is asked for the display on and a blanking pause,
 * and the pause ends 1 s later. Nothing runs unless a toggle is tapped.
 */
Item {
    id: page
    objectName: "wristOrientationPage"

    property int depth
    property var pop
    //% "Wrist orientation"
    property string title: qsTrId("id-wrist-orientation")

    ConfigurationValue {
        id: orientation
        key: "/org/asteroidos/settings/wrist-orientation-mode"
        defaultValue: 0
    }
    DBusInterface {
        id: mce
        bus: DBus.SystemBus
        service: "com.nokia.mce"
        path: "/com/nokia/mce/request"
        iface: "com.nokia.mce.request"
    }

    // stock's content descriptions of the two headers
    //% "Which wrist do you want to wear your watch on?"
    readonly property string wristHint: qsTrId("id-wrist-description")
    //% "Where do you want the crown? Changing the location will flip the display."
    readonly property string crownHint: qsTrId("id-crown-description")

    // the mode as the two choices; anything out of range reads as 0
    readonly property int mode: {
        var m = Number(orientation.value)
        return (m === 0 || m === 1 || m === 2 || m === 3) ? m : 0
    }
    readonly property bool wristLeft: mode === 0 || mode === 1
    readonly property bool crownRight: mode === 0 || mode === 2

    function modeOf(left, right) { return left ? (right ? 0 : 1) : (right ? 2 : 3) }

    function chooseWrist(left) {
        if (left === wristLeft)
            return
        orientation.value = modeOf(left, crownRight)
    }
    function chooseCrown(right) {
        if (right === crownRight)
            return
        orientation.value = modeOf(wristLeft, right)
        holdScreenOn()
    }
    // stock WristOrientationFragment.toggleCrown: wake lock for 1000 ms
    function holdScreenOn() {
        mce.call("req_display_state_on", [])
        mce.call("req_display_blanking_pause", [])
        releaseTimer.restart()
    }
    Timer {
        id: releaseTimer
        interval: 1000
        onTriggered: mce.call("req_display_cancel_blanking_pause", [])
    }

    // the layout numbers, from the screen
    readonly property int topPad: Math.ceil(height * 0.1664)
    readonly property int bottomPad: Math.ceil(height * 0.3646)
    readonly property int sidePad: Math.ceil(width * 0.052)
    readonly property int titlePad: Math.round(width * 0.073)

    Flickable {
        id: flick
        objectName: "settingsFlickable"
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.y + column.height + page.bottomPad
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: column
            objectName: "settingsColumn"
            y: page.topPad
            x: page.sidePad
            width: page.width - 2 * page.sidePad

            Label {
                objectName: "wristTitle"
                width: parent.width
                role: "titleMedium"
                horizontalAlignment: Text.AlignHCenter
                leftPadding: page.titlePad - page.sidePad
                rightPadding: leftPadding
                wrapMode: Text.Wrap
                text: page.title
                Accessible.role: Accessible.Heading
            }
            Item { width: 1; height: Theme.dp(12) }
            Label {
                objectName: "wristHeader"
                width: parent.width
                role: "bodyMedium"
                horizontalAlignment: Text.AlignHCenter
                leftPadding: page.titlePad - page.sidePad
                rightPadding: leftPadding
                //% "Wrist"
                text: qsTrId("id-wrist")
                Accessible.name: page.wristHint
                Accessible.role: Accessible.Heading
            }
            Item { width: 1; height: Theme.dp(4) }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.dp(8)
                Column {
                    WristToggle {
                        objectName: "leftWristButton"
                        kind: "wrist"
                        onLeft: true
                        checked: page.wristLeft
                        //% "Left wrist"
                        description: qsTrId("id-left-wrist")
                        onClicked: page.chooseWrist(true)
                    }
                    Item { width: 1; height: Theme.dp(8) }
                    Label {
                        objectName: "leftWristCaption"
                        width: Theme.dp(80)
                        role: "bodySmall"
                        horizontalAlignment: Text.AlignHCenter
                        //% "Left"
                        text: qsTrId("id-left")
                        Accessible.ignored: true
                    }
                }
                Column {
                    WristToggle {
                        objectName: "rightWristButton"
                        kind: "wrist"
                        onLeft: false
                        checked: !page.wristLeft
                        //% "Right wrist"
                        description: qsTrId("id-right-wrist")
                        onClicked: page.chooseWrist(false)
                    }
                    Item { width: 1; height: Theme.dp(8) }
                    Label {
                        objectName: "rightWristCaption"
                        width: Theme.dp(80)
                        role: "bodySmall"
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTrId("id-right")
                        Accessible.ignored: true
                    }
                }
            }
            Item { width: 1; height: Theme.dp(16) }
            Label {
                objectName: "crownHeader"
                width: parent.width
                role: "bodyMedium"
                horizontalAlignment: Text.AlignHCenter
                leftPadding: page.titlePad - page.sidePad
                rightPadding: leftPadding
                //% "Crown"
                text: qsTrId("id-crown")
                Accessible.name: page.crownHint
                Accessible.role: Accessible.Heading
            }
            Item { width: 1; height: Theme.dp(4) }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.dp(8)
                Column {
                    WristToggle {
                        objectName: "leftCrownButton"
                        kind: "crown"
                        onLeft: true
                        checked: !page.crownRight
                        //% "Crown on the left"
                        description: qsTrId("id-left-crown")
                        onClicked: page.chooseCrown(false)
                    }
                    Item { width: 1; height: Theme.dp(8) }
                    Label {
                        objectName: "leftCrownCaption"
                        width: Theme.dp(80)
                        role: "bodySmall"
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTrId("id-left")
                        Accessible.ignored: true
                    }
                }
                Column {
                    WristToggle {
                        objectName: "rightCrownButton"
                        kind: "crown"
                        onLeft: false
                        checked: page.crownRight
                        //% "Crown on the right"
                        description: qsTrId("id-right-crown")
                        onClicked: page.chooseCrown(true)
                    }
                    Item { width: 1; height: Theme.dp(8) }
                    Label {
                        objectName: "rightCrownCaption"
                        width: Theme.dp(80)
                        role: "bodySmall"
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTrId("id-right")
                        Accessible.ignored: true
                    }
                }
            }
        }
    }
}
