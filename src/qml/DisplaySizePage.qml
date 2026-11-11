/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * Settings > Display > Display size & text (stock display_text_size_title).
 * A stub from W1-settings-structure: W2-settings-display gives it its rows
 * (font size, bold text, display size: design-tokens-15, settings-a-19) and
 * the Display row that opens it.
 */
SettingsPage {
    objectName: "displaySizePage"
    //% "Display size & text"
    title: qsTrId("id-display-size-page")
}
