/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import org.asteroid.settings
import Nemo.DBus
import Nemo.Mce

// Settings > System (stock prefs_system.xml, in its order): System updates,
// Power off and Restart (each asks "Are you sure?" as stock), Date & time,
// Input methods, Language (no summary: the list names the current one), About,
// Disconnect & reset (setup-wizard-07; FactoryResetPreference:29-36,
// FactoryResetDialogFragment:67-290): the question, then the full-screen
// "Resetting..." and the wipe by the root helper (eos-factory-reset).
SettingsPage {
    id: page
    objectName: "systemPage"
    title: qsTrId("id-system-page")

    BluetoothStatus { id: btStatus }
    MceBatteryLevel { id: batteryLevel }
    MceChargerType { id: chargerType }

    DBusInterface {
        id: login1
        bus: DBus.SystemBus
        service: "org.freedesktop.login1"
        path: "/org/freedesktop/login1"
        iface: "org.freedesktop.login1.Manager"
    }

    // a reboot at low battery has left this watch off until USB: no reset
    // below 30 % unless it is on the charger
    readonly property int resetMinimumLevel: 30
    readonly property bool resetAllowed: chargerType.type != MceChargerType.None
                                          || !batteryLevel.valid || batteryLevel.percent >= resetMinimumLevel

    function askReset() {
        if (!resetAllowed) {
            confirm.tell(qsTrId("id-factory-reset-title"),
                         //% "Charge your watch to at least %1% to reset it."
                         qsTrId("id-factory-reset-battery").arg(resetMinimumLevel))
            return
        }
        //% "This will reset watch to factory settings and delete all user data."
        var message = qsTrId("id-factory-reset-message")
        if (btStatus.connected)
            //% "It's best to disconnect the watch using the %1 app."
            message += "\n\n" + qsTrId("id-factory-reset-recommend").arg("Gadgetbridge")
        //% "Disconnect & reset?"
        confirm.ask(qsTrId("id-factory-reset-title"), message, function () { resetScreen.start() })
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
        objectName: "inputMethodsItem"
        //% "Input methods"
        title: qsTrId("id-input-methods-page")
        onClicked: layerStack.push(inputMethodsLayer)
    }
    SettingsChip {
        objectName: "languageItem"
        title: qsTrId("id-language-page")
        onClicked: layerStack.push(languageLayer)
    }
    SettingsChip {
        objectName: "aboutItem"
        title: qsTrId("id-about-page")
        onClicked: layerStack.push(aboutLayer)
    }
    SettingsChip {
        objectName: "factoryResetItem"
        //% "Disconnect & reset"
        title: qsTrId("id-factory-reset")
        onClicked: page.askReset()
    }
}
