/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * Settings > Modes > Theater mode (stock ClockworkNavRouteCollector$init$53:
 * TheaterSwitchPreference, TheaterCustomizePreference): the switch titled On
 * or Off with the caption "Turns off screen and sounds completely"
 * (pref_priorityTheaterModeDescription), then the Customize row. The
 * launcher's modes engine does what Theater changes (the screen goes off at
 * once, sounds and touch are held); this page only switches the same dconf
 * key as the quick panel's Theater tile (modes-dnd-02).
 */
SettingsPage {
    objectName: "theaterPage"
    //% "Theater mode"
    title: qsTrId("id-theater-mode")

    SettingsChip {
        objectName: "theaterSwitch"
        title: modeState.theater ? qsTrId("id-on") : qsTrId("id-off")
        control: "toggle"
        checked: modeState.theater
        onClicked: modeState.theater = !modeState.theater
    }
    SettingsText {
        objectName: "theaterCaption"
        //% "Turns off screen and sounds completely"
        text: qsTrId("id-theater-caption")
    }
    SettingsChip {
        objectName: "theaterCustomize"
        title: qsTrId("id-customize")
        onClicked: layerStack.push(theaterCustomizeLayer)
    }
}
