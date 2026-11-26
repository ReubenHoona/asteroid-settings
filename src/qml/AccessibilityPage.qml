/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Nemo.Configuration

// Settings > Accessibility (settings-b-10, accessibility-lock-security-20,
// FP-S4). Stock CP3A's AccessibilityFragment (xml/prefs_accessibility.xml)
// in its order: Screen reader (TalkBack, removed while TalkBack is not
// installed), Display: Magnification (the row of the magnification screen,
// On or Off under it), Text size (the font size of Display size & text),
// Color correction, Reduce animations with "Reduce movement on the screen";
// General: Audio adjustment ("Mono audio, Audio balance"), Gestures,
// Vibration watch (shown while vibration is on, vibrate_on) and Power
// button ends call (a switch, with an audio output). Text-to-speech output
// and RTT have no engine or dialer here: no rows. The keys are the
// launcher's (CR-34, src/qml/a11y and KeyRouter): a11y/magnification,
// -scale, -edge-haptic (MagnificationPage), a11y/color-correction, -mode
// (ColorCorrectionPage), a11y/vibration-watch, -type, -speed
// (VibrationWatchPage), a11y/power-button-ends-call b false. The screen
// reader's rows (a11y/screen-reader, -button-shortcut, b false) stay hidden
// while the launcher's ScreenReader is not available: behind the gate
// a11y/screen-reader-supported b false (the coordinator's rule, as CR-33),
// which the package that makes it available sets true.
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
    // gate (CR-34): true once the launcher's screen reader is available
    ConfigurationValue {
        id: screenReaderSupported
        key: "/org/asteroidos/a11y/screen-reader-supported"
        defaultValue: false
    }
    ConfigurationValue {
        id: screenReader
        key: "/org/asteroidos/a11y/screen-reader"
        defaultValue: false
    }
    ConfigurationValue {
        id: screenReaderShortcut
        key: "/org/asteroidos/a11y/screen-reader-button-shortcut"
        defaultValue: false
    }
    ConfigurationValue {
        id: magnification
        key: "/org/asteroidos/a11y/magnification"
        defaultValue: false
    }
    // Vibration & haptics (VibrationPage): Vibration watch only while it is on
    ConfigurationValue {
        id: vibration
        key: "/desktop/asteroid/vibration"
        defaultValue: true
    }
    ConfigurationValue {
        id: powerEndsCall
        key: "/org/asteroidos/a11y/power-button-ends-call"
        defaultValue: false
    }

    function isOn(v) { return v === true || v === "true" }
    readonly property bool screenReaderShown: isOn(screenReaderSupported.value)

    SettingsCategory {
        objectName: "screenReaderCategory"
        visible: page.screenReaderShown
        //% "Screen reader"
        text: qsTrId("id-screen-reader")
    }
    SettingsChip {
        objectName: "screenReaderSwitch"
        visible: page.screenReaderShown
        //% "Use screen reader"
        title: qsTrId("id-screen-reader-use")
        control: "toggle"
        checked: page.isOn(screenReader.value)
        onClicked: screenReader.value = !checked
    }
    SettingsChip {
        objectName: "screenReaderShortcutSwitch"
        visible: page.screenReaderShown
        //% "Button shortcut"
        title: qsTrId("id-screen-reader-shortcut")
        control: "toggle"
        checked: page.isOn(screenReaderShortcut.value)
        onClicked: screenReaderShortcut.value = !checked
    }
    SettingsText {
        objectName: "screenReaderShortcutCaption"
        visible: page.screenReaderShown
        //% "Triple press the side button to turn the screen reader on and off"
        text: qsTrId("id-screen-reader-shortcut-explain")
    }

    SettingsCategory {
        objectName: "displayCategory"
        //% "Display"
        text: qsTrId("id-display-page")
    }
    SettingsChip {
        objectName: "magnificationItem"
        title: qsTrId("id-magnification")
        summary: page.isOn(magnification.value) ? qsTrId("id-on") : qsTrId("id-off")
        onClicked: layerStack.push(magnificationLayer)
    }
    SettingsChip {
        objectName: "textSizeItem"
        //% "Text size"
        title: qsTrId("id-text-size")
        onClicked: layerStack.push(displaySizeLayer)
    }
    SettingsChip {
        objectName: "colorCorrectionItem"
        title: qsTrId("id-color-correction")
        onClicked: layerStack.push(colorCorrectionLayer)
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
    SettingsChip {
        objectName: "vibrationWatchItem"
        visible: page.isOn(vibration.value)
        title: qsTrId("id-vibration-watch")
        onClicked: layerStack.push(vibrationWatchLayer)
    }
    SettingsChip {
        objectName: "powerButtonEndsCallSwitch"
        visible: DeviceSpecs.hasSpeaker
        //% "Power button ends call"
        title: qsTrId("id-power-button-ends-call")
        control: "toggle"
        checked: page.isOn(powerEndsCall.value)
        onClicked: powerEndsCall.value = !checked
    }
}
