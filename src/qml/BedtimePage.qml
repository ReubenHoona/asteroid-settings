/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

/*
 * Settings > Modes > Bedtime mode, as the Pixel Watch's page
 * (PixelWatchNavRouteCollector$init$13.java): the switch titled On or Off with
 * the caption "Settle in for sleep" (pref_priorityBedtimeModeDescription), the
 * Auto-bedtime group (AutoBedtimeModeEntryExitCategory: the switches Auto
 * enter and Auto exit under one caption, no group title), then Customize.
 *
 * Auto-bedtime (modes-dnd-18) is stock's auto_bedtime_mode, 0 off, 1 both,
 * 2 enter only, 3 exit only (AutoBedtimeModeEntryExitCategory.java:79-140),
 * here /org/asteroidos/modes/auto-bedtime, default 0. Stock shows the group
 * unless auto_bedtime_mode_supported says no (default yes); this watch has no
 * sleep sensing yet (sensor hub, W3-app-sensorlogd), so the group stays hidden
 * until /org/asteroidos/modes/auto-bedtime-supported is true. Whatever senses
 * sleep turns it on and reads the value.
 *
 * Stock's Bedtime page has no phone-sync row: the phone's Do Not Disturb is
 * mapped to the watch's Do Not Disturb (ModeSynchronizerImpl.java:113-117),
 * so the earlier "Start with phone's Do Not Disturb" switch is not built
 * (DECISIONS Q53, modes-dnd-19).
 */
SettingsPage {
    id: page
    objectName: "bedtimePage"
    //% "Bedtime mode"
    title: qsTrId("id-bedtime-mode")

    ConfigurationValue {
        id: auto
        key: "/org/asteroidos/modes/auto-bedtime"
        defaultValue: 0
    }
    ConfigurationValue {
        id: autoSupported
        key: "/org/asteroidos/modes/auto-bedtime-supported"
        defaultValue: false
    }

    readonly property int autoMode: Math.max(0, Math.min(3, Number(auto.value) || 0))
    readonly property bool autoEnter: autoMode === 1 || autoMode === 2
    readonly property bool autoExit: autoMode === 1 || autoMode === 3
    readonly property bool autoShown: autoSupported.value === true || autoSupported.value === "true"
    // the two switches to the one value (AutoBedtimeModeEntryExitCategory.java:96-111)
    function autoValue(enter, exit) {
        return enter && exit ? 1 : enter ? 2 : exit ? 3 : 0
    }

    SettingsChip {
        objectName: "bedtimeSwitch"
        title: modeState.bedtime ? qsTrId("id-on") : qsTrId("id-off")
        control: "toggle"
        checked: modeState.bedtime
        onClicked: modeState.bedtime = !modeState.bedtime
    }
    SettingsText {
        objectName: "bedtimeCaption"
        //% "Settle in for sleep"
        text: qsTrId("id-bedtime-caption")
    }
    SettingsChip {
        objectName: "autoEnterSwitch"
        visible: page.autoShown
        //% "Auto enter"
        title: qsTrId("id-auto-enter")
        control: "toggle"
        checked: page.autoEnter
        onClicked: auto.value = page.autoValue(!page.autoEnter, page.autoExit)
    }
    SettingsChip {
        objectName: "autoExitSwitch"
        visible: page.autoShown
        //% "Auto exit"
        title: qsTrId("id-auto-exit")
        control: "toggle"
        checked: page.autoExit
        onClicked: auto.value = page.autoValue(page.autoEnter, !page.autoExit)
    }
    SettingsText {
        objectName: "autoBedtimeCaption"
        visible: page.autoShown
        //% "Bedtime will turn on and exit automatically based on sleep sensing"
        text: qsTrId("id-auto-bedtime-caption")
    }
    SettingsChip {
        objectName: "bedtimeCustomize"
        title: qsTrId("id-customize")
        onClicked: layerStack.push(bedtimeCustomizeLayer)
    }
}
