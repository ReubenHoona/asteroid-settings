/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Apps & notifications > Notifications (heads-up-alerts-06,
// settings-b-03): App notifications first, then Show new notifications, a
// button whose second line is the choice; a tap opens the selection dialog
// of the same name with "On wrist raise (recommended)" and "Immediately
// (reduces battery life)" (Settings.System
// enable_notification_without_tap_or_tilt, default 0).
SettingsPage {
    id: page
    objectName: "notificationsPage"
    title: qsTrId("id-notifications-page")

    // true: the screen turns on for a new notification (today's behaviour
    // of the launcher before the stock default); false: it waits for a wrist
    // raise. The launcher's heads-up and stream read it.
    ConfigurationValue {
        id: showImmediately
        key: "/org/asteroidos/notifications/show-immediately"
        defaultValue: false
    }

    readonly property var choices: [
        //% "On wrist raise"
        qsTrId("id-notif-show-wrist"),
        //% "Immediately"
        qsTrId("id-notif-show-immediately")]
    readonly property var notes: [
        //% "(recommended)"
        qsTrId("id-note-recommended"),
        //% "(reduces battery life)"
        qsTrId("id-note-reduces-battery")]
    readonly property int current: (showImmediately.value === true || showImmediately.value === "true") ? 1 : 0

    SettingsChip {
        objectName: "appNotificationsItem"
        //% "App notifications"
        title: qsTrId("id-app-notifications")
        onClicked: layerStack.push(appNotificationsLayer)
    }
    SettingsChip {
        objectName: "showNewItem"
        //% "Show new notifications"
        title: qsTrId("id-show-new-notifications")
        summary: page.choices[page.current]
        onClicked: app.choose(qsTrId("id-show-new-notifications"), page.choices, page.current,
                              function (i) { showImmediately.value = (i === 1) }, page.notes)
    }
}
