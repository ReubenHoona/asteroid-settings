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

// System > About (stock prefs_device_info.xml): one row per fact, the title
// and its value (SettingsDataPreference): the system and its version,
// Model, Device name, Versions ("Tap to view": build, kernel, Qt), Serial
// number, Connection, Battery, then this watch's own: the Wi-Fi address,
// and its uptime, load and memory under "Status".
SettingsPage {
    id: page
    objectName: "aboutPage"
    title: qsTrId("id-about-page")

    AboutSettings { id: about }
    SysInfo { id: info }
    BluetoothStatus { id: btStatus }
    MceBatteryLevel { id: batteryLevel }
    MceChargerType { id: chargerType }
    ConfigurationValue {
        id: eosVersion
        key: "/org/asteroidos/eos-update/version"
        defaultValue: ""
    }

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: true
        onTriggered: info.refresh()
    }
    readonly property int secondsPerDay: 60 * 60 * 24
    function uptimeText() {
        var now = info.uptime
        var days = Math.floor(now / secondsPerDay)
        var date = new Date(1000 * (now - days * secondsPerDay))
        return qsTr("%L1 days %L2").arg(days).arg(date.toISOString().substring(11, 19))
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
        clickable: false
        //% "Model"
        title: qsTrId("id-about-model")
        summary: DeviceSpecs.machineName
        visible: summary !== ""
    }
    SettingsChip {
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
        clickable: false
        title: qsTr("Serial number")
        summary: about.serial
        visible: summary !== ""
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
        clickable: false
        //% "Wi-Fi MAC address"
        title: qsTrId("id-about-wifi-mac")
        summary: about.wlanMacAddress
        visible: summary !== ""
    }
    //% "Status"
    SettingsCategory { text: qsTrId("id-about-status") }
    SettingsChip {
        clickable: false
        title: qsTr("Uptime")
        summary: page.uptimeText()
    }
    SettingsChip {
        clickable: false
        title: qsTr("1,5,15 Minute loads")
        summary: qsTr("%L1, %L2, %L3").arg(info.loads[0].toFixed(2)).arg(info.loads[1].toFixed(2)).arg(info.loads[2].toFixed(2))
    }
    SettingsChip {
        clickable: false
        title: qsTr("Free memory")
        summary: qsTr("%L1 MB (%L2 %)").arg(Math.round(info.freeRam * info.memUnit / 1e6)).arg((100.0 * info.freeRam / info.totalRam).toFixed(0))
    }
    SettingsChip {
        clickable: false
        title: qsTr("Total memory")
        summary: qsTr("%L1 MB").arg(Math.round(info.totalRam * info.memUnit / 1e6))
    }
    SettingsChip {
        clickable: false
        title: qsTr("Threads")
        summary: qsTr("%L1").arg(info.threads)
    }
    SettingsChip {
        clickable: false
        title: qsTr("Display size")
        summary: qsTr("%L1W x %L2H").arg(Dims.w(100)).arg(Dims.h(100))
    }
}
