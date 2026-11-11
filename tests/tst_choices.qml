/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * W1-settings-choices: the user's five choices as Settings rows (PLAN.md
 * section 4), on the mocks of tests/mocks (Backend records every dconf and
 * mce write): the rows in stock order with their titles, captions and
 * values; the code defaults (= the user's values and the image's
 * 00-eos-defaults); what each switch writes (the other value = stock's);
 * greying under the master switch, the modes and Automatic time format;
 * the samples the vibration switches play (the real org.asteroid.controls
 * Haptics); the side-button dialog and the always-on question.
 * Run once with no dconf database (Haptics: Using crown off, so the crown
 * sample waits and gives up) and once with DB=crown (Using crown on).
 */

import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls

SettingsHarness {
    id: h

    // when each haptic event passed Haptics' switches, and when each key
    // was last written (the switch's click handler writes it first)
    property var stamps: []
    property var written: ({})
    Connections {
        target: Haptics
        function onPlayed(event) {
            var l = h.stamps.slice()
            l.push({ "event": event, "t": Date.now() })
            h.stamps = l
        }
    }
    Connections {
        target: Backend
        function onConfWritten(key) { h.written[key] = Date.now() }
    }

    TestCase {
        name: "Choices"
        when: windowShown

        readonly property string kVibration: "/desktop/asteroid/vibration"
        readonly property string kTouch: "/org/asteroidos/ux/haptics"
        readonly property string kCrown: "/org/asteroidos/ux/haptics-crown"
        readonly property string kFast: "/org/asteroidos/ux/crown-fast"
        readonly property string kSide: "/org/asteroidos/ux/side-button"
        readonly property string kShot: "/org/asteroidos/settings/screenshot-enabled"
        readonly property string kAod: "/org/asteroidos/settings/always-on-display"
        readonly property string kOffWrist: "/org/asteroidos/settings/always-on-off-wrist"
        readonly property string kAuto: "/org/asteroidos/settings/time-format-from-phone"
        readonly property string k12h: "/org/asteroidos/settings/use-12h-format"
        readonly property string kRotary: "/system/osso/dsm/display/rotary_wake_enabled"

        function init() {
            h.start(this)
            h.stamps = []
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
        // what the page shows, top to bottom: rows, categories and captions
        function shownRows(page) {
            var col = h.find(page, "settingsColumn")
            var out = []
            for (var i = 0; i < col.children.length; i++) {
                var c = col.children[i]
                if (!c.visible || c.objectName === "settingsTitle")
                    continue
                if (c.hasOwnProperty("firstInPage"))
                    out.push("category:" + c.text)
                else if (c.hasOwnProperty("control") && c.hasOwnProperty("summary"))
                    out.push("row:" + c.title)
                else if (c.text !== undefined)
                    out.push("text:" + c.text)
            }
            return out
        }
        function indexIn(page, name) {
            var col = h.find(page, "settingsColumn")
            var item = h.find(page, name)
            for (var i = 0; i < col.children.length; i++)
                if (col.children[i] === item)
                    return i
            return -1
        }
        function writesOf(key) {
            var n = 0
            for (var i = 0; i < Backend.calls.length; i++)
                if (Backend.calls[i].target === "dconf" && Backend.calls[i].method === key)
                    n++
            return n
        }
        function count(event) {
            var n = 0
            for (var i = 0; i < h.stamps.length; i++)
                if (h.stamps[i].event === event)
                    n++
            return n
        }
        function stampOf(event) {
            for (var i = 0; i < h.stamps.length; i++)
                if (h.stamps[i].event === event)
                    return h.stamps[i].t
            return -1
        }
        // the image's 00-eos-defaults (W1-meta-config) for the five choices
        function imageDefaults() {
            Backend.confSet(kVibration, true)
            Backend.confSet(kTouch, true)
            Backend.confSet(kCrown, false)
            Backend.confSet(kFast, true)
            Backend.confSet(kSide, "assistant")
            Backend.confSet(kShot, true)
            Backend.confSet(kAod, true)
            Backend.confSet(kOffWrist, true)
            Backend.confSet(kAuto, false)
            Backend.confSet(k12h, true)
        }
        function setModes(bedtime, theater, saver) {
            Backend.confSet("/org/asteroidos/modes/bedtime", bedtime)
            Backend.confSet("/org/asteroidos/modes/theater", theater)
            Backend.confSet("/org/asteroidos/modes/battery-saver", saver)
            wait(50)
        }
        function mceWith(key, v) {
            var m = {}
            for (var k in Backend.mce)
                m[k] = Backend.mce[k]
            m[key] = v
            Backend.mce = m
        }

        // the code defaults are the user's values: what the rows show with
        // an empty dconf database, and with the image defaults
        function test_01_defaults_are_the_users_choices() {
            for (var pass = 0; pass < 2; pass++) {
                if (pass === 1) {
                    h.home(this)
                    imageDefaults()
                } else {
                    // the TimeFormat singleton outlives a test: empty its key too
                    Backend.confSet(k12h, undefined)
                    delete Backend.conf[k12h]
                }
                open(["vibrationItem"])
                verify(chip("vibrationSwitch").checked, "Vibration & haptics on")
                verify(chip("touchFeedbackSwitch").checked, "Touch feedback on")
                verify(!chip("crownHapticsSwitch").checked, "Using crown off (choice 1)")
                h.home(this)
                open(["buttonsItem"])
                verify(chip("crownFastSwitch").checked, "Faster crown scrolling on (choice 2)")
                compare(chip("sideButtonItem").summary, "Press & hold for Assistant")
                verify(chip("screenshotSwitch").checked, "Screenshot on, as stock")
                h.home(this)
                open(["displayItem"])
                verify(chip("aodSwitch").checked, "Always-on screen on (choice 3)")
                verify(chip("aodOffWristSwitch").checked, "Always-on when off wrist on (choice 3)")
                verify(chip("aodOffWristSwitch").active)
                h.home(this)
                open(["systemItem", "dateTimeItem"])
                verify(!chip("autoTimeFormatSwitch").checked, "Automatic time format off (choice 4)")
                verify(h.shown(chip("hourFormatSwitch")))
                verify(!h.shown(chip("hourFormatCaption")))
                // the 12/24 switch shows what the clocks do (TimeFormat: same key, same code default)
                compare(chip("hourFormatSwitch").checked, TimeFormat.use24h)
                if (pass === 0)
                    verify(chip("hourFormatSwitch").checked, "no database: the code default, 24 h")
                else
                    verify(!chip("hourFormatSwitch").checked, "the image: 12 h, the user's choice")
            }
            // nothing is written by looking
            Backend.clearCalls()
            h.home(this)
            open(["buttonsItem"])
            h.home(this)
            open(["vibrationItem"])
            compare(Backend.calls.length, 0)
        }

        // Vibration: rows in stock order, the keys, the master greys the two
        function test_02_vibration_rows() {
            open(["vibrationItem"])
            compare(shownRows(h.current()),
                    ["row:Silence watch while charging",
                     "text:Notifications won't sound or vibrate while the watch is charging",
                     "row:Vibration & haptics",
                     "category:Interactive haptics",
                     "row:Touch feedback",
                     "row:Using crown"])
            // every row a switch, none with a value line
            var names = ["vibrationSwitch", "touchFeedbackSwitch", "crownHapticsSwitch"]
            for (var i = 0; i < names.length; i++) {
                compare(chip(names[i]).control, "toggle")
                compare(chip(names[i]).summary, "")
            }
            // Using crown: on writes stock's value, off the user's
            h.tapName(this, "crownHapticsSwitch")
            compare(conf(kCrown), true)
            verify(chip("crownHapticsSwitch").checked)
            h.tapName(this, "crownHapticsSwitch")
            compare(conf(kCrown), false)
            // Touch feedback
            h.tapName(this, "touchFeedbackSwitch")
            compare(conf(kTouch), false)
            verify(!chip("touchFeedbackSwitch").checked)
            h.tapName(this, "touchFeedbackSwitch")
            compare(conf(kTouch), true)
            // the master off greys both; they keep showing their own value
            Backend.confSet(kCrown, true)
            h.tapName(this, "vibrationSwitch")
            compare(conf(kVibration), false)
            verify(!chip("touchFeedbackSwitch").active)
            verify(!chip("crownHapticsSwitch").active)
            verify(chip("touchFeedbackSwitch").checked)
            verify(chip("crownHapticsSwitch").checked)
            // a greyed row takes no tap
            Backend.clearCalls()
            h.tapName(this, "crownHapticsSwitch")
            h.tapName(this, "touchFeedbackSwitch")
            compare(Backend.calls.length, 0)
            compare(conf(kCrown), true)
            h.tapName(this, "vibrationSwitch")
            compare(conf(kVibration), true)
            verify(chip("touchFeedbackSwitch").active)
            verify(chip("crownHapticsSwitch").active)
            // no mode holds them (choice-settings-15)
            setModes(true, true, true)
            verify(chip("vibrationSwitch").active)
            verify(chip("touchFeedbackSwitch").active)
            verify(chip("crownHapticsSwitch").active)
            compare(chip("crownHapticsSwitch").summary, "")
        }

        // the samples: the master's at once, Touch feedback's and Using
        // crown's 100 ms after, only when turned on with the master on
        function test_03_vibration_samples() {
            open(["vibrationItem"])
            verify(Haptics.enabled, "the test database leaves touch haptics on")
            // the page passes the class by name: the enum reaches QML
            compare(Haptics.Touch, 0)
            compare(Haptics.Crown, 1)
            // the master, off -> on: vib_preview_master at once
            Backend.confSet(kVibration, false)
            wait(50)
            h.stamps = []
            h.tapName(this, "vibrationSwitch")
            compare(conf(kVibration), true)
            tryVerify(function () { return count("vib_preview_master") === 1 }, 1000, "the master's sample")
            var dt = stampOf("vib_preview_master") - h.written[kVibration]
            verify(dt >= 0 && dt < 50, "at once: " + dt + " ms")
            // on -> off: none
            h.stamps = []
            h.tapName(this, "vibrationSwitch")
            wait(300)
            compare(count("vib_preview_master"), 0)
            h.tapName(this, "vibrationSwitch")
            wait(200)
            // Touch feedback, off -> on: vib_preview_touch 100 ms later
            Backend.confSet(kTouch, false)
            wait(50)
            h.stamps = []
            h.tapName(this, "touchFeedbackSwitch")
            compare(conf(kTouch), true)
            tryVerify(function () { return count("vib_preview_touch") === 1 }, 1000, "the touch sample")
            // 100 ms after the switch; a QML Timer runs on the animation
            // clock, so it may end up to one 60 Hz frame (17 ms) either side
            dt = stampOf("vib_preview_touch") - h.written[kTouch]
            verify(dt >= 100 - 17 && dt < 400, "100 ms after the switch: " + dt + " ms")
            // on -> off: none
            h.stamps = []
            h.tapName(this, "touchFeedbackSwitch")
            wait(300)
            compare(count("vib_preview_touch"), 0)
            h.tapName(this, "touchFeedbackSwitch")
            wait(300)
            // Using crown, off -> on: vib_preview_crown 100 ms later, in the
            // crown class: it plays once Haptics has Using crown on
            Backend.confSet(kCrown, false)
            wait(50)
            h.stamps = []
            h.tapName(this, "crownHapticsSwitch")
            compare(conf(kCrown), true)
            console.log("Using crown in the dconf database: " + Haptics.crownEnabled)
            if (Haptics.crownEnabled) {
                tryVerify(function () { return count("vib_preview_crown") === 1 }, 1000, "the crown sample")
                dt = stampOf("vib_preview_crown") - h.written[kCrown]
                verify(dt >= 100 - 17 && dt < 400, "100 ms after the switch: " + dt + " ms")
            } else {
                // Haptics never sees Using crown on here (the mocks write
                // no dconf): the sample waits, then gives up after 1 s
                wait(1300)
                compare(count("vib_preview_crown"), 0)
            }
            // on -> off: none
            h.stamps = []
            h.tapName(this, "crownHapticsSwitch")
            wait(300)
            compare(count("vib_preview_crown"), 0)
            // apart from the samples only the switch rows' own toggle clicks play
            for (var i = 0; i < h.stamps.length; i++)
                verify(["ui_toggle_on", "ui_toggle_off"].indexOf(h.stamps[i].event) >= 0, h.stamps[i].event)
        }

        // Buttons: the rows in order, the keys, no holds
        function test_04_buttons_rows() {
            open(["buttonsItem"])
            compare(h.current().objectName, "buttonsPage")
            compare(h.find(h.current(), "settingsTitle").text, "Buttons")
            // mce without the crown wake: no Rotate crown to wake row
            compare(shownRows(h.current()),
                    ["row:Faster crown scrolling",
                     "text:Lists move farther with each turn of the crown",
                     "row:Side button",
                     "category:Chord press",
                     "row:Screenshot",
                     "text:Take a screenshot by pressing the crown and side button at the same time"])
            compare(chip("crownFastSwitch").control, "toggle")
            compare(chip("screenshotSwitch").control, "toggle")
            compare(chip("sideButtonItem").control, "none")
            // Faster crown scrolling: off = stock's speed
            h.tapName(this, "crownFastSwitch")
            compare(conf(kFast), false)
            verify(!chip("crownFastSwitch").checked)
            h.tapName(this, "crownFastSwitch")
            compare(conf(kFast), true)
            // Screenshot
            h.tapName(this, "screenshotSwitch")
            compare(conf(kShot), false)
            h.tapName(this, "screenshotSwitch")
            compare(conf(kShot), true)
            // no mode holds them
            setModes(true, true, true)
            verify(chip("crownFastSwitch").active)
            verify(chip("sideButtonItem").active)
            verify(chip("screenshotSwitch").active)
            compare(chip("crownFastSwitch").summary, "")
            compare(chip("sideButtonItem").summary, "Press & hold for Assistant")
        }

        // Rotate crown to wake: shown once mce knows the key; unset shows off
        function test_05_rotate_crown_to_wake() {
            mceWith(kRotary, -1)
            open(["buttonsItem"])
            compare(shownRows(h.current())[0], "row:Rotate crown to wake")
            var row = chip("rotaryWakeSwitch")
            compare(row.control, "toggle")
            verify(row.active)
            verify(!row.checked, "unset (-1) shows off")
            h.tapName(this, "rotaryWakeSwitch")
            compare(last("mce", kRotary).args, [true])
            verify(row.checked)
            h.tapName(this, "rotaryWakeSwitch")
            compare(last("mce", kRotary).args, [false])
            verify(!row.checked)
            // an int or a bool setting
            Backend.mceSet(kRotary, 1)
            verify(row.checked)
            Backend.mceSet(kRotary, 0)
            verify(!row.checked)
            Backend.mceSet(kRotary, true)
            verify(row.checked)
            // Bedtime and Theater hold it (Bedtime first), Battery saver does not
            setModes(true, true, false)
            verify(!row.active)
            verify(!row.checked)
            compare(row.summary, "Bedtime mode is on")
            setModes(false, true, false)
            compare(row.summary, "Theater mode is on")
            verify(!row.active)
            setModes(false, false, true)
            verify(row.active)
            compare(row.summary, "")
            verify(row.checked)
        }

        // Side button: the selection dialog with its message
        function test_06_side_button_dialog() {
            open(["buttonsItem"])
            h.tapName(this, "sideButtonItem")
            h.settle(this)
            var d = h.chooser()
            verify(d.shown)
            compare(d.title, "Side button")
            compare(d.message, "What the side button does")
            compare(d.options, ["Press & hold for Assistant", "Press for recent apps"])
            compare(d.currentIndex, 0)
            var list = h.find(d, "choiceList")
            compare(list.count, 2)
            h.tap(this, h.listItem(this, list, 1))
            compare(conf(kSide), "recents")
            tryVerify(function () { return !d.shown }, 2000, "closes after the choice")
            compare(chip("sideButtonItem").summary, "Press for recent apps")
            h.tapName(this, "sideButtonItem")
            h.settle(this)
            compare(h.chooser().currentIndex, 1)
            h.tap(this, h.listItem(this, h.find(h.chooser(), "choiceList"), 0))
            compare(conf(kSide), "assistant")
            tryVerify(function () { return !h.chooser().shown }, 2000)
            compare(chip("sideButtonItem").summary, "Press & hold for Assistant")
            // an unknown value shows the default
            Backend.confSet(kSide, "stock")
            compare(chip("sideButtonItem").summary, "Press & hold for Assistant")
        }

        // Display: Always-on screen with stock's question, and right under
        // it Always-on when off wrist, greyed and held with it
        function test_07_display_always_on_rows() {
            open(["displayItem"])
            var page = h.current()
            var at = indexIn(page, "aodSwitch")
            verify(at > 0)
            compare(indexIn(page, "aodOffWristSwitch"), at + 1)
            compare(indexIn(page, "aodOffWristCaption"), at + 2)
            compare(chip("aodSwitch").title, "Always-on screen")
            compare(chip("aodOffWristSwitch").title, "Always-on when off wrist")
            compare(chip("aodOffWristSwitch").control, "toggle")
            compare(chip("aodOffWristCaption").text, "Always-on screen stays on when watch is off wrist or charging")
            // the timeout row stays above (Go to watch face comes in between later)
            verify(indexIn(page, "timeoutItem") < at)
            // off wrist: off = stock (black 60 s off the wrist or charging)
            h.tapName(this, "aodOffWristSwitch")
            compare(conf(kOffWrist), false)
            verify(!chip("aodOffWristSwitch").checked)
            h.tapName(this, "aodOffWristSwitch")
            compare(conf(kOffWrist), true)
            // Always-on screen off: at once, no question; off wrist greyed
            h.tapName(this, "aodSwitch")
            verify(!dialog().shown)
            compare(conf(kAod), false)
            verify(!chip("aodOffWristSwitch").active)
            verify(chip("aodOffWristSwitch").checked, "greyed, showing its value")
            compare(chip("aodOffWristSwitch").summary, "")
            Backend.clearCalls()
            h.tapName(this, "aodOffWristSwitch")
            compare(writesOf(kOffWrist), 0)
            // on: stock's question
            h.tapName(this, "aodSwitch")
            verify(dialog().shown)
            compare(dialog().title, "Turn on always-on screen?")
            compare(dialog().message, "Always-on screen reduces battery life.")
            reject()
            compare(conf(kAod), false)
            h.tapName(this, "aodSwitch")
            accept()
            compare(conf(kAod), true)
            verify(chip("aodOffWristSwitch").active)
            // the modes hold both, with the same summary, showing off
            var holds = [[true, false, false, "Bedtime mode is on"],
                         [false, true, false, "Theater mode is on"],
                         [false, false, true, "Battery saver mode is on"]]
            for (var i = 0; i < holds.length; i++) {
                setModes(holds[i][0], holds[i][1], holds[i][2])
                verify(!chip("aodSwitch").active)
                verify(!chip("aodOffWristSwitch").active)
                compare(chip("aodSwitch").summary, holds[i][3])
                compare(chip("aodOffWristSwitch").summary, holds[i][3])
                verify(!chip("aodOffWristSwitch").checked)
            }
            setModes(false, false, false)
            verify(chip("aodOffWristSwitch").active)
            verify(chip("aodOffWristSwitch").checked)
            compare(chip("aodOffWristSwitch").summary, "")
        }

        // Date & time: Automatic time format, Use 24-hour format with the
        // 13:00 sample, the caption while the phone sets the format
        function test_08_date_time_rows() {
            Backend.confSet(k12h, true)
            open(["systemItem", "dateTimeItem"])
            compare(shownRows(h.current()),
                    ["row:Automatic time format", "row:Use 24-hour format",
                     "row:Set date", "row:Set time", "row:Set time zone"])
            compare(chip("autoTimeFormatSwitch").control, "toggle")
            compare(chip("hourFormatSwitch").control, "toggle")
            // 12 h: the switch off, 13:00 written as the time format writes it
            verify(!chip("hourFormatSwitch").checked)
            compare(chip("hourFormatSwitch").summary, "1:00 pm")
            compare(chip("setTimeItem").summary, "10:09 am")
            // the sample is not the clock
            Backend.now = new Date(2026, 10, 2, 15, 30, 0)
            compare(chip("hourFormatSwitch").summary, "1:00 pm")
            compare(chip("setTimeItem").summary, "3:30 pm")
            // 24 h
            h.tapName(this, "hourFormatSwitch")
            compare(conf(k12h), false)
            verify(chip("hourFormatSwitch").checked)
            compare(chip("hourFormatSwitch").summary, "13:00")
            compare(chip("setTimeItem").summary, "15:30")
            h.tapName(this, "hourFormatSwitch")
            compare(conf(k12h), true)
            compare(chip("hourFormatSwitch").summary, "1:00 pm")
            // Automatic time format on = stock: the phone's flag, the switch
            // gone, the caption last
            Backend.clearCalls()
            h.tapName(this, "autoTimeFormatSwitch")
            compare(conf(kAuto), true)
            compare(writesOf(k12h), 0)
            verify(chip("autoTimeFormatSwitch").checked)
            compare(shownRows(h.current()),
                    ["row:Automatic time format", "row:Set date", "row:Set time", "row:Set time zone",
                     "text:Time format managed by phone's settings"])
            // what the phone sets (btsyncd writes the key) shows at once
            Backend.confSet(k12h, false)
            compare(chip("setTimeItem").summary, "15:30")
            // off again: the switch is back with the phone's choice
            h.tapName(this, "autoTimeFormatSwitch")
            compare(conf(kAuto), false)
            verify(h.shown(chip("hourFormatSwitch")))
            verify(!h.shown(chip("hourFormatCaption")))
            verify(chip("hourFormatSwitch").checked)
            Backend.now = new Date(2026, 10, 2, 10, 9, 0)
        }

        // pictures for the review (copied to the package's shots/)
        function test_09_screens() {
            imageDefaults()
            open(["vibrationItem"])
            h.shot(this, "choices-01-vibration")
            h.scrollToEnd(this)
            h.shot(this, "choices-02-vibration-end")
            h.home(this)
            mceWith(kRotary, -1)
            open(["buttonsItem"])
            h.shot(this, "choices-03-buttons")
            h.scrollToEnd(this)
            h.shot(this, "choices-04-buttons-end")
            h.tapName(this, "sideButtonItem")
            h.settle(this)
            h.shot(this, "choices-05-side-button-dialog")
            h.back(this)
            h.home(this)
            open(["displayItem"])
            h.bringIntoView(this, chip("aodOffWristSwitch"))
            h.shot(this, "choices-06-display-always-on")
            h.tapName(this, "aodSwitch")
            h.tapName(this, "aodSwitch")
            h.settle(this)
            h.shot(this, "choices-07-always-on-question")
            reject()
            h.home(this)
            open(["systemItem", "dateTimeItem"])
            h.shot(this, "choices-08-date-time")
            h.tapName(this, "autoTimeFormatSwitch")
            h.scrollToEnd(this)
            h.shot(this, "choices-09-date-time-automatic")
        }
    }
}
