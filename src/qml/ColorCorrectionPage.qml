/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Accessibility > Color correction as stock CP3A's
// (ColorCorrectionFragment, xml/prefs_color_correction.xml): the switch Use
// color correction, then four radio rows, always enabled: Red-green (Green
// weak, deuteranomaly), Red-green (Red weak, protanomaly), Blue-yellow
// (Tritanomaly) and Grayscale; with no mode stored Red-green deuteranomaly
// is the checked one (stock's default, 12). The keys are the launcher's
// (CR-34, a11y/ColorCorrection.qml): a11y/color-correction b false,
// a11y/color-correction-mode s deuteranomaly, protanomaly, tritanomaly or
// grayscale.
SettingsPage {
    id: page
    objectName: "colorCorrectionPage"
    //% "Color correction"
    title: qsTrId("id-color-correction")

    ConfigurationValue {
        id: correction
        key: "/org/asteroidos/a11y/color-correction"
        defaultValue: false
    }
    ConfigurationValue {
        id: mode
        key: "/org/asteroidos/a11y/color-correction-mode"
        defaultValue: "deuteranomaly"
    }

    readonly property var modes: [
        //% "Red-green"
        { "id": "deuteranomaly", "title": qsTrId("id-color-correction-red-green"),
          //% "Green weak, deuteranomaly"
          "summary": qsTrId("id-color-correction-deuteranomaly") },
        { "id": "protanomaly", "title": qsTrId("id-color-correction-red-green"),
          //% "Red weak, protanomaly"
          "summary": qsTrId("id-color-correction-protanomaly") },
        //% "Blue-yellow"
        { "id": "tritanomaly", "title": qsTrId("id-color-correction-blue-yellow"),
          //% "Tritanomaly"
          "summary": qsTrId("id-color-correction-tritanomaly") },
        //% "Grayscale"
        { "id": "grayscale", "title": qsTrId("id-color-correction-grayscale"), "summary": "" }
    ]
    // the launcher's validMode: anything else is deuteranomaly
    readonly property string current: {
        var m = String(mode.value)
        for (var i = 0; i < modes.length; i++)
            if (modes[i].id === m)
                return m
        return "deuteranomaly"
    }

    SettingsChip {
        objectName: "colorCorrectionSwitch"
        //% "Use color correction"
        title: qsTrId("id-color-correction-use")
        control: "toggle"
        checked: correction.value === true || correction.value === "true"
        onClicked: correction.value = !checked
    }
    Repeater {
        model: page.modes
        delegate: SettingsChip {
            required property var modelData
            objectName: "colorCorrection_" + modelData.id
            title: modelData.title
            summary: modelData.summary
            control: "radio"
            checked: page.current === modelData.id
            onClicked: mode.value = modelData.id
        }
    }
}
