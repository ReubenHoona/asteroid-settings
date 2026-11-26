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
// switch labelled On or Off. Stock's channel categories stay out: our
// notifications have no channels.
// A watch app's switch edits disabled-apps, a phone app's blocked-packages.
// Live updates (NotificationDetailsViewModel, LiveUpdatesPreference: for an
// app that may post promoted notifications, a category "Live updates" with
// a switch labelled On or Off and the caption "Display ongoing,
// time-sensitive notifications on the watch face"): for a watch app that
// posts ongoing activities (WatchApps ongoing). Off puts the app's desktop
// id (no ".desktop") in /org/asteroidos/ongoing/muted-apps, the list the
// launcher's OngoingFeed hands to its ongoing registry (whose chip skips
// those apps; the chip's long press adds to it too); On takes it out.
SettingsPage {
    id: page
    objectName: "appNotificationPage"
    title: qsTrId("id-notifications-page")

    property string appId: ""
    property string appName: ""
    property bool phone: false
    property bool ongoing: false

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

    ConfigurationValue {
        id: mutedApps
        key: "/org/asteroidos/ongoing/muted-apps"
        defaultValue: []
    }

    readonly property bool on: !AppFormat.has(page.phone ? blockedPackages.value : disabledApps.value, page.appId)
    // the launcher matches the ids without ".desktop" and blanks
    function appOf(id) { return String(id).trim().replace(/\.desktop$/, "") }
    readonly property var mutedOthers: AppFormat.asList(mutedApps.value).filter(function (a) {
        return page.appOf(a) !== page.appId
    })
    readonly property bool liveOn: AppFormat.asList(mutedApps.value).length === page.mutedOthers.length

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
    SettingsCategory {
        objectName: "liveUpdatesCategory"
        visible: page.ongoing && !page.phone
        //% "Live updates"
        text: qsTrId("id-live-updates")
    }
    SettingsChip {
        objectName: "liveUpdatesSwitch"
        visible: page.ongoing && !page.phone
        title: page.liveOn ? qsTrId("id-on") : qsTrId("id-off")
        control: "toggle"
        checked: page.liveOn
        onClicked: mutedApps.value = page.liveOn ? page.mutedOthers.concat([page.appId]) : page.mutedOthers
    }
    SettingsText {
        objectName: "liveUpdatesCaption"
        visible: page.ongoing && !page.phone
        //% "Display ongoing, time-sensitive notifications on the watch face"
        text: qsTrId("id-live-updates-explain")
    }
}
