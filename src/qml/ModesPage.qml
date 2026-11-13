/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * Settings > Modes (stock ClockworkNavRouteCollector$init$44.java, the
 * ModesViewModel list): one row per mode with its icon and label and no
 * summary (mask 207 in DoNotDisturbModePreference, BedtimeModePreference and
 * TheaterModePreference): Do Not Disturb (ic_cc_settings_do_not_disturb),
 * Bedtime (ic_cc_settings_bedtime), Theater (ic_cc_settings_theater_v). Each
 * opens its own page, titled Do Not Disturb / Bedtime mode / Theater mode
 * (settings-a-01, modes-dnd-01). The icons are eos originals drawn to the
 * same roles (src/icons).
 */
SettingsPage {
    objectName: "modesPage"
    title: qsTrId("id-modes-page")

    SettingsChip {
        objectName: "modesDndItem"
        //% "Do Not Disturb"
        title: qsTrId("id-dnd-page")
        iconName: app.iconDir + "eos-settings-modes"
        onClicked: layerStack.push(dndLayer)
    }
    SettingsChip {
        objectName: "modesBedtimeItem"
        //% "Bedtime"
        title: qsTrId("id-bedtime-row")
        iconName: app.iconDir + "eos-settings-bedtime"
        onClicked: layerStack.push(bedtimeLayer)
    }
    SettingsChip {
        objectName: "modesTheaterItem"
        //% "Theater"
        title: qsTrId("id-theater-row")
        iconName: app.iconDir + "eos-settings-theater"
        onClicked: layerStack.push(theaterLayer)
    }
}
