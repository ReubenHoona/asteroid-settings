/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Apps & notifications (stock prefs_apps.xml): Assistant (its voice
// recognition). Do Not Disturb is under Modes in CP3A (settings-a-01). The
// phone decides which apps notify (Gadgetbridge); a notification's long press
// mutes its app.
SettingsPage {
    objectName: "appsPage"
    title: qsTrId("id-apps-page")

    SettingsChip {
        objectName: "assistantItem"
        //% "Assistant"
        title: qsTrId("id-assistant-page")
        onClicked: layerStack.push(assistantLayer)
    }
}
