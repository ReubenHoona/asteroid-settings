/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import Nemo.DBus

// Settings > Developer options (stock prefs_developer_options.xml, there once
// Build number was tapped seven times): Restart to bootloader (fastboot),
// which Settings > Power had; and the switch that hides this entry again.
SettingsPage {
    objectName: "developerPage"
    title: qsTrId("id-developer-page")

    ConfigurationValue {
        id: developerOptions
        key: "/org/asteroidos/settings/developer-options"
        defaultValue: false
    }
    DBusInterface {
        id: login1
        bus: DBus.SystemBus
        service: "org.freedesktop.login1"
        path: "/org/freedesktop/login1"
        iface: "org.freedesktop.login1.Manager"
    }

    SettingsChip {
        objectName: "developerSwitch"
        title: qsTrId("id-developer-page")
        control: "toggle"
        checked: developerOptions.value
        onClicked: {
            developerOptions.value = false
            app.backToMainMenu()
        }
    }
    SettingsChip {
        objectName: "bootloaderItem"
        //% "Restart to bootloader"
        title: qsTrId("id-restart-bootloader")
        iconName: "ios-bootloader-outline"
        onClicked: confirm.ask(qsTrId("id-restart-bootloader"), qsTrId("id-are-you-sure"),
                               function () {
                                   login1.call("SetRebootParameter", ["bootloader"])
                                   login1.call("Reboot", [false])
                               })
    }
}
