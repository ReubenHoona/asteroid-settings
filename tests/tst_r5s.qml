/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * R5-settings, on the mocks of tests/mocks (Backend records every dconf,
 * mce and D-Bus write): the items of AUDIT-72 area C that Settings closes.
 * C-06 the adaptive brightness levels from dconf; C-07 Text-to-speech
 * output (System, Accessibility, the engine's page); C-09 Sound > Audio
 * adjustment; C-12 Date & time > Use location.
 */

import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls

SettingsHarness {
    id: h
    shots: "/tmp/r5s-shots"

    TestCase {
        name: "SettingsR5"
        when: windowShown

        readonly property string kLevels: "/org/asteroidos/settings/adaptive-brightness-levels"

        function init() {
            h.start(this)
            Backend.clearCalls()
        }

        function chip(name) { return h.find(h.current(), name) }
        function conf(key) { return Backend.confGet(key) }
        function last(target, method) { return Backend.find(target, method) }
        function open(names) {
            for (var i = 0; i < names.length; i++) {
                h.tapName(this, names[i])
                h.settle(this)
            }
        }
        function title() { return h.find(h.current(), "settingsTitle").text }
        function shownRows(page) {
            var col = h.find(page, "settingsColumn")
            var out = []
            for (var i = 0; i < col.children.length; i++) {
                var c = col.children[i]
                if (!c.visible || c.objectName === "settingsTitle")
                    continue
                if (c.hasOwnProperty("firstInPage"))
                    out.push("category:" + c.text)
                else if (c.hasOwnProperty("stepSize"))
                    out.push("slider:" + c.objectName)
                else if (c.hasOwnProperty("control") && c.hasOwnProperty("summary"))
                    out.push("row:" + c.title)
                else if (c.text !== undefined)
                    out.push("text:" + c.text)
            }
            return out
        }
        function scrollTop() { h.find(h.current(), "settingsFlickable").contentY = 0; wait(100) }
        function plus(name) { h.tap(this, h.find(chip(name), "sliderPlus")) }
        function minus(name) { h.tap(this, h.find(chip(name), "sliderMinus")) }
        function brightness() { return last("mce", "display_brightness").args[0] }
        function choices() {
            var list = h.find(h.current(), "choiceList")
            var out = []
            for (var i = 0; i < list.model; i++)
                out.push(list.textOf(i))
            return out
        }
        function pick(item, index) {
            h.tap(this, chip(item))
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), index))
            h.settle(this)
        }
        function toastText() { return h.find(h.find(h.app, "toast"), "toastText").text }
        function request(route) {
            Backend.confSet("/org/asteroidos/settings/ui/open", route + "@" + Date.now())
            wait(500)
            h.settle(this)
        }
        function scrollTo(name) {
            h.bringIntoView(this, chip(name))
        }

        readonly property string kHelper: "/usr/libexec/asteroid-assistant/asteroid-assistant-tts"
        readonly property string kSpeed: "/org/asteroidos/assistant/tts-speed"
        readonly property string kTtsLang: "/org/asteroidos/assistant/tts-language"
        readonly property string kSample: "/org/asteroidos/assistant/tts-sample-supported"
        function engine(on) {
            var f = {}
            if (on)
                f[kHelper] = true
            Backend.files = f
        }

        // C-06: Dim / Normal / Bright are the three percents of the dconf
        // key when it holds three rising whole percents, else 20, 50, 85
        function test_c06_adaptive_levels_from_dconf() {
            open(["displayItem", "brightnessItem"])
            var page = h.current()
            compare(page.objectName, "brightnessPage")
            var s = chip("brightnessSlider")
            // the mock watch: adaptive on, mce at 60: Normal of 20 / 50 / 85
            compare(page.adaptivePercents, [20, 50, 85])
            compare(s.value, 2)
            minus("brightnessSlider")
            compare(brightness(), 20)
            plus("brightnessSlider")
            compare(brightness(), 50)
            plus("brightnessSlider")
            compare(brightness(), 85)
            compare(s.valueDescription, "Bright")

            // tuned levels (an array, as dconf write "[15, 40, 70]")
            Backend.confSet(kLevels, [15, 40, 70])
            compare(page.adaptivePercents, [15, 40, 70])
            // 85 stored: Bright is the nearest
            compare(s.value, 3)
            minus("brightnessSlider")
            compare(brightness(), 40)
            compare(s.value, 2)
            compare(s.valueDescription, "Normal")
            minus("brightnessSlider")
            compare(brightness(), 15)
            compare(s.valueDescription, "Dim")
            // a stored level between two steps reads back as the nearest
            Backend.brightness = 60
            compare(s.value, 3)
            Backend.brightness = 50
            compare(s.value, 2)

            // a string as written by hand
            Backend.confSet(kLevels, "10, 45,90")
            compare(page.adaptivePercents, [10, 45, 90])
            Backend.confSet(kLevels, "[12;44;88]")
            compare(page.adaptivePercents, [12, 44, 88])

            // anything else is the built-in levels
            var bad = [[50, 40, 90], [20, 20, 85], [0, 50, 85], [20, 50, 101], [20, 50], [20, 50, 85, 95],
                       [20.5, 50, 85], ["a", 50, 85], "", "abc", "20,,85", "20,50", 42, true]
            for (var i = 0; i < bad.length; i++) {
                Backend.confSet(kLevels, bad[i])
                compare(page.adaptivePercents, [20, 50, 85], "not three rising percents: " + JSON.stringify(bad[i]))
            }

            // the fixed steps do not take the key
            Backend.confSet(kLevels, [15, 40, 70])
            h.tapName(this, "adaptiveSwitch")
            h.settle(this)
            verify(!page.adaptive)
            compare(page.percents, [6, 12, 24, 48, 100])
            compare(s.to, 5)
        }

        // C-07: Text-to-speech output in System (after Input methods) and
        // Accessibility (General, after Gestures), only with a speech engine
        function test_c07_rows_need_an_engine() {
            engine(false)
            open(["systemItem"])
            verify(!h.shown(chip("ttsItem")), "no engine: no System row")
            h.home(this)
            open(["accessibilityItem"])
            verify(!h.shown(chip("ttsA11yItem")), "no engine: no Accessibility row")
            h.home(this)
            request("text_to_speech_output")
            compare(h.current().objectName, "mainPage")

            engine(true)
            open(["systemItem"])
            var rows = shownRows(h.current())
            var i = rows.indexOf("row:Input methods")
            verify(i >= 0, JSON.stringify(rows))
            compare(rows[i + 1], "row:Text-to-speech output")
            compare(rows[i + 2], "row:Language")
            h.home(this)
            open(["accessibilityItem"])
            rows = shownRows(h.current())
            i = rows.indexOf("row:Gestures")
            verify(i >= 0, JSON.stringify(rows))
            compare(rows[i + 1], "row:Text-to-speech output")
            open(["ttsA11yItem"])
            compare(h.current().objectName, "ttsPage")
            h.home(this)
            request("text_to_speech_output")
            compare(h.current().objectName, "ttsPage")
            h.back(this)
            compare(h.current().objectName, "systemPage")
        }

        // the page: the engine (accent chip, the default) and Speech rate,
        // stock's nine rates on the assistant's tts-speed factor
        function test_c07_speech_rate() {
            engine(true)
            open(["systemItem", "ttsItem"])
            compare(title(), "Text-to-speech output")
            compare(shownRows(h.current()), ["row:Flite", "row:Speech rate"])
            var e = chip("ttsEngineItem")
            compare(e.control, "select")
            verify(e.checked, "the default engine is the accent chip")
            compare(chip("ttsRateItem").summary, "Normal")
            h.shot(this, "c07-tts-page")
            h.tap(this, chip("ttsRateItem"))
            h.settle(this)
            compare(choices(), ["Very slow", "Slow", "Normal", "Fast", "Faster", "Very fast", "Rapid",
                                "Very rapid", "Fastest"])
            compare(h.find(h.current(), "choiceList").currentIndex, 2)
            h.shot(this, "c07-tts-rates")
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 4))
            h.settle(this)
            compare(conf(kSpeed), 2)
            compare(chip("ttsRateItem").summary, "Faster")
            pick("ttsRateItem", 0)
            compare(conf(kSpeed), 0.6)
            compare(chip("ttsRateItem").summary, "Very slow")
            pick("ttsRateItem", 8)
            compare(conf(kSpeed), 4)
            // a factor set elsewhere reads as the nearest rate
            Backend.confSet(kSpeed, 1.4)
            compare(chip("ttsRateItem").summary, "Fast")
            Backend.confSet(kSpeed, "x")
            compare(chip("ttsRateItem").summary, "Normal")
        }

        // the engine's page: the status toast, Language, Listen to an
        // example (behind its gate), Set as default (one engine: greyed on)
        function test_c07_engine_page() {
            engine(true)
            open(["systemItem", "ttsItem", "ttsEngineItem"])
            compare(h.current().objectName, "ttsEnginePage")
            compare(title(), "Engine settings")
            tryCompare(h.find(h.app, "toast"), "visible", true)
            compare(toastText(), "English (United States) is fully supported")
            compare(shownRows(h.current()), ["row:Language", "row:Set as default"])
            compare(chip("ttsLanguageItem").summary, "Use system language")
            var d = chip("ttsDefaultSwitch")
            verify(d.checked && !d.active, "the one engine is the default, greyed")
            h.shot(this, "c07-tts-engine")
            h.tap(this, chip("ttsLanguageItem"))
            h.settle(this)
            compare(choices(), ["Use system language", "English (United States)"])
            compare(h.find(h.current(), "choiceList").currentIndex, 0)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 1))
            h.settle(this)
            compare(conf(kTtsLang), "en_US")
            compare(chip("ttsLanguageItem").summary, "English (United States)")
            pick("ttsLanguageItem", 0)
            compare(conf(kTtsLang), "")

            // Listen to an example once the assistant can speak it
            verify(!h.shown(chip("ttsListenItem")), "hidden behind its gate")
            Backend.confSet(kSample, true)
            verify(h.shown(chip("ttsListenItem")))
            verify(chip("ttsListenItem").active)
            compare(shownRows(h.current()), ["row:Language", "row:Listen to an example", "row:Set as default"])
            Backend.clearCalls()
            h.tap(this, chip("ttsListenItem"))
            var c = last("org.asteroidos.assistant", "org.asteroidos.assistant.Speak")
            verify(c !== null, "Speak was called")
            compare(c.args, ["This is an example of speech synthesis"])
            h.shot(this, "c07-tts-engine-listen")
            // leaving the page stops the sample, as stock's onDestroy
            h.back(this)
            h.settle(this)
            tryVerify(function () { return last("org.asteroidos.assistant", "org.asteroidos.assistant.StopSpeaking") !== null },
                      5000, "the sample stops with the page")
        }

        // C-09: Sound has stock's Audio adjustment row after Charging
        // sounds, behind the same gate as Accessibility's (CR-33)
        function test_c09_sound_audio_adjustment() {
            open(["soundItem"])
            var rows = shownRows(h.current())
            verify(rows.indexOf("row:Audio adjustment") < 0, "hidden behind its gate: " + JSON.stringify(rows))
            Backend.confSet("/org/asteroidos/a11y/audio-adjust-supported", true)
            rows = shownRows(h.current())
            var i = rows.indexOf("row:Charging sounds")
            verify(i >= 0, JSON.stringify(rows))
            compare(rows[i + 1], "row:Audio adjustment")
            compare(rows[i + 2], "row:Wireless emergency alerts")
            compare(chip("soundAudioAdjustmentItem").summary, "Mono audio, Audio balance")
            h.scrollToEnd(this)
            h.shot(this, "c09-sound-audio-adjustment")
            open(["soundAudioAdjustmentItem"])
            compare(h.current().objectName, "audioAdjustPage")
            h.back(this)
            h.settle(this)
            compare(h.current().objectName, "soundPage")
        }

        // C-12: Date & time > Use location and its caption, after Automatic
        // time zone, behind the gate of the package that sets the zone
        function test_c12_use_location() {
            var kLoc = "/org/asteroidos/settings/location-time-zone"
            var kOn = "/org/asteroidos/settings/location-enabled"
            var kZone = "/org/asteroidos/settings/auto-time-zone"
            open(["systemItem", "dateTimeItem"])
            var rows = shownRows(h.current())
            verify(rows.indexOf("row:Use location") < 0, "hidden behind its gate: " + JSON.stringify(rows))
            Backend.confSet("/org/asteroidos/settings/location-time-zone-supported", true)
            rows = shownRows(h.current())
            var i = rows.indexOf("row:Automatic time zone")
            verify(i >= 0, JSON.stringify(rows))
            compare(rows[i + 1], "row:Use location")
            compare(rows[i + 2], "text:Location may be used to set time zone")
            compare(rows[i + 3], "row:Automatic time format")
            var sw = chip("locationTimeZoneSwitch")
            verify(sw.active && !sw.checked, "stock default: off")
            wait(200)
            h.bringIntoView(this, sw)
            h.shot(this, "c12-use-location")
            h.tap(this, sw)
            h.settle(this)
            compare(conf(kLoc), true)
            verify(sw.checked)
            h.tap(this, sw)
            h.settle(this)
            compare(conf(kLoc), false)
            // Automatic time zone off: greyed, unchecked, its caption
            Backend.confSet(kLoc, true)
            Backend.confSet(kZone, false)
            verify(!sw.active && !sw.checked)
            compare(chip("locationTimeZoneCaption").text, "Automatic time zone is off")
            h.tap(this, sw)
            h.settle(this)
            compare(conf(kLoc), true, "a greyed switch does nothing")
            // Location off: unchecked, "Location is off"; turning it on asks
            Backend.confSet(kZone, true)
            verify(sw.checked)
            Backend.confSet(kOn, false)
            verify(sw.active && !sw.checked)
            compare(chip("locationTimeZoneCaption").text, "Location is off")
            Backend.confSet(kLoc, false)
            h.tap(this, sw)
            h.settle(this)
            var d = h.find(h.app, "confirmDialog")
            tryVerify(function () { return d.shown })
            compare(d.title, "Device location needed")
            compare(d.message, "To set the time zone using your location, turn on location, then update time zone settings")
            h.shot(this, "c12-location-needed")
            compare(conf(kLoc), false, "nothing is set while location is off")
            h.tap(this, h.find(h.app, "dialogYes"))
            h.settle(this)
            compare(h.current().objectName, "locationPage")
        }
    }
}
