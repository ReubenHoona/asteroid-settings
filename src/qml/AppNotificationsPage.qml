/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import "AppFormat.js" as AppFormat

// Settings > Apps & notifications > Notifications > App notifications
// (settings-b-04): first Show apps (All apps, Notifications off, Core system
// apps; stock's AppNotificationsPreference), then one row per app with its
// name and no second line. The apps are the watch apps that post
// notifications (WatchApps) and the phone apps asteroid-btsyncd has seen in
// notifications (known-apps). A tap opens the app's Notifications page.
SettingsPage {
    id: page
    objectName: "appNotificationsPage"
    title: qsTrId("id-app-notifications")

    WatchApps { id: watch }

    // "<package>|<name>", kept by asteroid-btsyncd
    ConfigurationValue {
        id: known
        key: "/org/asteroidos/notifications/known-apps"
        defaultValue: []
    }
    // the watch apps and categories whose notifications are off (the
    // launcher's notification manager drops them)
    ConfigurationValue {
        id: disabledApps
        key: "/org/asteroidos/notifications/disabled-apps"
        defaultValue: []
    }
    // the phone apps muted; asteroid-btsyncd turns a change into mute and
    // unmute for that package
    ConfigurationValue {
        id: blockedPackages
        key: "/org/asteroidos/notifications/blocked-packages"
        defaultValue: []
    }

    Component { id: appLayer; AppNotificationPage { } }

    // 0 All apps, 1 Notifications off, 2 Core system apps
    property int filter: 0
    readonly property var filterNames: [
        //% "All apps"
        qsTrId("id-show-apps-all"),
        //% "Notifications off"
        qsTrId("id-show-apps-off"),
        //% "Core system apps"
        qsTrId("id-show-apps-core")]

    // every app: { id, name, phone, core, off }
    readonly property var all: {
        var out = []
        var i
        for (i = 0; i < watch.notifying.length; i++) {
            var w = watch.notifying[i]
            out.push({ "id": w.id, "name": w.name, "phone": false, "core": w.core,
                       "off": AppFormat.has(disabledApps.value, w.id) })
        }
        var phone = AppFormat.parseKnown(known.value)
        for (i = 0; i < phone.length; i++)
            out.push({ "id": phone[i].id, "name": phone[i].name, "phone": true, "core": false,
                       "off": AppFormat.has(blockedPackages.value, phone[i].id) })
        return out
    }
    readonly property var shownApps: all.filter(function (a) {
        return page.filter === 0 || (page.filter === 1 && a.off) || (page.filter === 2 && a.core)
    })

    SettingsChip {
        objectName: "showAppsItem"
        //% "Show apps"
        title: qsTrId("id-show-apps")
        summary: page.filterNames[page.filter]
        onClicked: app.choose(qsTrId("id-show-apps"), page.filterNames, page.filter,
                              function (i) { page.filter = i })
    }
    Repeater {
        model: page.shownApps
        delegate: SettingsChip {
            objectName: "appNotificationItem"
            title: modelData.name
            onClicked: layerStack.push(appLayer, { "appId": modelData.id, "appName": modelData.name,
                                                    "phone": modelData.phone })
        }
    }
}
