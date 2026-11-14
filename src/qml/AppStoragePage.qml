/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings
import Nemo.Configuration
import "AppFormat.js" as AppFormat

// Settings > Apps & notifications > App storage (settings-b-06): a switch
// whose label is the sort order, Data size (on, the default) or App size
// (off), then the apps by that size, largest first, with the size as the
// second line ("12 MB"; one decimal under 10 MB). The apps are those with a
// launcher entry; the sizes come from the same place as App info and are
// summed once when the page opens ("Computing..." until then).
SettingsPage {
    id: page
    objectName: "appStoragePage"
    //% "Storage"
    title: qsTrId("id-app-storage")

    AppInventory { id: inventory }

    Component { id: detailLayer; AppDetailPage { } }

    // stock keeps the sort order: "data" (the default) or "app"
    ConfigurationValue {
        id: sortOrder
        key: "/org/asteroidos/settings/app-storage-sort"
        defaultValue: "data"
    }
    // true: by data size, false: by app size
    readonly property bool byData: String(sortOrder.value) !== "app"

    // { id, name, process, system }, by name
    property var apps: []
    // id -> { app, data, cache }; filled as the sums come in
    property var sizes: ({})
    property int pending: 0
    // the rows: by name until all sizes are known, then by size
    readonly property var rows: {
        var list = apps.slice()
        if (pending > 0)
            return list
        var field = byData ? "data" : "app"
        list.sort(function (a, b) {
            var d = sizes[b.id][field] - sizes[a.id][field]
            return d !== 0 ? d : a.name.localeCompare(b.name)
        })
        return list
    }

    function load() {
        var list = []
        var found = inventory.launcherApps()
        for (var i = 0; i < found.length; i++)
            list.push({ "id": found[i].id, "name": found[i].name, "process": found[i].process, "system": false })
        sizes = ({})
        pending = list.length
        apps = list
        for (i = 0; i < list.length; i++) {
            // the same names as App info looks for
            var pkg = inventory.packageOf(list[i].id)
            var names = []
            var all = [list[i].id, list[i].process, pkg]
            for (var j = 0; j < all.length; j++)
                if (all[j] && names.indexOf(all[j]) < 0)
                    names.push(all[j])
            inventory.computeSizes(list[i].id, names, pkg)
        }
    }
    Connections {
        target: inventory
        function onSizesReady(key, appBytes, dataBytes, cacheBytes) {
            var map = {}
            for (var k in page.sizes)
                map[k] = page.sizes[k]
            if (map[key] !== undefined || !page.apps.some(function (a) { return a.id === key }))
                return
            map[key] = { "app": appBytes, "data": dataBytes, "cache": cacheBytes }
            page.sizes = map
            page.pending = Math.max(0, page.pending - 1)
        }
    }
    Component.onCompleted: load()

    function sizeText(id) {
        var s = sizes[id]
        if (s === undefined)
            return qsTrId("id-computing")
        return AppFormat.formatSize(byData ? s.data : s.app, Qt.locale().decimalPoint)
    }

    SettingsChip {
        objectName: "sortSwitch"
        //% "Data size"
        title: page.byData ? qsTrId("id-storage-sort-data")
                           //% "App size"
                           : qsTrId("id-storage-sort-app")
        control: "toggle"
        checked: page.byData
        onClicked: sortOrder.value = page.byData ? "app" : "data"
    }
    Repeater {
        model: page.rows
        delegate: SettingsChip {
            objectName: "storageItem"
            title: modelData.name
            summary: page.sizeText(modelData.id)
            onClicked: layerStack.push(detailLayer, { "entry": modelData })
        }
    }
}
