/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

/*
 * Settings > Display > Touch lock (stock PixelWatchNavRouteCollector$init$22:
 * the page "Touch lock" with one button, and the caption). The button turns
 * Touch lock on at once (stock TouchLockPreference$clickBehavior$1 writes
 * Settings.Global wet_mode_on = 1) and the watch shows the face locked, so
 * Settings ends: the launcher's touch lock (W2-launcher-power-system) takes
 * /org/asteroidos/settings/touch-lock, drops the touches, goes to the face
 * and puts the key back to false when the crown hold ends it. Water
 * ejection stays hidden (config_supportWaterEjection false).
 */
SettingsPage {
    id: page
    objectName: "touchLockPage"
    //% "Touch lock"
    title: qsTrId("id-touch-lock")

    ConfigurationValue {
        id: touchLock
        key: "/org/asteroidos/settings/touch-lock"
        defaultValue: false
    }

    Timer {
        id: closeTimer
        interval: 150
        onTriggered: app.closeApp()
    }

    SettingsChip {
        objectName: "touchLockButton"
        title: qsTrId("id-touch-lock")
        onClicked: {
            touchLock.value = true
            closeTimer.restart()
        }
    }
    SettingsText {
        objectName: "touchLockCaption"
        //% "Turns off touch screen. Press & hold crown for 2 sec. to turn it back on."
        text: qsTrId("id-touch-lock-explain")
    }
}
