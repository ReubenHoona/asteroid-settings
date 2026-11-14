/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import org.asteroid.settings
import Nemo.Configuration
import Nemo.Mce

// System > About as stock CP3A (prefs_device_info.xml, DeviceInfoFragment:
// 90-212): one row per fact, the title and its value (SettingsDataPreference):
// the system and its version (Wear OS by Google "7.0" on stock), Model,
// Device name, Versions ("Tap to view"), Serial number, Manufactured year (the
// first digit of the serial + 2020, "Unknown" when it is not a digit),
// Connection, Battery, System licenses and Legal notices. Stock has no status
// rows, and none is added (DECISIONS rule 2): the uptime, load and memory
// rows, their one-second timer and the Wi-Fi address are gone. IMEI and MSN
// come with the LTE milestone (Q61).
SettingsPage {
    id: page
    objectName: "aboutPage"
    title: qsTrId("id-about-page")

    AboutSettings { id: about }
    BluetoothStatus { id: btStatus }
    MceBatteryLevel { id: batteryLevel }
    MceChargerType { id: chargerType }
    ConfigurationValue {
        id: eosVersion
        key: "/org/asteroidos/eos-update/version"
        defaultValue: ""
    }

    // DeviceInfoFragment: the year is 2020 + the first digit of the serial
    function manufacturedYear(serial) {
        var c = String(serial || "").charAt(0)
        return c >= "0" && c <= "9" ? String(2020 + Number(c))
                                    //% "Unknown"
                                    : qsTrId("id-about-manufactured-unknown")
    }

    SettingsChip {
        objectName: "aboutSystem"
        clickable: false
        title: about.operatingSystemName
        summary: about.softwareVersion
        visible: title !== ""
    }
    SettingsChip {
        objectName: "aboutEos"
        clickable: false
        //% "System version"
        title: qsTrId("id-about-system-version")
        summary: eosVersion.value
        visible: summary !== ""
    }
    SettingsChip {
        objectName: "aboutModel"
        clickable: false
        //% "Model"
        title: qsTrId("id-about-model")
        summary: DeviceSpecs.machineName
        visible: summary !== ""
    }
    SettingsChip {
        objectName: "aboutDeviceName"
        clickable: false
        //% "Device name"
        title: qsTrId("id-about-device-name")
        summary: DeviceSpecs.hostname
        visible: summary !== ""
    }
    SettingsChip {
        objectName: "versionsItem"
        //% "Versions"
        title: qsTrId("id-about-versions")
        //% "Tap to view"
        summary: qsTrId("id-about-tap-to-view")
        onClicked: layerStack.push(versionsLayer)
    }
    SettingsChip {
        objectName: "aboutSerial"
        clickable: false
        //% "Serial number"
        title: qsTrId("id-about-serial")
        summary: about.serial
        visible: summary !== ""
    }
    SettingsChip {
        objectName: "aboutManufactured"
        clickable: false
        //% "Manufactured year"
        title: qsTrId("id-about-manufactured")
        summary: page.manufacturedYear(about.serial)
        visible: about.serial !== ""
    }
    SettingsChip {
        objectName: "aboutConnection"
        clickable: false
        //% "Connection"
        title: qsTrId("id-about-connection")
        summary: btStatus.connected ? qsTrId("id-connected") : qsTrId("id-disconnected")
    }
    SettingsChip {
        objectName: "aboutBattery"
        clickable: false
        title: qsTrId("id-battery-page")
        //% "%1% - plugged in"
        summary: !batteryLevel.valid ? "" : chargerType.type != MceChargerType.None
                 ? qsTrId("id-battery-percent-plugged").arg(batteryLevel.percent)
                 : qsTrId("id-battery-percent").arg(batteryLevel.percent)
    }
    SettingsChip {
        objectName: "licensesItem"
        //% "System licenses"
        title: qsTrId("id-about-licenses")
        onClicked: layerStack.push(licensesLayer)
    }
    SettingsChip {
        objectName: "legalNoticesItem"
        //% "Legal notices"
        title: qsTrId("id-about-legal")
        onClicked: confirm.tell(qsTrId("id-about-legal"),
                                //% "AsteroidOS is free software. Its licences, and the source of this system, are at asteroidos.org."
                                qsTrId("id-about-legal-text"))
    }
}
