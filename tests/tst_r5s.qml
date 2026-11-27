/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * R5-settings, on the mocks of tests/mocks (Backend records every dconf,
 * mce and D-Bus write): the items of AUDIT-72 area C that Settings closes.
 * C-06 the adaptive brightness levels from dconf.
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
    }
}
