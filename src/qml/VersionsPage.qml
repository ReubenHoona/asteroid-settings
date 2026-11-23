/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import org.asteroid.settings
import Nemo.Configuration

// About > Versions (stock DeviceVersionFragment:38,120-160): Build number,
// System UI (the launcher's version), then the kernel and Qt, each a plain
// SettingsDataPreference row (SettingsChip dataRow, :126-129). The Build
// number is the eos image version eos-update installed (stock: the system
// image's build), the os-release build id while there is none. Seven taps on
// Build number turn on Developer options, as on Wear OS; the toast "You are
// now # steps away from being a developer." shows only with 2 or 1 taps left,
// and "No need, you are already a developer." only after more than 3 taps.
SettingsPage {
    id: page
    objectName: "versionsPage"
    //% "Versions"
    title: qsTrId("id-about-versions")
    // DeviceVersionFragment is a legacy preference screen: its title (D60-40)
    legacyHeader: true

    PackageInfo { id: packages }
    ConfigurationValue {
        id: developerOptions
        key: "/org/asteroidos/settings/developer-options"
        defaultValue: false
    }
    // the image eos-update installed ("0" or "" before its first install)
    ConfigurationValue {
        id: eosVersion
        key: "/org/asteroidos/eos-update/version"
        defaultValue: ""
    }
    readonly property string imageVersion: {
        var v = String(eosVersion.value === undefined || eosVersion.value === null ? "" : eosVersion.value)
        return v === "0" ? "" : v
    }
    property int taps: 0

    SettingsChip {
        objectName: "buildItem"
        dataRow: true
        //% "Build number"
        title: qsTrId("id-about-build")
        summary: page.imageVersion !== "" ? page.imageVersion : DeviceSpecs.buildID
        onClicked: {
            page.taps++
            if (developerOptions.value) {
                if (page.taps > 3)
                    //% "No need, you are already a developer."
                    toast.show(qsTrId("id-dev-already"))
                return
            }
            var left = 7 - page.taps
            if (left <= 0) {
                developerOptions.value = true
                //% "You are now a developer!"
                toast.show(qsTrId("id-dev-on"))
            } else if (left <= 2) {
                //% "You are now %n step(s) away from being a developer."
                toast.show(qsTrId("id-dev-steps", left))
            }
        }
    }
    SettingsChip {
        objectName: "systemUiItem"
        clickable: false
        dataRow: true
        //% "System UI"
        title: qsTrId("id-about-system-ui")
        summary: packages.version("asteroid-launcher")
        visible: summary !== ""
    }
    SettingsChip {
        objectName: "kernelItem"
        clickable: false
        dataRow: true
        title: qsTr("Kernel version")
        summary: kernelVersion
    }
    SettingsChip {
        objectName: "qtItem"
        clickable: false
        dataRow: true
        title: qsTr("Qt version")
        summary: qtVersion
    }
}
