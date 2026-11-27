/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import "whatsnew.js" as WhatsNew

// Settings > General as stock CP3A (SysUI general settings, jbk.java:62-177):
// Show unread notification indicator (the launcher's dot on the watch face),
// Autolaunch media controls (the launcher opens the media controls when
// phone playback starts), Start tutorial (goes to the watch face and starts
// the navigation tutorial), What's new (setup-wizard-15, CR-42: stock's Pixel
// Tips has What's new beside the navigation tutorial, sysui jbm.java:56-62;
// shown while eos-update's whatsnew-version and whatsnew-notes both hold
// something, it opens the last update's pages, WhatsNewPage) and App view
// (List view / Grid view). The temperature
// unit moved to the Weather app (stock has it there only). Stock has no quick settings editor
// (fixed order from the resource array), so there is none here (DECISIONS Q30).
SettingsPage {
    id: page
    objectName: "generalPage"
    title: qsTrId("id-general-page")

    ConfigurationValue {
        id: unreadDot
        key: "/org/asteroidos/notifications/unread-dot"
        defaultValue: true
    }
    ConfigurationValue {
        id: autolaunchMedia
        key: "/org/asteroidos/ux/autolaunch-media"
        defaultValue: false
    }
    // the app list opens as the grid unless the user chose the list (the
    // Wear OS 6 emulator, AllAppsLauncherActivity; the layer's default,
    // NEWLOOK-61 N61-15; CP3A: the list)
    ConfigurationValue {
        id: appLauncher
        key: "/desktop/asteroid/applauncher"
        defaultValue: "file:///usr/share/asteroid-launcher/applauncher/007-wear-grid.qml"
    }
    // the launcher starts the navigation tutorial when this changes
    // ("tutorial@<ms>", as open-face-picker)
    ConfigurationValue {
        id: tutorialRequest
        key: "/org/asteroidos/launcher/start-tutorial"
        defaultValue: ""
    }
    // what eos-update publishes after an update confirmed itself (CR-42)
    ConfigurationValue {
        id: whatsNewVersion
        key: "/org/asteroidos/eos-update/whatsnew-version"
        defaultValue: ""
    }
    ConfigurationValue {
        id: whatsNewNotes
        key: "/org/asteroidos/eos-update/whatsnew-notes"
        defaultValue: ""
    }

    // the two stock views: the Wear OS list (006) and the grid (007)
    readonly property string listView: "file:///usr/share/asteroid-launcher/applauncher/006-wear-list.qml"
    readonly property string gridView: "file:///usr/share/asteroid-launcher/applauncher/007-wear-grid.qml"
    readonly property bool grid: String(appLauncher.value).indexOf("007-") >= 0
    readonly property var viewNames: [
        //% "List view"
        qsTrId("id-app-view-list"),
        //% "Grid view"
        qsTrId("id-app-view-grid")]

    SettingsChip {
        objectName: "unreadDotSwitch"
        //% "Show unread notification indicator"
        title: qsTrId("id-unread-dot")
        control: "toggle"
        checked: unreadDot.value
        onClicked: unreadDot.value = !unreadDot.value
    }
    SettingsChip {
        objectName: "autolaunchMediaSwitch"
        //% "Autolaunch media controls"
        title: qsTrId("id-autolaunch-media")
        control: "toggle"
        checked: autolaunchMedia.value
        onClicked: autolaunchMedia.value = !autolaunchMedia.value
    }
    SettingsChip {
        objectName: "startTutorialItem"
        //% "Start tutorial"
        title: qsTrId("id-start-tutorial")
        onClicked: {
            tutorialRequest.value = "tutorial@" + Date.now()
            // Settings ends and the face shows the tutorial
            closeTimer.start()
        }
    }
    SettingsChip {
        objectName: "whatsNewItem"
        visible: WhatsNew.available(whatsNewVersion.value, whatsNewNotes.value)
        //% "What's new"
        title: qsTrId("id-whats-new")
        onClicked: layerStack.push(whatsNewLayer)
    }
    SettingsChip {
        objectName: "appViewItem"
        //% "App view"
        title: qsTrId("id-app-view")
        summary: page.viewNames[page.grid ? 1 : 0]
        onClicked: app.choose(qsTrId("id-app-view"), page.viewNames, page.grid ? 1 : 0,
                              function (i) { appLauncher.value = i === 1 ? page.gridView : page.listView })
    }

    // the launcher has read the request when this fires (one shot)
    Timer {
        id: closeTimer
        interval: 150
        onTriggered: app.closeApp()
    }
}
