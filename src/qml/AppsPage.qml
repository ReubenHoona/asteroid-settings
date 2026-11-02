/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Apps & notifications (stock prefs_apps.xml): Do Not Disturb.
// The phone decides which apps notify (Gadgetbridge); a notification's
// long press mutes its app.
SettingsPage {
    objectName: "appsPage"
    title: qsTrId("id-apps-page")

    ConfigurationValue {
        id: doNotDisturb
        key: "/org/asteroidos/notifications/do-not-disturb"
        defaultValue: false
    }

    SettingsChip {
        objectName: "dndItem"
        //% "Do Not Disturb"
        title: qsTrId("id-dnd-page")
        summary: doNotDisturb.value ? qsTrId("id-on") : qsTrId("id-off")
        onClicked: layerStack.push(dndLayer)
    }
}
