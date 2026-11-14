/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Nemo.Configuration

// Settings > Accessibility (settings-b-10, accessibility-lock-security-20).
// Stock CP3A's legacy AccessibilityFragment has the categories Display and
// General. Rows are built where this watch has the feature behind them:
// Display: Text size (the font size of Display size & text) and Reduce
// animations with "Reduce movement on the screen"; General: Audio adjustment
// ("Mono audio, Audio balance") and Gestures. Screen reader, Magnification,
// Color correction, Text-to-speech output, Power button ends call and
// Vibration watch come with the launcher's accessibility work (not built
// yet); a category with no row would be hidden.
SettingsPage {
    id: page
    objectName: "accessibilityPage"
    title: qsTrId("id-accessibility-page")

    // /org/asteroidos/a11y/reduce-motion is what the springs of qml-asteroid
    // (Motion) read: with it on they land at once
    ConfigurationValue {
        id: reduceMotion
        key: "/org/asteroidos/a11y/reduce-motion"
        defaultValue: false
    }

    // gate (CR-33): the audio helper that reads mono-audio and audio-balance
    // sets this true when it is installed; until then there is no row
    ConfigurationValue {
        id: audioAdjustSupported
        key: "/org/asteroidos/a11y/audio-adjust-supported"
        defaultValue: false
    }

    SettingsCategory {
        objectName: "displayCategory"
        //% "Display"
        text: qsTrId("id-display-page")
    }
    SettingsChip {
        objectName: "textSizeItem"
        //% "Text size"
        title: qsTrId("id-text-size")
        onClicked: layerStack.push(displaySizeLayer)
    }
    SettingsChip {
        objectName: "reduceAnimationsSwitch"
        //% "Reduce animations"
        title: qsTrId("id-reduce-animations")
        control: "toggle"
        checked: reduceMotion.value === true || reduceMotion.value === "true"
        onClicked: reduceMotion.value = !checked
    }
    SettingsText {
        objectName: "reduceAnimationsCaption"
        //% "Reduce movement on the screen"
        text: qsTrId("id-reduce-animations-explain")
    }
    SettingsCategory {
        objectName: "generalCategory"
        //% "General"
        text: qsTrId("id-general-page")
    }
    SettingsChip {
        objectName: "audioAdjustmentItem"
        visible: DeviceSpecs.hasSpeaker && (audioAdjustSupported.value === true || audioAdjustSupported.value === "true")
        //% "Audio adjustment"
        title: qsTrId("id-audio-adjustment")
        //% "Mono audio, Audio balance"
        summary: qsTrId("id-audio-adjustment-summary")
        onClicked: layerStack.push(audioAdjustLayer)
    }
    SettingsChip {
        objectName: "gesturesItem"
        title: qsTrId("id-gestures-page")
        onClicked: layerStack.push(gesturesLayer)
    }
}
