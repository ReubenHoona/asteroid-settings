/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * W2-settings-sound-vibration-modes, on the mocks of tests/mocks (Backend
 * records every dconf write; Nemo.Ngf's NonGraphicalFeedback records every
 * sample played or stopped): the Modes page and the Do Not Disturb, Bedtime
 * and Theater pages with their Customize pages (stock captions, switches,
 * defaults, keys), Sound (rows in stock order, the per-stream sliders and
 * their step sounds), Vibration (the three intensity sliders and their
 * previews, the silence row), the slider's haptic tick per step (the real
 * org.asteroid.controls Haptics), the deep links.
 */

import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls

SettingsHarness {
    id: h
    shots: "/tmp/w2svm-shots"

    // the haptic events that passed Haptics' switches, with the time
    property var stamps: []
    Connections {
        target: Haptics
        function onPlayed(event) {
            var l = h.stamps.slice()
            l.push({ "event": event, "t": Date.now() })
            h.stamps = l
        }
    }

    TestCase {
        name: "SoundVibrationModes"
        when: windowShown

        readonly property string mBase: "/org/asteroidos/modes/"
        readonly property string kBedtime: "/org/asteroidos/modes/bedtime"
        readonly property string kTheater: "/org/asteroidos/modes/theater"
        readonly property string kDnd: "/org/asteroidos/notifications/do-not-disturb"

        function init() {
            h.start(this)
            h.stamps = []
        }

        function chip(name) { return h.find(h.current(), name) }
        function conf(key) { return Backend.confGet(key) }
        function open(names) {
            for (var i = 0; i < names.length; i++) {
                h.tapName(this, names[i])
                h.settle(this)
            }
        }
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
        function title() { return h.find(h.current(), "settingsTitle").text }
        function plus(name) { h.tap(this, h.find(chip(name), "sliderPlus")) }
        function minus(name) { h.tap(this, h.find(chip(name), "sliderMinus")) }
        // the samples ngfd was asked for, "play:event" / "stop:event" in order
        function ngf() {
            var out = []
            for (var i = 0; i < Backend.calls.length; i++) {
                var c = Backend.calls[i]
                if (c.target === "ngf")
                    out.push(c.method + ":" + c.args[0])
            }
            return out
        }
        function plays() {
            return ngf().filter(function (s) { return s.indexOf("play:") === 0 })
                        .map(function (s) { return s.substring(5) })
        }
        function haptics() { return h.stamps.map(function (s) { return s.event }) }
        function writes(key) {
            var n = 0
            for (var i = 0; i < Backend.calls.length; i++)
                if (Backend.calls[i].target === "dconf" && Backend.calls[i].method === key)
                    n++
            return n
        }

        // ---- Modes (settings-a-01, modes-dnd-02)

        function test_01_modes_page() {
            // Apps & notifications no longer has Do Not Disturb
            open(["appsItem"])
            verify(h.find(h.current(), "dndItem") === null, "no Do Not Disturb row under Apps & notifications")
            h.home(this)
            open(["modesItem"])
            compare(h.current().objectName, "modesPage")
            compare(title(), "Modes")
            compare(shownRows(h.current()), ["row:Do Not Disturb", "row:Bedtime", "row:Theater"])
            var rows = ["modesDndItem", "modesBedtimeItem", "modesTheaterItem"]
            var icons = ["eos-settings-modes", "eos-settings-bedtime", "eos-settings-theater"]
            for (var i = 0; i < rows.length; i++) {
                compare(chip(rows[i]).summary, "", rows[i] + " has no summary")
                verify(String(chip(rows[i]).iconName).indexOf(icons[i]) >= 0, rows[i] + " icon " + chip(rows[i]).iconName)
            }
            h.shot(this, "w2-01-modes")
            var pages = [["modesDndItem", "dndPage", "Do Not Disturb"],
                         ["modesBedtimeItem", "bedtimePage", "Bedtime mode"],
                         ["modesTheaterItem", "theaterPage", "Theater mode"]]
            for (var j = 0; j < pages.length; j++) {
                h.tapName(this, pages[j][0])
                h.settle(this)
                compare(h.current().objectName, pages[j][1])
                compare(title(), pages[j][2])
                h.back(this)
            }
        }

        function test_02_mode_pages() {
            var specs = [
                { "row": "modesDndItem", "sw": "dndSwitch", "caption": "dndCaption", "text": "Silences watch to minimize interruptions",
                  "customize": "dndCustomize", "key": kDnd, "next": "dndCustomizePage", "ctitle": "Do Not Disturb", "shot": "w2-02-dnd" },
                { "row": "modesBedtimeItem", "sw": "bedtimeSwitch", "caption": "bedtimeCaption", "text": "Settle in for sleep",
                  "customize": "bedtimeCustomize", "key": kBedtime, "next": "bedtimeCustomizePage", "ctitle": "Bedtime mode", "shot": "w2-03-bedtime" },
                { "row": "modesTheaterItem", "sw": "theaterSwitch", "caption": "theaterCaption", "text": "Turns off screen and sounds completely",
                  "customize": "theaterCustomize", "key": kTheater, "next": "theaterCustomizePage", "ctitle": "Theater mode", "shot": "w2-04-theater" }
            ]
            for (var i = 0; i < specs.length; i++) {
                var s = specs[i]
                open(["modesItem", s.row])
                // the switch, its caption, Customize: nothing else (auto-bedtime is hidden)
                compare(shownRows(h.current()), ["row:Off", "text:" + s.text, "row:Customize"], s.row)
                compare(chip(s.sw).control, "toggle")
                verify(!chip(s.sw).checked)
                compare(chip(s.caption).text, s.text)
                // no dialog, writes the mode's key; the label follows
                h.tapName(this, s.sw)
                compare(conf(s.key), true, s.row)
                compare(chip(s.sw).title, "On")
                verify(chip(s.sw).checked)
                verify(!h.find(h.app, "confirmDialog").shown, "no dialog from the switch")
                h.shot(this, s.shot)
                h.tapName(this, s.sw)
                compare(conf(s.key), false)
                compare(chip(s.sw).title, "Off")
                // a change from elsewhere (the quick panel, the phone) shows at once
                Backend.confSet(s.key, true)
                compare(chip(s.sw).title, "On")
                Backend.confSet(s.key, false)
                h.tapName(this, s.customize)
                h.settle(this)
                compare(h.current().objectName, s.next)
                compare(title(), s.ctitle)
                h.home(this)
            }
        }

        function test_03_deep_links() {
            var cases = { "dnd": ["modesPage", "dndPage"], "bedtime": ["modesPage", "bedtimePage"],
                          "theater": ["modesPage", "theaterPage"],
                          "mode_do_not_disturb": ["modesPage", "dndPage"],
                          "mode_bedtime": ["modesPage", "bedtimePage"],
                          "mode_theater": ["modesPage", "theaterPage"],
                          "mode_bedtime_customize": ["modesPage", "bedtimePage", "bedtimeCustomizePage"],
                          "mode_theater_customize": ["modesPage", "theaterPage", "theaterCustomizePage"],
                          "mode_do_not_disturb_customize": ["modesPage", "dndPage", "dndCustomizePage"] }
            for (var k in cases) {
                Backend.confSet("/org/asteroidos/settings/ui/open", k + "@" + Date.now())
                wait(150)
                var names = []
                for (var i = 0; i < h.stack.layers.length; i++)
                    names.push(h.stack.layers[i].objectName)
                compare(names, cases[k], k)
            }
        }

        // ---- Customize (modes-dnd-03, settings-a-39)

        readonly property var customizeDefaults: ({
            "do-not-disturb": [true, true, true, true, true],
            "bedtime": [true, true, false, true, true],
            "theater": [false, false, false, false, true] })
        readonly property var customizeNames: ["starred", "repeat", "media", "alarm-sound", "alarm-vibrate"]
        readonly property var customizeSwitches: ["starredSwitch", "repeatSwitch", "mediaSwitch", "alarmSoundSwitch", "alarmVibrateSwitch"]

        function test_04_customize_pages() {
            var modes = [["do-not-disturb", "modesDndItem", "dndCustomize"],
                         ["bedtime", "modesBedtimeItem", "bedtimeCustomize"],
                         ["theater", "modesTheaterItem", "theaterCustomize"]]
            for (var m = 0; m < modes.length; m++) {
                var mode = modes[m][0]
                open(["modesItem", modes[m][1], modes[m][2]])
                var rows = ["category:What can notify you", "row:Starred callers", "row:Repeat callers", "row:Media sounds",
                            "category:Alarms and Timers", "row:Sound", "row:Vibrate"]
                // the caption follows Sound and Vibrate: both on at stock's defaults
                var def = customizeDefaults[mode]
                rows.push("text:" + (def[3] || def[4] ? "Individual app settings for sound and vibration still apply"
                                                       : "Alarms will activate silently"))
                if (mode === "bedtime") {
                    rows.push("category:Display options")
                    rows.push("row:Display options")
                }
                compare(shownRows(h.current()), rows, mode)
                // stock's defaults, and looking writes nothing
                for (var i = 0; i < 5; i++) {
                    compare(chip(customizeSwitches[i]).control, "toggle")
                    compare(chip(customizeSwitches[i]).checked, def[i], mode + " " + customizeNames[i] + " default")
                    compare(writes(mBase + mode + "/" + customizeNames[i]), 0)
                }
                // each switch writes its key and only its key
                for (var j = 0; j < 5; j++) {
                    var key = mBase + mode + "/" + customizeNames[j]
                    h.tapName(this, customizeSwitches[j])
                    compare(conf(key), !def[j], key)
                    compare(chip(customizeSwitches[j]).checked, !def[j])
                    h.tapName(this, customizeSwitches[j])
                    compare(conf(key), def[j], key + " back")
                }
                h.shot(this, "w2-05-customize-" + mode)
                h.home(this)
            }
        }

        function test_05_alarms_caption() {
            open(["modesItem", "modesTheaterItem", "theaterCustomize"])
            var cap = chip("alarmsCaption")
            // Theater: vibration only
            compare(cap.text, "Individual app settings for sound and vibration still apply")
            h.tapName(this, "alarmVibrateSwitch")
            compare(conf(mBase + "theater/alarm-vibrate"), false)
            compare(cap.text, "Alarms will activate silently")
            h.shot(this, "w2-06-customize-theater-silent")
            h.tapName(this, "alarmSoundSwitch")
            compare(cap.text, "Individual app settings for sound and vibration still apply")
            compare(conf(mBase + "theater/alarm-sound"), true)
            // each mode has its own keys
            compare(conf(mBase + "bedtime/alarm-sound"), undefined)
            compare(conf(mBase + "do-not-disturb/alarm-sound"), undefined)
        }

        function test_06_display_options() {
            var key = mBase + "bedtime/display-filter"
            open(["modesItem", "modesBedtimeItem", "bedtimeCustomize"])
            // stock: Nightlight is on for Bedtime on the Pixel Watch
            compare(chip("displayOptionsItem").summary, "Nightlight")
            h.tapName(this, "displayOptionsItem")
            h.settle(this)
            var d = h.chooser()
            verify(d.shown)
            compare(d.title, "Display options")
            compare(d.options, ["No color filter", "Grayscale", "Nightlight"])
            compare(d.summaries, ["", "", "Reduce blue light"])
            compare(d.currentIndex, 2)
            h.shot(this, "w2-07-display-options")
            var list = h.find(d, "choiceList")
            h.tap(this, h.listItem(this, list, 1))
            compare(conf(key), "grayscale")
            tryVerify(function () { return !d.shown }, 2000, "closes after the choice")
            compare(chip("displayOptionsItem").summary, "Grayscale")
            h.tapName(this, "displayOptionsItem")
            h.settle(this)
            compare(h.chooser().currentIndex, 1)
            h.tap(this, h.listItem(this, h.find(h.chooser(), "choiceList"), 0))
            compare(conf(key), "none")
            tryVerify(function () { return !h.chooser().shown }, 2000)
            compare(chip("displayOptionsItem").summary, "No color filter")
            // an unknown value shows the first
            Backend.confSet(key, "sepia")
            compare(chip("displayOptionsItem").summary, "No color filter")
        }

        // ---- Auto-bedtime (modes-dnd-18, the Settings half)

        function test_07_auto_bedtime() {
            var key = mBase + "auto-bedtime"
            open(["modesItem", "modesBedtimeItem"])
            verify(!h.shown(chip("autoEnterSwitch")), "hidden while nothing senses sleep")
            verify(!h.shown(chip("autoExitSwitch")))
            Backend.confSet(mBase + "auto-bedtime-supported", true)
            compare(shownRows(h.current()), ["row:Off", "text:Settle in for sleep", "row:Auto enter", "row:Auto exit",
                                             "text:Bedtime will turn on and exit automatically based on sleep sensing",
                                             "row:Customize"])
            verify(!chip("autoEnterSwitch").checked && !chip("autoExitSwitch").checked, "default off")
            compare(writes(key), 0)
            h.shot(this, "w2-08-bedtime-auto")
            // auto_bedtime_mode: 0 off, 1 both, 2 enter only, 3 exit only
            h.tapName(this, "autoEnterSwitch")
            compare(conf(key), 2)
            h.tapName(this, "autoExitSwitch")
            compare(conf(key), 1)
            verify(chip("autoEnterSwitch").checked && chip("autoExitSwitch").checked)
            h.tapName(this, "autoEnterSwitch")
            compare(conf(key), 3)
            verify(!chip("autoEnterSwitch").checked && chip("autoExitSwitch").checked)
            h.tapName(this, "autoExitSwitch")
            compare(conf(key), 0)
            // a value from elsewhere
            Backend.confSet(key, 2)
            verify(chip("autoEnterSwitch").checked && !chip("autoExitSwitch").checked)
        }

        // ---- Sound (settings-a-28, -29, -30, -31)

        function test_08_sound_rows() {
            open(["soundItem"])
            var expected = ["row:Mute ring & notifications",
                            "category:Ring volume", "slider:ringVolumeSlider",
                            "category:Notification volume", "slider:notificationVolumeSlider",
                            "category:Alarm volume", "slider:alarmVolumeSlider",
                            "row:Mute alarm",
                            "text:Silences alarm when Mute ring is enabled while worn. Watch will still vibrate",
                            "category:Media volume", "slider:volumeSlider",
                            "category:Call volume", "slider:callVolumeSlider",
                            "row:Screen unlocking sound", "row:Charging sounds"]
            compare(shownRows(h.current()), expected)
            // the defaults
            verify(chip("muteRingSwitch").checked, "muted by default (the engine's default)")
            compare(chip("muteRingSwitch").control, "toggle")
            verify(!chip("muteAlarmSwitch").checked)
            verify(chip("unlockSoundSwitch").checked)
            verify(chip("chargingSoundsSwitch").checked)
            var sl = [["ringVolumeSlider", 0, 7, 5], ["notificationVolumeSlider", 0, 7, 5],
                      ["alarmVolumeSlider", 0, 7, 6], ["callVolumeSlider", 1, 5, 4]]
            for (var i = 0; i < sl.length; i++) {
                var s = chip(sl[i][0])
                compare(s.from, sl[i][1], sl[i][0] + " from")
                compare(s.to, sl[i][2], sl[i][0] + " to")
                compare(s.stepSize, 1)
                compare(s.value, sl[i][3], sl[i][0] + " default")
                verify(!s.segmented, "volume sliders are plain, as stock")
            }
            compare(chip("volumeSlider").value, 70)
            compare(chip("volumeSlider").steps, 10)
            h.shot(this, "w2-09-sound-top")
            h.scrollToEnd(this)
            h.shot(this, "w2-10-sound-end")
        }

        function test_09_sound_switches() {
            open(["soundItem"])
            var cases = [["muteRingSwitch", "/org/asteroidos/sound/mute-ring-notifications", true],
                         ["muteAlarmSwitch", "/org/asteroidos/sound/mute-alarm", false],
                         ["unlockSoundSwitch", "/org/asteroidos/sound/screen-unlock", true],
                         ["chargingSoundsSwitch", "/org/asteroidos/sound/charging", true]]
            for (var i = 0; i < cases.length; i++) {
                compare(writes(cases[i][1]), 0, "looking writes nothing")
                h.tapName(this, cases[i][0])
                compare(conf(cases[i][1]), !cases[i][2], cases[i][0])
                compare(chip(cases[i][0]).checked, !cases[i][2])
                h.tapName(this, cases[i][0])
                compare(conf(cases[i][1]), cases[i][2], cases[i][0] + " back")
            }
        }

        function test_10_stream_sliders_write_percent() {
            open(["soundItem"])
            // ring 5 of 7 -> 6 -> 7 (percent of the maximum), then the end
            plus("ringVolumeSlider")
            compare(conf("/org/asteroidos/sound/ring-volume"), 86)
            compare(chip("ringVolumeSlider").value, 6)
            plus("ringVolumeSlider")
            compare(conf("/org/asteroidos/sound/ring-volume"), 100)
            compare(chip("ringVolumeSlider").value, 7)
            var n = writes("/org/asteroidos/sound/ring-volume")
            plus("ringVolumeSlider")
            compare(writes("/org/asteroidos/sound/ring-volume"), n, "no step past the maximum")
            minus("ringVolumeSlider")
            compare(conf("/org/asteroidos/sound/ring-volume"), 86)
            // notification 5 -> 4
            minus("notificationVolumeSlider")
            compare(conf("/org/asteroidos/sound/notification-volume"), 57)
            // alarm starts at 6 and never goes below 0 (config_audio_alarm_min_vol); call at 4 of 5, lowest 1
            for (var i = 0; i < 7; i++)
                minus("alarmVolumeSlider")
            compare(chip("alarmVolumeSlider").value, 0)
            compare(conf("/org/asteroidos/sound/alarm-volume"), 0)
            for (i = 0; i < 6; i++)
                minus("callVolumeSlider")
            compare(chip("callVolumeSlider").value, 1)
            compare(conf("/org/asteroidos/sound/call-volume"), 20)
            plus("callVolumeSlider")
            compare(conf("/org/asteroidos/sound/call-volume"), 40)
            // a stored percent between steps is shown at the nearest step
            Backend.confSet("/org/asteroidos/sound/ring-volume", 50)
            compare(chip("ringVolumeSlider").value, 4)
            Backend.confSet("/org/asteroidos/sound/ring-volume", 0)
            compare(chip("ringVolumeSlider").value, 0)
            // the main volume as before
            plus("volumeSlider")
            compare(Backend.find("pulse", "MainVolume2.CurrentStep").args, [80])
        }

        // ---- the step sounds (haptics-sounds-14)

        function test_11_step_sound_events() {
            open(["soundItem"])
            Backend.sampleMs = 300
            plus("volumeSlider")                       // 70 -> 80
            compare(plays(), ["volume_step"])
            // a stop comes first: one stream, one sample
            compare(ngf().slice(-2)[0].indexOf("stop:"), 0)
            wait(450)
            Backend.volume = 90
            plus("volumeSlider")                       // 90 -> 100: the maximum
            compare(plays(), ["volume_step", "volume_step_max"])
            wait(450)
            // the stream being changed names the event
            plus("ringVolumeSlider")                   // 5 -> 6
            minus("ringVolumeSlider")                  // 6 -> 5, waits while the first plays
            wait(1300)
            compare(plays().slice(2), ["volume_step_ring", "volume_step_ring"])
            wait(450)
            plus("ringVolumeSlider")                   // 5 -> 6
            plus("ringVolumeSlider")                   // 6 -> 7: the maximum
            wait(1300)
            verify(plays().indexOf("volume_step_max_ring") >= 0, "the ring maximum: " + plays())
            var spec = [["notificationVolumeSlider", "volume_step_notification"],
                        ["alarmVolumeSlider", "volume_step_alarm"],
                        ["callVolumeSlider", "volume_step_call"]]
            for (var i = 0; i < spec.length; i++) {
                wait(1300)
                var before = plays().length
                minus(spec[i][0])
                compare(plays().length, before + 1, spec[i][0])
                compare(plays()[before], spec[i][1])
            }
            // a press that moved nothing plays nothing (call is at 3: two steps to 1)
            for (i = 0; i < 2; i++) { wait(1300); minus("callVolumeSlider") }
            compare(chip("callVolumeSlider").value, 1)
            wait(1300)
            var n = plays().length
            minus("callVolumeSlider")
            wait(100)
            compare(plays().length, n, "no sample at the lowest step")
        }

        function test_12_step_sound_timing() {
            open(["soundItem"])
            // a long sample is cut after 2 s
            Backend.sampleMs = 6000
            var t0 = Date.now()
            plus("volumeSlider")
            compare(plays(), ["volume_step"])
            var stops = ngf().filter(function (s) { return s.indexOf("stop:") === 0 }).length
            tryVerify(function () { return ngf().filter(function (s) { return s.indexOf("stop:") === 0 }).length > stops }, 3000, "cut")
            var cut = Date.now() - t0
            verify(cut >= 1950 && cut < 2600, "cut after " + cut + " ms")
            // while a sample plays, the next step waits 1 s, and only the newest counts
            Backend.volume = 70
            wait(100)
            Backend.sampleMs = 6000
            plus("volumeSlider")
            var p0 = plays().length
            var t1 = Date.now()
            wait(150)
            plus("volumeSlider")
            wait(150)
            plus("volumeSlider")
            compare(plays().length, p0, "the later steps wait while a sample plays")
            wait(500)
            compare(plays().length, p0, "still waiting")
            tryVerify(function () { return plays().length > p0 }, 2500, "plays after the wait")
            var waited = Date.now() - t1
            // 1 s after the last step (about 300 ms in)
            verify(waited >= 1150 && waited < 2200, "waited " + waited + " ms after the first step")
            wait(1200)
            compare(plays().length, p0 + 1, "one sample for the steps taken while waiting")
            compare(plays()[p0], "volume_step_max", "the newest step reached the maximum")
        }

        // ---- the slider's haptic tick (haptics-sounds-04)

        function test_13_slider_haptics() {
            open(["soundItem"])
            h.stamps = []
            // ring 5 of 0..7: a step in the middle is the segment tick
            plus("ringVolumeSlider")                   // 6
            compare(haptics(), ["ui_segment_tick"])
            // onto the last value: gesture end (click)
            plus("ringVolumeSlider")                   // 7 = to
            compare(haptics(), ["ui_segment_tick", "ui_gesture_end"])
            // a press that moves nothing plays nothing (no more limit buzz)
            plus("ringVolumeSlider")
            plus("ringVolumeSlider")
            compare(haptics(), ["ui_segment_tick", "ui_gesture_end"])
            h.stamps = []
            // down from 7: 6 to 1 are ticks, 0 is the first value: gesture end
            for (var i = 0; i < 6; i++)
                minus("ringVolumeSlider")
            compare(haptics(), ["ui_segment_tick", "ui_segment_tick", "ui_segment_tick", "ui_segment_tick",
                                "ui_segment_tick", "ui_segment_tick"])
            minus("ringVolumeSlider")
            compare(haptics().length, 7)
            compare(haptics()[6], "ui_gesture_end")
            minus("ringVolumeSlider")
            compare(haptics().length, 7, "nothing below the first value")
            h.stamps = []
            // a slider whose first value is 0 (alarm, from 6): five ticks, then the end
            for (i = 0; i < 6; i++)
                minus("alarmVolumeSlider")
            compare(haptics(), ["ui_segment_tick", "ui_segment_tick", "ui_segment_tick", "ui_segment_tick", "ui_segment_tick",
                                "ui_gesture_end"])
        }

        // ---- Vibration (settings-a-33, -35, calls-14, haptics-sounds-19)

        function test_14_vibration_rows() {
            open(["vibrationItem"])
            compare(shownRows(h.current()), ["row:Silence watch while charging",
                "text:Notifications won't sound or vibrate while the watch is charging",
                "row:Vibration & haptics",
                "category:Ring vibration", "slider:ringVibrationSlider",
                "category:Notification vibration", "slider:notificationVibrationSlider",
                "category:Alarm vibration", "slider:alarmVibrationSlider",
                "category:Interactive haptics", "row:Touch feedback", "row:Using crown"])
            var names = ["ringVibrationSlider", "notificationVibrationSlider", "alarmVibrationSlider"]
            for (var i = 0; i < names.length; i++) {
                var s = chip(names[i])
                compare(s.from, 0)
                compare(s.to, 3)
                compare(s.stepSize, 1)
                compare(s.value, 3, names[i] + " default High")
                verify(s.active)
                verify(!s.segmented, "plain, as stock (Vibration: segmented false)")
            }
            h.shot(this, "w2-11-vibration")
            // each slider writes its own key; 0 = Off
            var keys = ["ring", "notification", "alarm"]
            for (i = 0; i < 3; i++) {
                var key = "/org/asteroidos/vibration/" + keys[i] + "-intensity"
                compare(writes(key), 0)
                minus(names[i])
                compare(conf(key), 2, keys[i])
                minus(names[i])
                compare(conf(key), 1)
                minus(names[i])
                compare(conf(key), 0)
                compare(chip(names[i]).value, 0)
                plus(names[i])
                compare(conf(key), 1)
            }
            // greyed while the master is off, showing the values
            h.tapName(this, "vibrationSwitch")
            compare(conf("/desktop/asteroid/vibration"), false)
            for (i = 0; i < 3; i++)
                verify(!chip(names[i]).active, names[i] + " greyed")
            compare(chip("ringVibrationSlider").value, 1)
            var n = writes("/org/asteroidos/vibration/ring-intensity")
            plus("ringVibrationSlider")
            compare(writes("/org/asteroidos/vibration/ring-intensity"), n, "a greyed slider writes nothing")
            h.tapName(this, "vibrationSwitch")
            verify(chip("ringVibrationSlider").active)
        }

        function test_15_vibration_previews() {
            open(["vibrationItem"])
            var spec = [["ringVibrationSlider", "vib_preview_ring"],
                        ["notificationVibrationSlider", "vib_preview_notification"],
                        ["alarmVibrationSlider", "vib_preview_alarm"]]
            for (var i = 0; i < spec.length; i++) {
                var before = plays().length
                minus(spec[i][0])                       // 3 -> 2
                tryVerify(function () { return plays().length > before }, 1000, spec[i][1])
                var key = "/org/asteroidos/vibration/" + spec[i][1].substring(12) + "-intensity"
                var dt = Backend.find("ngf", "play").t - Backend.find("dconf", key).t
                // 100 ms after the change (a QML Timer ticks on the 60 Hz animation clock)
                verify(dt >= 70 && dt < 400, spec[i][1] + " after " + dt + " ms")
                compare(plays()[before], spec[i][1])
                // a running preview is cancelled first
                compare(ngf().slice(-2)[0].indexOf("stop:"), 0)
                wait(300)
            }
            // quick steps: the last one plays, once
            var b = plays().length
            chip("ringVibrationSlider").stepBy(1)       // 2 -> 3
            chip("ringVibrationSlider").stepBy(-1)      // 3 -> 2, within 100 ms
            wait(500)
            compare(plays().length, b + 1, "one preview for steps within 100 ms")
            // level 0: no preview
            wait(300)
            b = plays().length
            minus("alarmVibrationSlider")               // 2 -> 1
            wait(400)
            compare(plays().length, b + 1)
            minus("alarmVibrationSlider")               // 1 -> 0
            wait(400)
            compare(plays().length, b + 1, "no preview for Off")
            compare(conf("/org/asteroidos/vibration/alarm-intensity"), 0)
            // master off: the sliders are greyed, nothing plays; back on it plays again
            h.tapName(this, "vibrationSwitch")
            b = plays().length
            plus("notificationVibrationSlider")
            wait(400)
            compare(plays().length, b, "no preview with the master off")
            h.tapName(this, "vibrationSwitch")
        }

        function test_16_silence_row() {
            open(["vibrationItem"])
            compare(chip("quietSwitch").title, "Silence watch while charging")
            compare(chip("quietCaption").text, "Notifications won't sound or vibrate while the watch is charging")
            h.tapName(this, "quietSwitch")
            compare(conf("/org/asteroidos/notifications/quiet-on-charger"), false)
            // once the watch knows when it is off the wrist: stock's title and caption
            Backend.confSet("/org/asteroidos/sensors/off-body-available", true)
            compare(chip("quietSwitch").title, "Silence when off wrist")
            compare(chip("quietCaption").text, "Notifications won't sound or vibrate when watch is off wrist or charging")
            verify(!chip("quietSwitch").checked)
            h.tapName(this, "quietSwitch")
            compare(conf("/org/asteroidos/notifications/quiet-on-charger"), true)
            h.shot(this, "w2-12-vibration-off-wrist")
        }
    }
}
