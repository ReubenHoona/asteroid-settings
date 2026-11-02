/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings
import Nemo.DBus

// Settings > System (stock prefs_system.xml): System updates, Power off and
// Restart (each asks "Are you sure?" as stock), Date & time, Language (the
// current one under it), About.
SettingsPage {
    id: page
    objectName: "systemPage"
    title: qsTrId("id-system-page")

    LanguageModel { id: languages }

    DBusInterface {
        id: login1
        bus: DBus.SystemBus
        service: "org.freedesktop.login1"
        path: "/org/freedesktop/login1"
        iface: "org.freedesktop.login1.Manager"
    }

    SettingsChip {
        objectName: "updatesItem"
        //% "System updates"
        title: qsTrId("id-system-updates")
        onClicked: layerStack.push(updatesLayer)
    }
    SettingsChip {
        objectName: "powerOffItem"
        //% "Power off"
        title: qsTrId("id-power-off")
        onClicked: confirm.ask(qsTrId("id-power-off"),
                               //% "Are you sure?"
                               qsTrId("id-are-you-sure"),
                               function () { login1.call("PowerOff", [false]) })
    }
    SettingsChip {
        objectName: "restartItem"
        //% "Restart"
        title: qsTrId("id-restart")
        onClicked: confirm.ask(qsTrId("id-restart"), qsTrId("id-are-you-sure"),
                               function () {
                                   login1.call("SetRebootParameter", [""])
                                   login1.call("Reboot", [false])
                               })
    }
    SettingsChip {
        objectName: "dateTimeItem"
        //% "Date & time"
        title: qsTrId("id-date-time-page")
        onClicked: layerStack.push(dateTimeLayer)
    }
    SettingsChip {
        objectName: "languageItem"
        title: qsTrId("id-language-page")
        summary: languages.currentIndex >= 0 ? languages.languageName(languages.currentIndex) : ""
        onClicked: layerStack.push(languageLayer)
    }
    SettingsChip {
        objectName: "aboutItem"
        title: qsTrId("id-about-page")
        onClicked: layerStack.push(aboutLayer)
    }
}
