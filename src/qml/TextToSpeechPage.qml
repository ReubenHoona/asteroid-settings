/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Text-to-speech output, from System and Accessibility, as stock CP3A's
// TtsFragment (prefs_accessibility_tts.xml; TtsFragment.java:24-58): one row
// per speech engine, the default one drawn as the accent chip
// (chip_button_accent_streched), each opening its Engine settings
// (TextToSpeechEnginePage), then Speech rate, the list of nine rates
// (tts_rate_entries / tts_rate_entry_values 60 to 400, Normal 100 the
// default when tts_default_rate is unset). Stock removes the rows that open
// this page when there is no engine (SystemSettingsFragment.java:158-161,
// AccessibilityFragment.java:128-131); here the one engine is flite through
// asteroid-assistant's speech helper (app.ttsInstalled()). The rate is the
// assistant's /org/asteroidos/assistant/tts-speed (a factor, 1.0 = Normal),
// which it reads at each spoken answer: stock's percent / 100.
SettingsPage {
    id: page
    objectName: "ttsPage"
    //% "Text-to-speech output"
    title: qsTrId("id-tts-page")

    ConfigurationValue {
        id: speed
        key: "/org/asteroidos/assistant/tts-speed"
        defaultValue: 1.0
    }

    // tts_rate_entry_values
    readonly property var rates: [60, 80, 100, 150, 200, 250, 300, 350, 400]
    readonly property var rateNames: [
        //% "Very slow"
        qsTrId("id-tts-rate-very-slow"),
        //% "Slow"
        qsTrId("id-tts-rate-slow"),
        //% "Normal"
        qsTrId("id-tts-rate-normal"),
        //% "Fast"
        qsTrId("id-tts-rate-fast"),
        //% "Faster"
        qsTrId("id-tts-rate-faster"),
        //% "Very fast"
        qsTrId("id-tts-rate-very-fast"),
        //% "Rapid"
        qsTrId("id-tts-rate-rapid"),
        //% "Very rapid"
        qsTrId("id-tts-rate-very-rapid"),
        //% "Fastest"
        qsTrId("id-tts-rate-fastest")
    ]
    // the rate nearest to the stored factor (Normal when it is not a number)
    readonly property int rateIndex: {
        var f = Number(speed.value)
        if (!isFinite(f) || f <= 0)
            return 2
        var best = 0
        for (var i = 1; i < rates.length; i++)
            if (Math.abs(rates[i] - f * 100) < Math.abs(rates[best] - f * 100))
                best = i
        return best
    }

    SettingsChip {
        objectName: "ttsEngineItem"
        title: app.ttsEngineName
        // the default engine: stock's accent chip
        control: "select"
        checked: true
        onClicked: layerStack.push(ttsEngineLayer)
    }
    SettingsChip {
        objectName: "ttsRateItem"
        //% "Speech rate"
        title: qsTrId("id-tts-speech-rate")
        summary: page.rateNames[page.rateIndex]
        onClicked: app.choose(qsTrId("id-tts-speech-rate"), page.rateNames, page.rateIndex,
                              function (i) { speed.value = page.rates[i] / 100 })
    }
}
