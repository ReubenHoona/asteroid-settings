/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * W2-settings-display, on the mocks of tests/mocks (Backend records every
 * dconf, mce and D-Bus write): Settings > Display in stock's order with its
 * titles, summaries, defaults and greying; Screen timeout (stock choices,
 * recommended, the question, the mce values), Go to watch face, Change watch
 * face, the always-on summary precedence, Brightness (fixed and adaptive
 * steps), Display size & text, Wrist orientation, Touch lock, Gestures and
 * the deep links.
 */

import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls

SettingsHarness {
    id: h
    shots: "/tmp/w2sd-shots"

    TestCase {
        name: "SettingsDisplay"
        when: windowShown

        readonly property string kDim: "/system/osso/dsm/display/display_dim_timeout"
        readonly property string kBlank: "/system/osso/dsm/display/display_blank_timeout"
        readonly property string kFace: "/system/osso/dsm/display/display_blank_from_locksreen_timeout"
        readonly property string kGoTo: "/org/asteroidos/settings/go-to-watch-face-ms"
        readonly property string kPicker: "/org/asteroidos/launcher/open-face-picker"
        readonly property string kLongPress: "/org/asteroidos/ux/long-press-face"
        readonly property string kTouchLock: "/org/asteroidos/settings/touch-lock"
        readonly property string kWrist: "/org/asteroidos/settings/wrist-orientation-mode"
        readonly property string kDensity: "/org/asteroidos/ux/display-density"
        readonly property string kFont: "/org/asteroidos/ux/font-scale"
        readonly property string kBold: "/org/asteroidos/ux/bold-text"
        readonly property string kBedtime: "/org/asteroidos/modes/bedtime"
        readonly property string kTheater: "/org/asteroidos/modes/theater"
        readonly property string kSaver: "/org/asteroidos/modes/battery-saver"
        readonly property string kShot: "/org/asteroidos/settings/screenshot-enabled"

        // how often Settings was asked to end (the harness counts)
        readonly property int closed: h.closeCount

        function init() {
            h.start(this)
        }
        // the sizes are Theme's, which reads these keys from the mock for
        // the whole run: put them back
        function cleanup() {
            Backend.confSet(kDensity, 0)
            Backend.confSet(kFont, 1.0)
            Backend.confSet(kBold, false)
        }

        function chip(name) { return h.find(h.current(), name) }
        function conf(key) { return Backend.confGet(key) }
        function last(target, method) { return Backend.find(target, method) }
        function dialog() { return h.find(h.app, "confirmDialog") }
        function accept() { h.tap(this, h.find(h.app, "dialogYes")); wait(50) }
        function reject() { h.tap(this, h.find(h.app, "dialogNo")); wait(50) }
        function open(names) {
            for (var i = 0; i < names.length; i++) {
                h.tapName(this, names[i])
                h.settle(this)
            }
        }
        function title() { return h.find(h.current(), "settingsTitle").text }
        function toast() { return h.find(h.app, "toast") }
        // what the page shows, top to bottom
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
        function brightnessWrites() {
            var n = 0
            for (var i = 0; i < Backend.calls.length; i++)
                if (Backend.calls[i].target === "mce" && Backend.calls[i].method === "display_brightness")
                    n++
            return n
        }
        function mceCalls() {
            var out = []
            for (var i = 0; i < Backend.calls.length; i++)
                if (Backend.calls[i].target === "com.nokia.mce")
                    out.push(Backend.calls[i].method.replace("com.nokia.mce.request.", ""))
            return out
        }
        function pickTimeout(index) {
            h.tap(this, chip("timeoutItem"))
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), index))
            h.settle(this)
        }
        function pickGoTo(index) {
            h.tap(this, chip("goToFaceItem"))
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), index))
            h.settle(this)
        }

        // ---- Display: rows, order, summaries (settings-a-14, wake-sleep-display-13,
        //      ambient-aod-08, wrist-orientation-01, settings-a-21)

        function test_01_display_rows() {
            open(["displayItem"])
            compare(h.current().objectName, "displayPage")
            compare(title(), "Display")
            // stock order (PixelWatchNavRouteCollector$init$4), the user's
            // off-wrist row under Always-on screen; no Extra dim, Always-on
            // brightness, Burn-in protection or Nightstand rows (Q53, Q20, Q34)
            compare(shownRows(h.current()),
                    ["row:Change watch face", "row:Brightness", "row:Display size & text",
                     "row:Screen timeout", "row:Go to watch face", "row:Always-on screen",
                     "row:Always-on when off wrist",
                     "text:Always-on screen stays on when watch is off wrist or charging",
                     "row:Wrist orientation", "row:Touch lock"])
            var gone = ["extraDimItem", "aodBrightnessItem", "burnInItem", "nightstandItem"]
            for (var i = 0; i < gone.length; i++)
                verify(chip(gone[i]) === null, gone[i] + " is not on the page")
            compare(chip("brightnessItem").title, "Brightness")
            compare(chip("brightnessItem").summary, "")
            compare(chip("displaySizeItem").summary, "")
            // 10 + 5 s on the mock watch: the nearest choice is 15 s
            compare(chip("timeoutItem").summary, "15 seconds")
            compare(chip("goToFaceItem").summary, "After 1 minute")
            compare(chip("wristOrientationItem").summary, "")
            compare(chip("touchLockItem").summary, "")
            compare(chip("wristOrientationItem").control, "none")
            verify(chip("aodSwitch").checked && chip("aodSwitch").active)
            h.shot(this, "w2sd-01-display")
            h.scrollToEnd(this)
            h.shot(this, "w2sd-02-display-end")
            // the rows open their pages
            var pages = [["brightnessItem", "brightnessPage", "Brightness"],
                         ["displaySizeItem", "displaySizePage", "Display size & text"],
                         ["wristOrientationItem", "wristOrientationPage", "Wrist orientation"],
                         ["touchLockItem", "touchLockPage", "Touch lock"]]
            h.scrollToEnd(this)
            for (var j = 0; j < pages.length; j++) {
                h.tapName(this, pages[j][0])
                h.settle(this)
                compare(h.current().objectName, pages[j][1])
                h.back(this)
            }
        }

        // ---- Change watch face (face-interaction-29)

        function test_02_change_watch_face() {
            open(["displayItem"])
            var before = Date.now()
            h.tapName(this, "watchfaceItem")
            var v = String(conf(kPicker))
            verify(/^picker@\d+$/.test(v), "picker@<ms>: " + v)
            var t = Number(v.substring(7))
            verify(t >= before - 5 && t <= Date.now() + 5, "the time of the tap")
            // Settings ends after the key is written
            tryCompare(this, "closed", 1, 2000)
            // it stays on this page: no face grid in Settings
            compare(h.current().objectName, "displayPage")
        }

        // ---- Screen timeout (settings-a-15, wake-sleep-display-09/10)

        function test_03_screen_timeout() {
            // mce's dim timeout is 10 s on the mock watch: start from another
            // value so that choosing 10 s is a change it records
            Backend.mce[kDim] = 12
            open(["displayItem"])
            h.tap(this, chip("timeoutItem"))
            h.settle(this)
            var list = h.find(h.current(), "choiceList")
            compare(h.find(h.current(), "choiceTitle").text, "Screen timeout")
            compare(h.find(h.current(), "choiceMessage").text, "When display will turn off after inactivity")
            compare(list.count, 3)
            compare(list.currentIndex, 1, "15 s is the nearest to 10 + 5 s")
            compare(h.listItem(this, list, 0).children[0].title, "10 seconds (recommended)")
            compare(h.listItem(this, list, 1).children[0].title, "15 seconds")
            compare(h.listItem(this, list, 2).children[0].title, "30 seconds")
            h.shot(this, "w2sd-03-timeout-dialog")
            // 10 s, the recommended: at once; no dim phase, the screen on for
            // 10 s on the watch face too
            h.tap(this, h.listItem(this, list, 0))
            h.settle(this)
            verify(!dialog().shown)
            compare(last("mce", kDim).args, [10])
            compare(last("mce", kBlank).args, [0])
            compare(last("mce", kFace).args, [0], "the face adds this to the dim timeout")
            compare(chip("timeoutItem").summary, "10 seconds (recommended)")
            // 15 s asks first, "<label> reduces battery life"
            Backend.clearCalls()
            h.tap(this, chip("timeoutItem"))
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 1))
            verify(dialog().shown)
            compare(dialog().title, "Change screen timeout")
            compare(dialog().message, "15 seconds reduces battery life")
            h.settle(this)
            h.shot(this, "w2sd-04-timeout-ask")
            reject()
            h.settle(this)
            compare(last("mce", kDim), null, "no question accepted, nothing written")
            h.back(this)
            h.settle(this)
            compare(chip("timeoutItem").summary, "10 seconds (recommended)")
            h.tap(this, chip("timeoutItem"))
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 1))
            accept()
            h.settle(this)
            compare(last("mce", kDim).args, [15])
            compare(Backend.mce[kFace], 0)
            compare(chip("timeoutItem").summary, "15 seconds")
            // 30 s
            h.tap(this, chip("timeoutItem"))
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 2))
            compare(dialog().message, "30 seconds reduces battery life")
            accept()
            h.settle(this)
            compare(last("mce", kDim).args, [30])
            compare(Backend.mce[kFace], 0)
            compare(chip("timeoutItem").summary, "30 seconds")
            // stock asks for every choice above 10 s, also going down: 30 -> 15
            h.tap(this, chip("timeoutItem"))
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 1))
            verify(dialog().shown, "15 s asks even though it is shorter than 30 s")
            accept()
            h.settle(this)
            compare(last("mce", kDim).args, [15])
            compare(Backend.mce[kBlank], 0, "the blank timeout is 0 from the first choice on")
        }

        function test_04_odd_timeouts() {
            // a timeout set some other way (eos-cool, the old 5 + 5): the
            // nearest choice shows, nothing is written until one is chosen
            Backend.mce[kDim] = 3
            Backend.mce[kBlank] = 3
            open(["displayItem"])
            compare(chip("timeoutItem").summary, "10 seconds (recommended)")
            Backend.mce[kDim] = 20
            Backend.mce[kBlank] = 30
            Backend.mceWritten(kDim)
            compare(chip("timeoutItem").summary, "30 seconds")
            compare(last("mce", kDim), null)
        }

        // ---- Go to watch face (ambient-aod-02)

        function test_05_go_to_watch_face() {
            open(["displayItem"])
            compare(chip("goToFaceItem").title, "Go to watch face")
            compare(chip("goToFaceItem").summary, "After 1 minute")
            h.tap(this, chip("goToFaceItem"))
            h.settle(this)
            var list = h.find(h.current(), "choiceList")
            compare(h.find(h.current(), "choiceTitle").text, "Go to watch face")
            compare(h.find(h.current(), "choiceMessage").text, "Return to the watch face after inactivity")
            compare(list.count, 7)
            compare(list.currentIndex, 3)
            var labels = ["Immediately", "After 15 seconds", "After 30 seconds", "After 1 minute",
                          "After 2 minutes", "After 5 minutes", "Never"]
            var values = [0, 15000, 30000, 60000, 120000, 300000, 86400000]
            for (var i = 0; i < 7; i++)
                compare(h.listItem(this, list, i).children[0].title, labels[i])
            h.shot(this, "w2sd-05-go-to-face-dialog")
            h.back(this)
            // nothing written by looking
            compare(last("dconf", kGoTo), null)
            for (var j = 0; j < 7; j++) {
                pickGoTo(j)
                compare(conf(kGoTo), values[j], labels[j])
                compare(chip("goToFaceItem").summary, labels[j])
            }
            // another value shows as the nearest
            Backend.confSet(kGoTo, 100000)
            compare(chip("goToFaceItem").summary, "After 2 minutes")
            Backend.confSet(kGoTo, 200)
            compare(chip("goToFaceItem").summary, "Immediately")
        }

        // ---- Always-on summary precedence (ambient-aod-17)

        function test_06_always_on_precedence() {
            open(["displayItem"])
            var cases = [
                [{}, "", true],
                [{ "t": true }, "Theater mode is on", false],
                [{ "s": true, "t": true }, "Battery saver mode is on", false],
                [{ "b": true, "s": true, "t": true }, "Bedtime mode is on", false],
                [{ "b": true, "t": true }, "Bedtime mode is on", false],
                [{ "b": true, "s": true }, "Bedtime mode is on", false]
            ]
            for (var i = 0; i < cases.length; i++) {
                var c = cases[i][0]
                Backend.confSet(kBedtime, !!c.b)
                Backend.confSet(kSaver, !!c.s)
                Backend.confSet(kTheater, !!c.t)
                compare(chip("aodSwitch").summary, cases[i][1], JSON.stringify(c))
                compare(chip("aodSwitch").active, cases[i][2])
                compare(chip("aodOffWristSwitch").summary, cases[i][1])
            }
            // greyed, showing off
            verify(!chip("aodSwitch").checked)
            Backend.confSet(kBedtime, false)
            Backend.confSet(kSaver, false)
            Backend.confSet(kTheater, false)
            verify(chip("aodSwitch").checked)
            // Bedtime holds the brightness row as well
            Backend.confSet(kBedtime, true)
            verify(!chip("brightnessItem").active)
            compare(chip("brightnessItem").summary, "Bedtime mode is on")
            Backend.confSet(kBedtime, false)
        }

        // ---- Brightness (wake-sleep-display-12, wake-sleep-display-13)

        function test_07_brightness_adaptive_and_fixed() {
            open(["displayItem", "brightnessItem"])
            compare(h.current().objectName, "brightnessPage")
            compare(title(), "Brightness")
            // the mock watch: adaptive on, mce at 60 %: Normal is the nearest of 20 / 50 / 85
            compare(shownRows(h.current()), ["category:Adaptive brightness", "slider:brightnessSlider", "row:Adaptive brightness"])
            var s = chip("brightnessSlider")
            verify(s.segmented, "stock's Brightness is a segmented slider")
            compare(s.from, 0)
            compare(s.to, 3)
            compare(s.lowest, 1)
            compare(s.value, 2)
            compare(s.valueDescription, "Normal")
            compare(s.decreaseDescription, "Decrease brightness")
            compare(s.increaseDescription, "Increase brightness")
            compare(chip("adaptiveSwitch").title, "Adaptive brightness")
            verify(chip("adaptiveSwitch").checked)
            scrollTop()
            h.shot(this, "w2sd-06-brightness-adaptive")
            // Bright, 85 %
            plus("brightnessSlider")
            compare(last("mce", "display_brightness").args, [85])
            compare(s.valueDescription, "Bright")
            // the end of the slider: nothing more is written
            var n = brightnessWrites()
            plus("brightnessSlider")
            compare(brightnessWrites(), n)
            minus("brightnessSlider")
            compare(last("mce", "display_brightness").args, [50])
            minus("brightnessSlider")
            compare(last("mce", "display_brightness").args, [20])
            compare(s.valueDescription, "Dim")
            compare(s.value, 1)
            n = brightnessWrites()
            minus("brightnessSlider")
            compare(brightnessWrites(), n, "step 1 is the lowest")
            // adaptive off: fixed brightness, 5 steps of 6, 12, 24, 48 and 100 %
            h.tapName(this, "adaptiveSwitch")
            compare(last("mce", "als_enabled").args, [false])
            compare(shownRows(h.current()), ["category:Fixed brightness", "slider:brightnessSlider", "row:Adaptive brightness"])
            compare(s.to, 5)
            compare(s.lowest, 1)
            // 20 % reads back as the nearest, 24 %
            compare(s.value, 3)
            compare(s.valueDescription, "24 percent screen brightness")
            scrollTop()
            h.shot(this, "w2sd-07-brightness-fixed")
            var expected = [48, 100]
            for (var i = 0; i < expected.length; i++) {
                plus("brightnessSlider")
                compare(last("mce", "display_brightness").args, [expected[i]])
                compare(s.valueDescription, expected[i] + " percent screen brightness")
            }
            compare(s.value, 5)
            n = brightnessWrites()
            plus("brightnessSlider")
            compare(brightnessWrites(), n)
            var down = [48, 24, 12, 6]
            for (var j = 0; j < down.length; j++) {
                minus("brightnessSlider")
                compare(last("mce", "display_brightness").args, [down[j]])
            }
            compare(s.value, 1)
            compare(s.valueDescription, "6 percent screen brightness")
            n = brightnessWrites()
            minus("brightnessSlider")
            compare(brightnessWrites(), n)
            // back to adaptive: 6 % reads as Dim
            h.tapName(this, "adaptiveSwitch")
            compare(last("mce", "als_enabled").args, [true])
            compare(s.to, 3)
            compare(s.value, 1)
            compare(s.valueDescription, "Dim")
        }

        // ---- Display size & text (settings-a-19)

        function test_08_display_size_and_text() {
            open(["displayItem", "displaySizeItem"])
            compare(h.current().objectName, "displaySizePage")
            compare(title(), "Display size & text")
            compare(shownRows(h.current()),
                    ["category:Display size", "slider:displaySizeSlider", "text:Make everything bigger or smaller",
                     "category:Font size", "slider:fontSizeSlider", "text:Make text bigger or smaller",
                     "row:Bold text", "row:Reset settings"])
            var steps = Theme.densitySteps
            if (Theme.autoDensity === 2)
                compare(steps, [284, 301, 320], "the Pixel Watch 2 steps")
            var ds = chip("displaySizeSlider")
            var fs = chip("fontSizeSlider")
            compare(ds.to, steps.length)
            compare(ds.lowest, 1)
            verify(ds.segmented && fs.segmented)
            compare(ds.value, steps.length, "the default size is the last step here")
            // stock getSliderStateDescription: the step as a percent of the steps
            compare(ds.valueDescription, "100%")
            compare(ds.decreaseDescription, "Decrease display size")
            compare(ds.increaseDescription, "Increase display size")
            // 6 font sizes, Default selected
            compare(Theme.fontScaleSteps, [0.94, 1.0, 1.06, 1.12, 1.18, 1.24])
            compare(fs.to, 6)
            compare(fs.lowest, 1)
            compare(fs.value, 2)
            compare(fs.valueDescription, "Default")
            compare(fs.decreaseDescription, "Decrease font size")
            compare(fs.increaseDescription, "Increase font size")
            compare(chip("boldTextSwitch").control, "toggle")
            verify(!chip("boldTextSwitch").checked)
            compare(chip("resetItem").summary, "")
            scrollTop()
            h.shot(this, "w2sd-08-display-size")
            h.scrollToEnd(this)
            h.shot(this, "w2sd-08b-display-size-end")
            scrollTop()
            // nothing is written by looking
            compare(last("dconf", kFont), null)
            compare(last("dconf", kDensity), null)
            // font: Medium; the toast at once, the key 500 ms later
            var t0 = Date.now()
            plus("fontSizeSlider")
            compare(fs.value, 3, "the slider moves at once")
            compare(fs.valueDescription, "Medium")
            verify(toast().visible || toast().active, "Applying...")
            compare(toast().text, "Applying…")
            compare(last("dconf", kFont), null, "not before the delay")
            tryVerify(function () { return last("dconf", kFont) !== null }, 3000)
            verify(Date.now() - t0 >= 450, "500 ms after the tap")
            compare(conf(kFont), 1.06)
            compare(Theme.fontScale, 1.06)
            // two taps inside the delay: one write, the last
            Backend.clearCalls()
            plus("fontSizeSlider")
            plus("fontSizeSlider")
            compare(fs.valueDescription, "Larger")
            tryVerify(function () { return last("dconf", kFont) !== null }, 3000)
            wait(700)
            compare(conf(kFont), 1.18)
            var writes = Backend.calls.filter(function (c) { return c.target === "dconf" && c.method === kFont })
            compare(writes.length, 1, "one write for two taps")
            // the ends: Largest, then nothing more
            plus("fontSizeSlider")
            compare(fs.valueDescription, "Largest")
            wait(700)
            compare(conf(kFont), 1.24)
            minus("fontSizeSlider"); minus("fontSizeSlider"); minus("fontSizeSlider"); minus("fontSizeSlider"); minus("fontSizeSlider")
            compare(fs.valueDescription, "Small")
            compare(fs.value, 1)
            wait(700)
            compare(conf(kFont), 0.94)
            h.shot(this, "w2sd-09-font-small")
            // display size: one step smaller writes that step's dpi; the
            // default step is the automatic density (0)
            minus("displaySizeSlider")
            compare(ds.value, steps.length - 1)
            compare(ds.valueDescription, Math.round((steps.length - 1) * 100 / steps.length) + "%")
            tryVerify(function () { return last("dconf", kDensity) !== null }, 3000)
            compare(conf(kDensity), steps[steps.length - 2])
            plus("displaySizeSlider")
            compare(ds.value, steps.length)
            tryVerify(function () { return conf(kDensity) === 0 }, 3000)
            // bold text
            h.tapName(this, "boldTextSwitch")
            verify(chip("boldTextSwitch").checked, "the switch moves at once")
            compare(toast().text, "Applying…")
            compare(last("dconf", kBold), null)
            tryVerify(function () { return last("dconf", kBold) !== null }, 3000)
            compare(conf(kBold), true)
            verify(Theme.boldText)
            // reset: everything back after the delay
            Backend.confSet(kDensity, steps[0])
            h.tapName(this, "resetItem")
            compare(toast().text, "Applying…")
            compare(conf(kFont), 0.94, "not at once")
            tryVerify(function () { return conf(kFont) === 1.0 }, 3000)
            compare(conf(kDensity), 0)
            compare(conf(kBold), false)
            compare(fs.value, 2)
            verify(!chip("boldTextSwitch").checked)
            compare(ds.value, steps.length)
        }

        // ---- Wrist orientation (wrist-orientation-01, -02, -05)

        function test_09_wrist_orientation() {
            open(["displayItem"])
            h.scrollToEnd(this)
            h.tapName(this, "wristOrientationItem")
            h.settle(this)
            var page = h.current()
            compare(page.objectName, "wristOrientationPage")
            compare(page.title, "Wrist orientation")
            var col = h.find(page, "settingsColumn")
            // stock's paddings: 16.64 % at the top, 5.2 % at the sides
            compare(col.y, Math.ceil(page.height * 0.1664))
            compare(col.x, Math.ceil(page.width * 0.052))
            if (page.height === 384) {
                compare(col.y, 64)
                compare(col.x, 20)
                // the bottom 36.46 % is ceil()ed as stock's code does (141, the audit said 140)
                compare(h.find(page, "settingsFlickable").contentHeight, col.y + col.height + 141)
            }
            compare(h.find(page, "wristTitle").text, "Wrist orientation")
            compare(h.find(page, "wristHeader").text, "Wrist")
            compare(h.find(page, "crownHeader").text, "Crown")
            compare(page.wristHint, "Which wrist do you want to wear your watch on?")
            compare(page.crownHint,
                    "Where do you want the crown? Changing the location will flip the display.")
            var names = ["leftWristButton", "rightWristButton", "leftCrownButton", "rightCrownButton"]
            var descr = ["Left wrist", "Right wrist", "Crown on the left", "Crown on the right"]
            var caps = ["Left", "Right", "Left", "Right"]
            var capNames = ["leftWristCaption", "rightWristCaption", "leftCrownCaption", "rightCrownCaption"]
            for (var i = 0; i < 4; i++) {
                var b = h.find(page, names[i])
                compare(b.width, Theme.dp(80), "80 dp round toggle")
                compare(b.height, b.width)
                compare(b.description, descr[i])
                compare(h.find(page, capNames[i]).text, caps[i])
                compare(h.find(b, "wristToggleDisc").radius, b.width / 2)
            }
            // 8 dp between the toggles of a row
            var l = h.find(page, "leftWristButton"), r = h.find(page, "rightWristButton")
            compare(r.mapToItem(page, 0, 0).x - l.mapToItem(page, 0, 0).x, l.width + Theme.dp(8))
            // the mock watch is mode 0: left wrist, crown on the right
            function checkedNames() {
                return names.filter(function (n) { return h.find(page, n).checked })
            }
            compare(checkedNames(), ["leftWristButton", "rightCrownButton"])
            // checked is primary, not checked the surface colour
            compare(String(h.find(h.find(page, "leftWristButton"), "wristToggleDisc").color), String(Theme.color.primary))
            compare(String(h.find(h.find(page, "rightWristButton"), "wristToggleDisc").color), String(Theme.color.surfaceContainer))
            scrollTop()
            h.shot(this, "w2sd-10-wrist-orientation")
            h.scrollToEnd(this)
            h.shot(this, "w2sd-10b-wrist-orientation-end")
            // looking writes nothing; the selected one does nothing
            compare(last("dconf", kWrist), null)
            h.tapName(this, "leftWristButton")
            h.tapName(this, "rightCrownButton")
            compare(last("dconf", kWrist), null)
            compare(mceCalls(), [])
            // the mode: left ? (crown right ? 0 : 1) : (crown right ? 2 : 3)
            h.tapName(this, "leftCrownButton")
            compare(conf(kWrist), 1)
            compare(checkedNames(), ["leftWristButton", "leftCrownButton"])
            // a crown change holds the screen on: the display on and a
            // blanking pause, which ends 1 s later (stock's 1000 ms wake lock)
            compare(mceCalls(), ["req_display_state_on", "req_display_blanking_pause"])
            var t0 = Date.now()
            tryVerify(function () { return mceCalls().length === 3 }, 3000)
            compare(mceCalls()[2], "req_display_cancel_blanking_pause")
            verify(Date.now() - t0 >= 700, "about 1 s after the change")
            Backend.clearCalls()
            h.tapName(this, "rightWristButton")
            compare(conf(kWrist), 3)
            compare(checkedNames(), ["rightWristButton", "leftCrownButton"])
            compare(mceCalls(), [], "a wrist change does not touch the display")
            h.tapName(this, "rightCrownButton")
            compare(conf(kWrist), 2)
            compare(checkedNames(), ["rightWristButton", "rightCrownButton"])
            h.tapName(this, "leftWristButton")
            compare(conf(kWrist), 0)
            h.shot(this, "w2sd-11-wrist-orientation-left")
            h.tapName(this, "rightWristButton")
            h.tapName(this, "leftCrownButton")
            h.shot(this, "w2sd-11b-wrist-orientation-right-crown-left")
            h.tapName(this, "leftWristButton")
            h.tapName(this, "rightCrownButton")
            compare(conf(kWrist), 0)
            // a value from elsewhere shows at once; junk reads as 0
            Backend.confSet(kWrist, 3)
            compare(checkedNames(), ["rightWristButton", "leftCrownButton"])
            Backend.confSet(kWrist, 9)
            compare(checkedNames(), ["leftWristButton", "rightCrownButton"])
        }

        // ---- Touch lock (settings-a-21)

        function test_10_touch_lock() {
            open(["displayItem"])
            h.scrollToEnd(this)
            h.tapName(this, "touchLockItem")
            h.settle(this)
            compare(h.current().objectName, "touchLockPage")
            compare(title(), "Touch lock")
            compare(shownRows(h.current()),
                    ["row:Touch lock", "text:Turns off touch screen. Press & hold crown for 2 sec. to turn it back on."])
            compare(chip("touchLockButton").control, "none")
            compare(last("dconf", kTouchLock), null)
            h.shot(this, "w2sd-12-touch-lock")
            h.tapName(this, "touchLockButton")
            compare(conf(kTouchLock), true, "on at once, no question")
            verify(!dialog().shown)
            tryCompare(this, "closed", 1, 2000)
        }

        // ---- Gestures (settings-a-24, face-interaction-05, system-dialogs-misc-07)

        function test_11_gestures() {
            open(["gesturesItem"])
            compare(h.current().objectName, "gesturesPage")
            // stock's order on a watch with a Buttons page: Tilt, Touch,
            // Long press watch face; Rotate-to-wake and Screenshot are on Buttons
            compare(shownRows(h.current()),
                    ["row:Tilt-to-wake", "row:Touch-to-wake", "row:Long press watch face",
                     "text:Hold the watch face to change or edit it"])
            verify(chip("longPressSwitch").checked, "on by default")
            compare(chip("longPressSwitch").control, "toggle")
            compare(last("dconf", kLongPress), null)
            h.shot(this, "w2sd-13-gestures")
            // turning tilt-to-wake on asks "Turn on tilt-to-wake?"
            Backend.tilt = false
            verify(!chip("tiltSwitch").checked)
            h.tapName(this, "tiltSwitch")
            verify(dialog().shown)
            compare(dialog().title, "Turn on tilt-to-wake?")
            compare(dialog().message, "Tilt-to-wake reduces battery life.")
            h.settle(this)
            h.shot(this, "w2sd-14-tilt-ask")
            reject()
            h.settle(this)
            verify(!Backend.tilt)
            h.tapName(this, "tiltSwitch")
            accept()
            h.settle(this)
            verify(Backend.tilt)
            // turning it off is at once
            h.tapName(this, "tiltSwitch")
            verify(!dialog().shown)
            verify(!Backend.tilt)
            // Long press watch face: off asks "Turn off?"
            h.tapName(this, "longPressSwitch")
            verify(dialog().shown)
            compare(dialog().title, "Turn off?")
            compare(dialog().message,
                    "You can still change and edit watch faces using Settings > Display > Change watch face.")
            h.settle(this)
            h.shot(this, "w2sd-15-long-press-ask")
            reject()
            h.settle(this)
            verify(chip("longPressSwitch").checked)
            compare(last("dconf", kLongPress), null)
            h.tapName(this, "longPressSwitch")
            accept()
            h.settle(this)
            compare(conf(kLongPress), false)
            verify(!chip("longPressSwitch").checked)
            // on again: at once
            h.tapName(this, "longPressSwitch")
            verify(!dialog().shown)
            compare(conf(kLongPress), true)
            verify(chip("longPressSwitch").checked)
            // Screenshot is on Buttons > Chord press, as stock with a Buttons page
            h.back(this)
            open(["buttonsItem"])
            compare(chip("screenshotSwitch").title, "Screenshot")
            compare(chip("screenshotCaption").text,
                    "Take a screenshot by pressing the crown and side button at the same time")
            verify(chip("screenshotSwitch").checked, "on by default")
            h.tapName(this, "screenshotSwitch")
            compare(conf(kShot), false)
        }

        // ---- deep links

        function test_12_deep_links() {
            var cases = { "display": ["displayPage"], "brightness": ["displayPage", "brightnessPage"],
                          "display_size": ["displayPage", "displaySizePage"],
                          "wrist_orientation": ["displayPage", "wristOrientationPage"],
                          "touch_lock": ["displayPage", "touchLockPage"],
                          "extra_dim": ["extraDimPage"] }
            for (var k in cases) {
                Backend.confSet("/org/asteroidos/settings/ui/open", k + "@" + Date.now())
                wait(150)
                var names = []
                for (var i = 0; i < h.stack.layers.length; i++)
                    names.push(h.stack.layers[i].objectName)
                compare(names, cases[k], k)
            }
        }
    }
}
