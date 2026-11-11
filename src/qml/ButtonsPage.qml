/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings
import Nemo.Configuration

/*
 * Settings > Buttons. Stock CP3A builds the page from
 * PixelWatchNavRouteCollector$init$16.java: RotateToWakePreference,
 * ReduceFalseCrownInputPreference (not shown on the Pixel Watch 2), then the
 * category "Chord press" with ScreenshotGesturePreference. The user's two
 * button choices (PLAN.md section 4, choice-settings-05) go in between, so
 * the rows are:
 *  1 Rotate crown to wake: a switch on mce's
 *    /system/osso/dsm/display/rotary_wake_enabled (the wake itself is
 *    W2-mce-wake's). Stock shows the row only where the crown can wake
 *    (RotateToWakePreference isSupported); here it shows once mce knows the
 *    key. A mode holds it greyed, showing off, with "Bedtime mode is on" or
 *    "Theater mode is on", Bedtime first (RotateToWakePreference.java:84-97).
 *    mce 1 or true shows on; anything else (stock: unset, -1) shows off.
 *  2 Faster crown scrolling (choice 2): a switch with a caption, in the slot
 *    of stock's "Reduce unintended inputs", which is also a switch with a
 *    caption (ReduceFalseCrownInputPreference.java:165-168). On, the user's
 *    value: 7.5 px per crown count and the 1-3x gain. Off, stock's: 1.50 px
 *    per count with stock's slop and fling (qml-asteroid RotaryInput reads
 *    the key). No mode holds it.
 *  3 Side button (choice 5): a list row showing the choice. It opens the
 *    stock selection dialog with a message line, as Screen timeout does.
 *    'assistant', the user's value: a press only wakes, a hold opens the
 *    assistant. 'recents', stock's: a press opens Recents, a second press
 *    within 300 ms the previous app, a hold the assistant. The launcher
 *    reads the key and owns mce's hold delay (300 ms in both, DECISIONS
 *    Q5b). No mode holds it.
 *  4 Chord press > Screenshot: a switch with stock's caption, on
 *    /org/asteroidos/settings/screenshot-enabled (stock Global
 *    screenshot_enabled, default on: ScreenshotGesturePreference.java:
 *    117-118, 138-140). mce sends "screenshot" for the chord; the launcher
 *    takes it only while this is on.
 * Code defaults = the image defaults (00-eos-defaults): crown-fast true,
 * side-button 'assistant', screenshot-enabled true.
 */
SettingsPage {
    id: page
    objectName: "buttonsPage"
    title: qsTrId("id-buttons-page")

    MceConfigValue {
        id: rotaryWake
        key: "/system/osso/dsm/display/rotary_wake_enabled"
    }
    ConfigurationValue {
        id: crownFast
        key: "/org/asteroidos/ux/crown-fast"
        defaultValue: true
    }
    ConfigurationValue {
        id: sideButton
        key: "/org/asteroidos/ux/side-button"
        defaultValue: "assistant"
    }
    ConfigurationValue {
        id: screenshot
        key: "/org/asteroidos/settings/screenshot-enabled"
        defaultValue: true
    }

    function on(v) { return v === true || v === "true" }

    readonly property string rotaryHolder: modeState.bedtime ? "bedtime" : modeState.theater ? "theater" : ""
    readonly property bool rotaryOn: Number(rotaryWake.value) === 1

    readonly property var sideValues: ["assistant", "recents"]
    readonly property var sideLabels: [
        //% "Press & hold for Assistant"
        qsTrId("id-side-button-assistant"),
        //% "Press for recent apps"
        qsTrId("id-side-button-recents")
    ]
    readonly property int sideIndex: Math.max(0, sideValues.indexOf(String(sideButton.value)))
    function chooseSideButton() {
        app.choose(qsTrId("id-side-button"), sideLabels, sideIndex,
                   function (i) { sideButton.value = page.sideValues[i] }, [],
                   //% "What the side button does"
                   qsTrId("id-side-button-message"))
    }

    SettingsChip {
        objectName: "rotaryWakeSwitch"
        visible: rotaryWake.valid
        //% "Rotate crown to wake"
        title: qsTrId("id-rotary-wake")
        control: "toggle"
        active: page.rotaryHolder === ""
        summary: modeState.summary(page.rotaryHolder)
        checked: active && page.rotaryOn
        onClicked: rotaryWake.value = !page.rotaryOn
    }
    SettingsChip {
        objectName: "crownFastSwitch"
        //% "Faster crown scrolling"
        title: qsTrId("id-crown-fast")
        control: "toggle"
        checked: page.on(crownFast.value)
        onClicked: crownFast.value = !page.on(crownFast.value)
    }
    SettingsText {
        objectName: "crownFastCaption"
        //% "Lists move farther with each turn of the crown"
        text: qsTrId("id-crown-fast-explain")
    }
    SettingsChip {
        objectName: "sideButtonItem"
        //% "Side button"
        title: qsTrId("id-side-button")
        summary: page.sideLabels[page.sideIndex]
        onClicked: page.chooseSideButton()
    }
    SettingsCategory {
        objectName: "chordCategory"
        //% "Chord press"
        text: qsTrId("id-chord-press")
    }
    SettingsChip {
        objectName: "screenshotSwitch"
        //% "Screenshot"
        title: qsTrId("id-screenshot")
        control: "toggle"
        checked: page.on(screenshot.value)
        onClicked: screenshot.value = !page.on(screenshot.value)
    }
    SettingsText {
        objectName: "screenshotCaption"
        //% "Take a screenshot by pressing the crown and side button at the same time"
        text: qsTrId("id-screenshot-explain")
    }
}
