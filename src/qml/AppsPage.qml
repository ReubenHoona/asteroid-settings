/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// Settings > Apps & notifications (settings-b-02). Stock prefs_apps.xml rows,
// in its order, with no icons: Notifications, Default apps, Unused apps,
// App info, App permissions, Privacy dashboard, App storage; Assistant last
// (stock shows it on local-edition devices). Default apps, Unused apps, App
// permissions and Privacy dashboard are PermissionController concepts with
// no equivalent here and stay out. Do Not Disturb is under Modes.
SettingsPage {
    objectName: "appsPage"
    title: qsTrId("id-apps-page")

    SettingsChip {
        objectName: "notificationsItem"
        //% "Notifications"
        title: qsTrId("id-notifications-page")
        onClicked: layerStack.push(notificationsLayer)
    }
    SettingsChip {
        objectName: "appInfoItem"
        //% "App info"
        title: qsTrId("id-app-info-page")
        onClicked: layerStack.push(appInfoLayer)
    }
    SettingsChip {
        objectName: "appStorageItem"
        //% "App storage"
        title: qsTrId("id-app-storage-page")
        onClicked: layerStack.push(appStorageLayer)
    }
    SettingsChip {
        objectName: "assistantItem"
        //% "Assistant"
        title: qsTrId("id-assistant-page")
        onClicked: layerStack.push(assistantLayer)
    }
}
