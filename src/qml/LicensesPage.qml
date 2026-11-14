/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// System > About > System licenses (stock pref_watchSystemLicenses opens the
// licence texts of the system): this watch's system is free software, so the
// page names the licences by part; the texts and the source are with the
// AsteroidOS project and the eos-mainline repositories.
SettingsPage {
    id: page
    objectName: "licensesPage"
    //% "System licenses"
    title: qsTrId("id-about-licenses")

    SettingsText {
        objectName: "licensesLinux"
        //% "Linux kernel: GNU General Public License, version 2."
        text: qsTrId("id-licenses-kernel")
    }
    SettingsText {
        objectName: "licensesAsteroid"
        //% "AsteroidOS apps and system UI: GNU General Public License version 3, GNU Lesser General Public License version 2.1 and BSD 3-clause licences."
        text: qsTrId("id-licenses-asteroid")
    }
    SettingsText {
        objectName: "licensesQt"
        //% "Qt: GNU Lesser General Public License version 3."
        text: qsTrId("id-licenses-qt")
    }
    SettingsText {
        objectName: "licensesOthers"
        //% "Other parts keep their own licences. The full texts and the source are at asteroidos.org."
        text: qsTrId("id-licenses-others")
    }
}
