/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

/*
 * Settings > Display > Display size & text (stock prefs_display_and_text_size.
 * xml, DisplaySizeAndFontSizeFragment): category Display size with a segmented
 * slider and "Make everything bigger or smaller"; category Font size with a
 * 6 step slider (Small 0.94, Default 1.0, Medium 1.06, Large 1.12, Larger
 * 1.18, Largest 1.24: text_size_entries) and "Make text bigger or smaller";
 * the switch Bold text; Reset settings. Each slider runs from 0 to its step
 * count with the value on the step (1 to n). A change shows the toast
 * "Applying..." and is applied 500 ms later
 * (PENDING_DISPLAY_SETTING_CHANGE_DELAY), a later change inside that time
 * replaces the first. The sizes are the system-wide keys that
 * org.asteroid.controls Theme reads in every app: display-density (a dpi,
 * the steps of Theme.densitySteps; 0 is the automatic default, 320 dpi on
 * this watch), font-scale and bold-text. The one-shot timers start only
 * from a tap.
 */
SettingsPage {
    id: page
    objectName: "displaySizePage"
    //% "Display size & text"
    title: qsTrId("id-display-size-page")

    // stock PENDING_DISPLAY_SETTING_CHANGE_DELAY
    readonly property int applyDelay: 500

    ConfigurationValue { id: densityKey; key: "/org/asteroidos/ux/display-density"; defaultValue: 0 }
    ConfigurationValue { id: fontKey; key: "/org/asteroidos/ux/font-scale"; defaultValue: 1.0 }
    ConfigurationValue { id: boldKey; key: "/org/asteroidos/ux/bold-text"; defaultValue: false }

    readonly property var densities: Theme.densitySteps
    readonly property var fontScales: Theme.fontScaleSteps
    readonly property var fontLabels: [
        //% "Small"
        qsTrId("id-text-small"),
        //% "Default"
        qsTrId("id-text-default"),
        //% "Medium"
        qsTrId("id-text-medium"),
        //% "Large"
        qsTrId("id-text-large"),
        //% "Larger"
        qsTrId("id-text-larger"),
        //% "Largest"
        qsTrId("id-text-largest")
    ]

    function nearest(values, v) {
        var best = 0
        for (var i = 1; i < values.length; i++)
            if (Math.abs(values[i] - v) < Math.abs(values[best] - v))
                best = i
        return best
    }

    // the step shown: the one chosen and waiting to be applied, else the
    // one nearest to what is set now (1 to n)
    property int pendingDisplay: 0
    property int pendingFont: 0
    property int pendingBold: -1
    readonly property int displayStep: pendingDisplay > 0 ? pendingDisplay
                                       : nearest(densities, Theme.density * 160) + 1
    readonly property int fontStep: pendingFont > 0 ? pendingFont
                                    : nearest(fontScales, Theme.fontScale) + 1
    readonly property bool boldShown: pendingBold >= 0 ? pendingBold === 1 : Theme.boldText

    // stock getSliderStateDescription: the step as a percent of the steps
    // (the number and the percent sign in the form of the locale)
    function percentOf(step, n) {
        return Math.round(step * 100 / n).toLocaleString(Qt.locale(), "f", 0) + Qt.locale().percent
    }

    function applying() {
        toast.show(qsTrId("id-applying"))
    }
    Timer {
        id: displayTimer
        interval: page.applyDelay
        onTriggered: {
            // the default step is the automatic density
            var dpi = page.densities[page.pendingDisplay - 1]
            densityKey.value = dpi === Theme.defaultDensityDpi ? 0 : dpi
            page.pendingDisplay = 0
        }
    }
    Timer {
        id: fontTimer
        interval: page.applyDelay
        onTriggered: {
            fontKey.value = page.fontScales[page.pendingFont - 1]
            page.pendingFont = 0
        }
    }
    Timer {
        id: boldTimer
        interval: page.applyDelay
        onTriggered: {
            boldKey.value = page.pendingBold === 1
            page.pendingBold = -1
        }
    }
    Timer {
        id: resetTimer
        interval: page.applyDelay
        onTriggered: {
            fontKey.value = 1.0
            densityKey.value = 0
            boldKey.value = false
            page.pendingDisplay = 0
            page.pendingFont = 0
            page.pendingBold = -1
        }
    }
    function resetSettings() {
        displayTimer.stop(); fontTimer.stop(); boldTimer.stop()
        applying()
        // show the default steps while the reset waits
        pendingDisplay = nearest(densities, Theme.defaultDensityDpi) + 1
        pendingFont = nearest(fontScales, 1.0) + 1
        pendingBold = 0
        resetTimer.restart()
    }

    SettingsCategory {
        objectName: "displaySizeCategory"
        //% "Display size"
        text: qsTrId("id-display-size-category")
    }
    SettingsSlider {
        objectName: "displaySizeSlider"
        segmented: true
        from: 0
        to: page.densities.length
        lowest: 1
        stepSize: 1
        value: page.displayStep
        decreaseDescription: qsTrId("id-decrease-display-size")
        increaseDescription: qsTrId("id-increase-display-size")
        valueDescription: page.percentOf(page.displayStep, page.densities.length)
        onMoved: (newValue) => {
            resetTimer.stop()
            page.pendingDisplay = newValue
            page.applying()
            displayTimer.restart()
        }
    }
    SettingsText {
        objectName: "displaySizeCaption"
        //% "Make everything bigger or smaller"
        text: qsTrId("id-display-size-explain")
    }
    SettingsCategory {
        objectName: "fontSizeCategory"
        //% "Font size"
        text: qsTrId("id-font-size-category")
    }
    SettingsSlider {
        objectName: "fontSizeSlider"
        segmented: true
        from: 0
        to: page.fontScales.length
        lowest: 1
        stepSize: 1
        value: page.fontStep
        decreaseDescription: qsTrId("id-decrease-font-size")
        increaseDescription: qsTrId("id-increase-font-size")
        valueDescription: page.fontLabels[page.fontStep - 1]
        onMoved: (newValue) => {
            resetTimer.stop()
            page.pendingFont = newValue
            page.applying()
            fontTimer.restart()
        }
    }
    SettingsText {
        objectName: "fontSizeCaption"
        //% "Make text bigger or smaller"
        text: qsTrId("id-font-size-explain")
    }
    SettingsChip {
        objectName: "boldTextSwitch"
        //% "Bold text"
        title: qsTrId("id-bold-text")
        control: "toggle"
        checked: page.boldShown
        onClicked: {
            resetTimer.stop()
            page.pendingBold = page.boldShown ? 0 : 1
            page.applying()
            boldTimer.restart()
        }
    }
    SettingsChip {
        objectName: "resetItem"
        //% "Reset settings"
        title: qsTrId("id-display-reset")
        iconName: "ios-refresh"
        onClicked: page.resetSettings()
    }
}
