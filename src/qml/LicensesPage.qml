/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// System > About > System licenses as stock CP3A's
// (SystemLicenseLibrariesFragment: one plain row per library, sorted by
// name, no second line, each opening its licence text,
// SystemLicenseDetailsFragment): one row per part of this system, sorted,
// the rest last, each opening its text (LicenseTextPage). This watch's
// system is free software, so the text names the part's licences; the full
// texts and the source are with the AsteroidOS project and the
// eos-mainline repositories (the image ships no licence files to show).
SettingsPage {
    id: page
    objectName: "licensesPage"
    //% "System licenses"
    title: qsTrId("id-about-licenses")

    Component { id: textLayer; LicenseTextPage { } }
    function show(heading, body) {
        layerStack.push(textLayer, { "heading": heading, "body": body })
    }

    SettingsChip {
        objectName: "licensesAsteroid"
        title: "AsteroidOS"
        //% "The apps and the system UI: GNU General Public License version 3, GNU Lesser General Public License version 2.1 and BSD 3-clause licences."
        onClicked: page.show(title, qsTrId("id-licenses-asteroid"))
    }
    SettingsChip {
        objectName: "licensesLinux"
        //% "Linux kernel"
        title: qsTrId("id-licenses-kernel-title")
        //% "GNU General Public License, version 2."
        onClicked: page.show(title, qsTrId("id-licenses-kernel"))
    }
    SettingsChip {
        objectName: "licensesQt"
        title: "Qt"
        //% "GNU Lesser General Public License version 3."
        onClicked: page.show(title, qsTrId("id-licenses-qt"))
    }
    SettingsChip {
        objectName: "licensesOthers"
        //% "Other parts"
        title: qsTrId("id-licenses-others-title")
        //% "Other parts keep their own licences. The full texts and the source are at asteroidos.org."
        onClicked: page.show(title, qsTrId("id-licenses-others"))
    }
}
