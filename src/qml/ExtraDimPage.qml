/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// Display > Extra dim: not on stock Wear OS (the phone's Accessibility >
// Extra dim, which Android lets no app read, so it cannot follow the
// phone's). The screen under the lowest brightness, for dark rooms: the
// launcher's modes engine holds mce's brightness at 7, 5 or 2 % (DBV 17,
// 12 or 5 of 255; the slider's lowest is 10 %) with adaptive brightness
// off, and the always-on screen at its "low" step or under. As Android's,
// its Intensity, and it ends when the watch restarts.
SettingsPage {
    id: page
    objectName: "extraDimPage"
    title: qsTrId("id-extra-dim")

    readonly property var labels: [qsTrId("id-low"), qsTrId("id-medium"), qsTrId("id-high")]
    // Android's Extra dim strength (its range is 25 to 90, 50 by default)
    readonly property var intensities: [25, 50, 90]
    readonly property int intensityIndex: {
        var v = Number(modeState.extraDimIntensity)
        var best = 0
        for (var i = 1; i < intensities.length; i++)
            if (Math.abs(intensities[i] - v) < Math.abs(intensities[best] - v))
                best = i
        return best
    }

    SettingsChip {
        objectName: "extraDimSwitch"
        //% "Use Extra dim"
        title: qsTrId("id-extra-dim-use")
        control: "toggle"
        checked: modeState.extraDim
        onClicked: modeState.extraDim = !modeState.extraDim
    }
    SettingsChip {
        objectName: "extraDimIntensity"
        //% "Intensity"
        title: qsTrId("id-extra-dim-intensity")
        summary: page.labels[page.intensityIndex]
        onClicked: app.choose(qsTrId("id-extra-dim-intensity"), page.labels, page.intensityIndex,
                              function (i) { modeState.extraDimIntensity = page.intensities[i] })
    }
    SettingsText {
        //% "Dims the screen below the lowest brightness, for dark rooms. Extra dim turns off when the watch restarts."
        text: qsTrId("id-extra-dim-explain")
    }
}
