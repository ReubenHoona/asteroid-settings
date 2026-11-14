/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import "AppFormat.js" as AppFormat

// One app's Notifications (settings-b-04, stock AppNotificationsDetail): the
// page is titled Notifications, a category headed by the app's name holds one
// switch labelled On or Off. Stock's Live updates and the channel categories
// stay out: our notifications have no channels.
// A watch app's switch edits disabled-apps, a phone app's blocked-packages.
SettingsPage {
    id: page
    objectName: "appNotificationPage"
    title: qsTrId("id-notifications-page")

    property string appId: ""
    property string appName: ""
    property bool phone: false

    ConfigurationValue {
        id: disabledApps
        key: "/org/asteroidos/notifications/disabled-apps"
        defaultValue: []
    }
    ConfigurationValue {
        id: blockedPackages
        key: "/org/asteroidos/notifications/blocked-packages"
        defaultValue: []
    }

    readonly property bool on: !AppFormat.has(page.phone ? blockedPackages.value : disabledApps.value, page.appId)

    SettingsCategory {
        objectName: "appNotificationCategory"
        text: page.appName
    }
    SettingsChip {
        objectName: "appNotificationSwitch"
        title: page.on ? qsTrId("id-on") : qsTrId("id-off")
        control: "toggle"
        checked: page.on
        onClicked: {
            if (page.phone)
                blockedPackages.value = page.on ? AppFormat.plus(blockedPackages.value, page.appId)
                                                : AppFormat.minus(blockedPackages.value, page.appId)
            else
                disabledApps.value = page.on ? AppFormat.plus(disabledApps.value, page.appId)
                                             : AppFormat.minus(disabledApps.value, page.appId)
        }
    }
}
