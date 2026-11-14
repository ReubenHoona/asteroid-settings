/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings

// Assistant > About (assistant-voice-22; stock pref_about_title opens the
// assistant's own about screen): the assistant's version from the package
// list and what it does.
SettingsPage {
    objectName: "assistantAboutPage"
    title: qsTrId("id-about-page")

    PackageInfo { id: packages }

    SettingsChip {
        objectName: "assistantVersion"
        clickable: false
        title: qsTrId("id-app-version")
        summary: packages.version("asteroid-assistant") || "-"
    }
    SettingsText {
        objectName: "assistantAboutText"
        //% "Assistant answers what you say to your watch. Speech is recognised on the watch, or on your phone when you choose it."
        text: qsTrId("id-assistant-about")
    }
}
