/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Nemo.Configuration

// About > Versions (stock DeviceVersionFragment): Build number, then the
// kernel and Qt. Seven taps on Build number turn on Developer options, as
// on Wear OS, counting down from the fourth.
SettingsPage {
    id: page
    objectName: "versionsPage"
    //% "Versions"
    title: qsTrId("id-about-versions")

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
            if (developerOptions.value) {
                //% "No need, you are already a developer."
                toast.show(qsTrId("id-dev-already"))
                return
            }
            page.taps++
            var left = 7 - page.taps
            if (left <= 0) {
                developerOptions.value = true
                //% "You are now a developer!"
                toast.show(qsTrId("id-dev-on"))
            } else if (left <= 3) {
                toast.show(left === 1
                           //% "You are now 1 step away from being a developer."
                           ? qsTrId("id-dev-one-step")
                           //% "You are now %1 steps away from being a developer."
                           : qsTrId("id-dev-steps").arg(left))
            }
        }
    }
    SettingsChip {
        clickable: false
        title: qsTr("Kernel version")
        summary: kernelVersion
    }
    SettingsChip {
        clickable: false
        title: qsTr("Qt version")
        summary: qtVersion
    }
}
