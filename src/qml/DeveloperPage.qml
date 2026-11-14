/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import Nemo.DBus
import org.asteroid.settings

// Settings > Developer options (stock prefs_developer_options.xml:7-14, there
// once Build number was tapped seven times): the switch Use developer
// options (it hides this entry again), Stay awake when charging (the screen
// stays on while a charger is connected: mce's inhibit_blank_mode 1,
// STAY_ON_WITH_CHARGER; off by default; nothing runs unless a charger is
// connected), and Restart to bootloader (fastboot), which Settings > Power had.
SettingsPage {
    objectName: "developerPage"
    title: qsTrId("id-developer-page")

    ConfigurationValue {
        id: developerOptions
        key: "/org/asteroidos/settings/developer-options"
        defaultValue: false
    }
    // mce: 0 INHIBIT_OFF, 1 INHIBIT_STAY_ON_WITH_CHARGER
    MceConfigValue {
        id: stayAwake
        key: "/system/osso/dsm/display/inhibit_blank_mode"
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
        //% "Use developer options"
        title: qsTrId("id-developer-use")
        control: "toggle"
        checked: developerOptions.value
        onClicked: {
            developerOptions.value = false
            app.backToMainMenu()
        }
    }
    SettingsChip {
        objectName: "stayAwakeSwitch"
        //% "Stay awake when charging"
        title: qsTrId("id-stay-awake")
        control: "toggle"
        checked: Number(stayAwake.value) === 1
        onClicked: stayAwake.value = Number(stayAwake.value) === 1 ? 0 : 1
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
