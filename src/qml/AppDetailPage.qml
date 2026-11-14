/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings
import Nemo.Configuration
import "AppFormat.js" as AppFormat

// One app (settings-b-05, stock's per-app page titled with the app's label):
// Disable or Enable (Disable? / Other apps may be affected.; the launcher
// hides a disabled app: hidden-apps), Force stop (Force stop? / App may not
// function properly.; greyed while the app does not run) and App info. An app
// of the system (a service) has no Disable. Settings itself cannot be
// disabled (stock cannot_disable_package). Uninstall, Remove upgrades,
// Permissions, Advanced and App licenses are the package manager's and stay
// out.
SettingsPage {
    id: page
    objectName: "appDetailPage"

    // { id, name, process, system }
    property var entry: ({ "id": "", "name": "", "process": "", "system": false })
    title: entry.name

    AppInventory { id: inventory }

    // the apps the launcher does not list (apps' desktop ids)
    ConfigurationValue {
        id: hiddenApps
        key: "/org/asteroidos/launcher/hidden-apps"
        defaultValue: []
    }

    Component { id: dataLayer; AppDataPage { } }

    // whether the app runs, looked at when the page opens and after a force
    // stop (never polled)
    property bool running: false
    function refresh() { running = inventory.isRunning(entry.process) }
    Component.onCompleted: refresh()
    onEntryChanged: refresh()

    // the killed process leaves a moment later: one more look, once
    Timer {
        id: recheck
        interval: 300
        onTriggered: page.refresh()
    }

    readonly property bool disabled: AppFormat.has(hiddenApps.value, entry.id)
    readonly property bool canDisable: !entry.system && entry.id !== "asteroid-settings"

    SettingsChip {
        objectName: "disableItem"
        visible: !page.entry.system
        active: page.canDisable
        //% "Enable"
        title: page.disabled ? qsTrId("id-app-enable")
                             //% "Disable"
                             : qsTrId("id-app-disable")
        onClicked: {
            if (page.disabled) {
                //% "Enable?"
                confirm.ask(qsTrId("id-app-enable-title"), "",
                            function () { hiddenApps.value = AppFormat.minus(hiddenApps.value, page.entry.id) })
            } else {
                //% "Disable?"
                confirm.ask(qsTrId("id-app-disable-title"),
                            //% "Other apps may be affected."
                            qsTrId("id-app-disable-message"),
                            function () { hiddenApps.value = AppFormat.plus(hiddenApps.value, page.entry.id) })
            }
        }
    }
    SettingsChip {
        objectName: "forceStopItem"
        active: page.running
        //% "Force stop"
        title: qsTrId("id-app-force-stop")
        onClicked: {
            //% "Force stop?"
            confirm.ask(qsTrId("id-app-force-stop-title"),
                        //% "App may not function properly."
                        qsTrId("id-app-force-stop-message"),
                        function () {
                            inventory.forceStop(page.entry.process)
                            page.refresh()
                            recheck.restart()
                        })
        }
    }
    SettingsChip {
        objectName: "appDataItem"
        title: qsTrId("id-app-info-page")
        onClicked: layerStack.push(dataLayer, { "entry": page.entry })
    }
}
