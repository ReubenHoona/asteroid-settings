/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * Settings > Modes (stock ClockworkNavRouteCollector$init$44.java): one row
 * per mode with its icon and label, no summary: Do Not Disturb, Bedtime,
 * Theater. A stub from W1-settings-structure: Do Not Disturb opens today's
 * page (with Bedtime on it); W2-settings-sound-vibration-modes adds the
 * Bedtime and Theater rows and their pages (settings-a-01).
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
}
