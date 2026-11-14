/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings
import "AppFormat.js" as AppFormat

// An app's own "App info" page (settings-b-05, stock's App info): the
// information rows Version, Storage (the installed size of its package),
// Data (its files in ~/.local/share and ~/.config) and Cache (~/.cache), each
// "Computing..." until the sizes are summed, then Clear data (Delete app
// data? / All this app's data will be permanently deleted. ...; toast Data
// cleared) and Clear cache (toast Cache cleared).
SettingsPage {
    id: page
    objectName: "appDataPage"
    //% "App info"
    title: qsTrId("id-app-info-page")

    // { id, name, process, system }
    property var entry: ({ "id": "", "name": "", "process": "", "system": false })

    AppInventory { id: inventory }

    // the packages of the services carry the service's name; an app's package
    // is the one that installed its desktop entry
    readonly property string packageName: entry.system ? entry.id : inventory.packageOf(entry.id)
    // the directories the app may keep its files in, by name
    readonly property var names: {
        var out = []
        var all = [entry.id, entry.process, packageName]
        for (var i = 0; i < all.length; i++)
            if (all[i] && out.indexOf(all[i]) < 0)
                out.push(all[i])
        return out
    }

    // null while computing
    property var sizes: null
    function compute() {
        sizes = null
        inventory.computeSizes(entry.id, names, packageName)
    }
    Connections {
        target: inventory
        function onSizesReady(key, appBytes, dataBytes, cacheBytes) {
            if (key === page.entry.id)
                page.sizes = { "app": appBytes, "data": dataBytes, "cache": cacheBytes }
        }
    }
    Component.onCompleted: compute()

    function size(field) {
        return sizes === null ? computing : AppFormat.formatSize(sizes[field], Qt.locale().decimalPoint)
    }
    //% "Computing…"
    readonly property string computing: qsTrId("id-computing")

    SettingsChip {
        objectName: "versionInfo"
        clickable: false
        //% "Version"
        title: qsTrId("id-app-version")
        summary: inventory.version(page.packageName) || "-"
    }
    SettingsChip {
        objectName: "storageInfo"
        clickable: false
        //% "Storage"
        title: qsTrId("id-app-storage")
        summary: page.size("app")
    }
    SettingsChip {
        objectName: "dataInfo"
        clickable: false
        //% "Data"
        title: qsTrId("id-app-data")
        summary: page.size("data")
    }
    SettingsChip {
        objectName: "cacheInfo"
        clickable: false
        //% "Cache"
        title: qsTrId("id-app-cache")
        summary: page.size("cache")
    }
    SettingsChip {
        objectName: "clearDataItem"
        //% "Clear data"
        title: qsTrId("id-app-clear-data")
        onClicked: {
            //% "Delete app data?"
            confirm.ask(qsTrId("id-app-delete-data-title"),
                        //% "All this app's data will be permanently deleted. This includes all files, settings, accounts, databases, etc."
                        qsTrId("id-app-delete-data-message"),
                        function () {
                            inventory.clearData(page.names)
                            //% "Data cleared"
                            toast.show(qsTrId("id-app-data-cleared"))
                            page.compute()
                        })
        }
    }
    SettingsChip {
        objectName: "clearCacheItem"
        //% "Clear cache"
        title: qsTrId("id-app-clear-cache")
        onClicked: {
            inventory.clearCache(page.names)
            //% "Cache cleared"
            toast.show(qsTrId("id-app-cache-cleared"))
            page.compute()
        }
    }
}
