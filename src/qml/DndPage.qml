/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * Settings > Modes > Do Not Disturb (stock ClockworkNavRouteCollector$init$50:
 * DoNotDisturbSwitchPreference, DoNotDisturbCustomizePreference): the switch
 * titled On or Off with its caption "Silences watch to minimize
 * interruptions" (pref_priorityDoNotDisturbDescription), then the Customize
 * row. No dialog from the switch (DoNotDisturbSwitchPreference.java:95-104).
 * The same dconf key as the quick panel's tile; the launcher's modes engine
 * keeps Do Not Disturb and Bedtime apart (the one turned on last wins) and
 * asteroid-btsyncd keeps the phone's Do Not Disturb in step with it.
 */
SettingsPage {
    objectName: "dndPage"
    title: qsTrId("id-dnd-page")

    SettingsChip {
        objectName: "dndSwitch"
        title: modeState.doNotDisturb ? qsTrId("id-on") : qsTrId("id-off")
        control: "toggle"
        checked: modeState.doNotDisturb
        onClicked: modeState.doNotDisturb = !modeState.doNotDisturb
    }
    SettingsText {
        objectName: "dndCaption"
        //% "Silences watch to minimize interruptions"
        text: qsTrId("id-dnd-caption")
    }
    SettingsChip {
        objectName: "dndCustomize"
        //% "Customize"
        title: qsTrId("id-customize")
        onClicked: layerStack.push(dndCustomizeLayer)
    }
}
