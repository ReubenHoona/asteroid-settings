/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > General (stock: the system UI's SysUiSettingsActivity): Show
// unread notification dot (the launcher's dot on the watch face), App view
// (the launcher's app list style), then this watch's own: the quick
// settings panel and the temperature unit.
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
        id: appLauncher
        key: "/desktop/asteroid/applauncher"
        defaultValue: "file:///usr/share/asteroid-launcher/applauncher/000-default-horizontal.qml"
    }
    ConfigurationValue {
        id: useFahrenheit
        key: "/org/asteroidos/settings/use-fahrenheit"
        defaultValue: false
    }

    // the name of a launcher style from its file: 006-wear-list.qml is the
    // Wear OS list ("List view" as stock), the others by their names
    function launcherName(url) {
        var file = String(url).split("/").pop().replace(/\.qml$/, "")
        if (file === "006-wear-list")
            //% "List view"
            return qsTrId("id-app-view-list")
        var name = file.replace(/^[0-9]+-/, "").replace(/-/g, " ")
        return name.charAt(0).toUpperCase() + name.slice(1)
    }

    SettingsChip {
        objectName: "unreadDotSwitch"
        //% "Show unread notification dot"
        title: qsTrId("id-unread-dot")
        control: "toggle"
        checked: unreadDot.value
        onClicked: unreadDot.value = !unreadDot.value
    }
    SettingsChip {
        objectName: "appViewItem"
        //% "App view"
        title: qsTrId("id-app-view")
        summary: page.launcherName(appLauncher.value)
        onClicked: layerStack.push(launcherLayer)
    }
    SettingsChip {
        objectName: "quickPanelItem"
        //% "Quick settings"
        title: qsTrId("id-quick-settings")
        onClicked: layerStack.push(quickPanelLayer)
    }
    SettingsChip {
        objectName: "temperatureItem"
        //% "Temperature"
        title: qsTrId("id-temperature")
        summary: useFahrenheit.value ? qsTrId("id-fahrenheit-unit") : qsTrId("id-celsius-unit")
        onClicked: app.choose(qsTrId("id-temperature"),
                              //% "Celsius (°C)"
                              [qsTrId("id-celsius-unit"),
                               //% "Fahrenheit (°F)"
                               qsTrId("id-fahrenheit-unit")],
                              useFahrenheit.value ? 1 : 0,
                              function (i) { useFahrenheit.value = i === 1 })
    }
}
