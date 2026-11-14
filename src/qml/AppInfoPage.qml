/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings

// Settings > Apps & notifications > App info (settings-b-05): Show apps,
// Installed apps (default; the apps with a launcher entry) or System apps
// (the background services of the image), then the apps by name. A tap
// opens the app's page.
SettingsPage {
    id: page
    objectName: "appInfoPage"
    title: qsTrId("id-app-info-page")

    AppInventory { id: inventory }
    WatchApps { id: watch }

    Component { id: detailLayer; AppDetailPage { } }

    // 0 Installed apps, 1 System apps
    property int showing: 0
    readonly property var showNames: [
        //% "Installed apps"
        qsTrId("id-show-apps-installed"),
        //% "System apps"
        qsTrId("id-show-apps-system")]

    // { id, name, process, system }
    function entriesOf(system) {
        var out = []
        var i
        if (!system) {
            var apps = inventory.launcherApps()
            for (i = 0; i < apps.length; i++)
                out.push({ "id": apps[i].id, "name": apps[i].name, "process": apps[i].process, "system": false })
            return out
        }
        for (i = 0; i < watch.services.length; i++) {
            var s = watch.services[i]
            // a service whose package is not on this image is not listed
            if (inventory.version(s.id) !== "")
                out.push({ "id": s.id, "name": s.name, "process": s.process, "system": true })
        }
        out.sort(function (a, b) { return a.name.localeCompare(b.name) })
        return out
    }
    readonly property var entries: entriesOf(showing === 1)

    // the app to show at once (the deep link app_info, CR-17): its desktop id,
    // with or without ".desktop"; an app not found leaves the list
    property string appId: ""
    function showApp(id) {
        id = String(id).replace(/\.desktop$/, "")
        if (id === "")
            return
        for (var sys = 0; sys < 2; sys++) {
            var list = entriesOf(sys === 1)
            for (var i = 0; i < list.length; i++) {
                if (list[i].id === id) {
                    showing = sys
                    layerStack.push(detailLayer, { "entry": list[i] })
                    return
                }
            }
        }
    }
    Component.onCompleted: if (appId !== "") Qt.callLater(page.showApp, appId)

    SettingsChip {
        objectName: "showAppsItem"
        //% "Show apps"
        title: qsTrId("id-show-apps")
        summary: page.showNames[page.showing]
        onClicked: app.choose(qsTrId("id-show-apps"), page.showNames, page.showing,
                              function (i) { page.showing = i })
    }
    Repeater {
        model: page.entries
        delegate: SettingsChip {
            objectName: "appItem"
            title: modelData.name
            onClicked: layerStack.push(detailLayer, { "entry": modelData })
        }
    }
}
