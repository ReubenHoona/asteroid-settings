/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * Settings > Location (stock main_location). A stub from
 * W1-settings-structure: W3-settings-apps-privacy gives it its rows and then
 * shows the main list entry (PageReady.js).
 */
SettingsPage {
    objectName: "locationPage"
    title: qsTrId("id-location-page")
}
