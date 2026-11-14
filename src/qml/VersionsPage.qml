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
// System UI (the launcher's version), then the kernel and Qt. Seven taps on
// Build number turn on Developer options, as on Wear OS; the toast "You are
// now # steps away from being a developer." shows only with 2 or 1 taps left,
// and "No need, you are already a developer." only after more than 3 taps.
SettingsPage {
    id: page
    objectName: "versionsPage"
    //% "Versions"
    title: qsTrId("id-about-versions")

    PackageInfo { id: packages }
    ConfigurationValue {
        id: developerOptions
        key: "/org/asteroidos/settings/developer-options"
        defaultValue: false
    }
    property int taps: 0

    SettingsChip {
        objectName: "buildItem"
        //% "Build number"
        title: qsTrId("id-about-build")
        summary: DeviceSpecs.buildID
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
        //% "System UI"
        title: qsTrId("id-about-system-ui")
        summary: packages.version("asteroid-launcher")
        visible: summary !== ""
    }
    SettingsChip {
        objectName: "kernelItem"
        clickable: false
        title: qsTr("Kernel version")
        summary: kernelVersion
    }
    SettingsChip {
        objectName: "qtItem"
        clickable: false
        title: qsTr("Qt version")
        summary: qtVersion
    }
}
