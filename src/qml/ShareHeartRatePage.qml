/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Nemo.Configuration

// Settings > Connectivity > Share heart rate (stock: the row opens the Share
// heart rate app, com.google.android.wearable.pixel.aspen, which sends the
// heart rate to gym equipment over Bluetooth). Here the app is this page:
// the switch is the dconf key asteroid-btsyncd's Heart Rate Service reads
// (advertising and the sensor run only while it is on), the note is the app's
// own ("Using this feature will impact battery life.") and its about text.
// Stock's aspen strings: battery_impact_information, about_description,
// bluetooth_required. Off by default.
SettingsPage {
    id: page
    objectName: "shareHeartRatePage"
    //% "Share heart rate"
    title: qsTrId("id-share-heart-rate")

    BluetoothStatus { id: btStatus }
    ConfigurationValue {
        id: share
        key: "/org/asteroidos/btsyncd/share-heart-rate"
        defaultValue: false
    }
    readonly property bool on: share.value === true || share.value === "true"

    SettingsChip {
        objectName: "shareHeartRateSwitch"
        title: qsTrId("id-share-heart-rate")
        //% "Requires Bluetooth to be enabled."
        summary: btStatus.powered ? "" : qsTrId("id-share-hr-needs-bluetooth")
        control: "toggle"
        checked: page.on
        // it can always be switched off; on needs Bluetooth
        active: btStatus.powered || page.on
        onClicked: share.value = !page.on
    }
    SettingsText {
        objectName: "shareHeartRateBattery"
        //% "Using this feature will impact battery life."
        text: qsTrId("id-share-hr-battery")
    }
    SettingsText {
        objectName: "shareHeartRateAbout"
        //% "Connect to compatible exercise machines and apps to see real-time heart rate on display."
        text: qsTrId("id-share-hr-about")
    }
}
