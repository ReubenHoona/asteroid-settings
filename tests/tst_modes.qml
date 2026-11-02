/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * The modes in Settings, as stock (STOCK-MODES.md) on the mocks of
 * tests/mocks: a setting a mode holds is greyed out, shown off, with the
 * mode as its summary (Bedtime, Theater, Battery saver, Extra dim);
 * Bedtime mode under Do Not Disturb; Battery saver on the Battery page
 * (asking first, greyed out on the charger) and suggested at low battery;
 * Extra dim and its intensity under Display. Screenshots of each go to
 * shots/settings/ as modes-*.png.
 */

import QtQuick
import QtTest
import SettingsTest

SettingsHarness {
    id: h

    TestCase {
        name: "Modes"
        when: windowShown

        readonly property string bedtimeKey: "/org/asteroidos/modes/bedtime"
        readonly property string theaterKey: "/org/asteroidos/modes/theater"
        readonly property string saverKey: "/org/asteroidos/modes/battery-saver"
        readonly property string extraDimKey: "/org/asteroidos/modes/extra-dim"
        readonly property string dndKey: "/org/asteroidos/notifications/do-not-disturb"

        function init() { h.start(this) }
        function dialog() { return h.find(h.app, "confirmDialog") }
        function accept() { h.tap(this, h.find(h.app, "dialogYes")); wait(50) }
        function conf(key) { return Backend.confGet(key) }
        function open(names) {
            for (var i = 0; i < names.length; i++) {
                h.tapName(this, names[i])
                h.settle(this)
            }
        }
        function chip(name) {
            var c = h.find(h.current(), name)
            verify(c !== null, name)
            return c
        }
        function held(name, summary) {
            var c = chip(name)
            verify(!c.active, name + " greyed out")
            compare(c.summary, summary, name + " summary")
            if (c.control === "toggle")
                verify(!c.checked, name + " shown off")
        }
        function test_01_bedtime_holds_display_and_gestures() {
            Backend.confSet(bedtimeKey, true)
            open(["displayItem"])
            held("brightnessItem", "Bedtime mode is on")
            held("aodSwitch", "Bedtime mode is on")
            verify(!h.shown(chip("aodBrightnessItem")), "no always-on brightness while it is held off")
            // a tap does nothing
            var calls = Backend.calls.length
            h.tap(this, chip("aodSwitch"))
            compare(Backend.calls.length, calls)
            compare(h.current().objectName, "displayPage")
            h.shot(this, "modes-01-display-bedtime")
            h.home(this)
            open(["gesturesItem"])
            held("tiltSwitch", "Bedtime mode is on")
            held("touchSwitch", "Bedtime mode is on")
            h.shot(this, "modes-02-gestures-bedtime")
            // over: back to the user's values
            Backend.confSet(bedtimeKey, false)
            wait(50)
            verify(chip("tiltSwitch").active && chip("tiltSwitch").checked)
            verify(chip("touchSwitch").active && chip("touchSwitch").checked)
            compare(chip("tiltSwitch").summary, "")
        }

        function test_02_theater_saver_extra_dim() {
            Backend.confSet(theaterKey, true)
            open(["gesturesItem"])
            held("tiltSwitch", "Theater mode is on")
            held("touchSwitch", "Theater mode is on")
            h.home(this)
            open(["displayItem"])
            held("aodSwitch", "Theater mode is on")
            verify(chip("brightnessItem").active, "Theater leaves the brightness")
            // Theater and Battery saver: Theater names it, as stock's order
            Backend.confSet(saverKey, true)
            wait(50)
            compare(chip("aodSwitch").summary, "Theater mode is on")
            Backend.confSet(theaterKey, false)
            wait(50)
            held("aodSwitch", "Battery saver mode is on")
            h.home(this)
            open(["gesturesItem"])
            held("tiltSwitch", "Battery saver mode is on")
            verify(chip("touchSwitch").active, "Battery saver leaves touch-to-wake")
            Backend.confSet(saverKey, false)
            h.home(this)
            // Extra dim holds the brightness only
            Backend.confSet(extraDimKey, true)
            open(["displayItem"])
            held("brightnessItem", "Extra dim is on")
            verify(chip("aodSwitch").active)
            compare(chip("extraDimItem").summary, "On")
            h.shot(this, "modes-03-display-extra-dim")
        }

        function test_03_extra_dim_page() {
            open(["displayItem", "extraDimItem"])
            compare(h.current().objectName, "extraDimPage")
            compare(chip("extraDimIntensity").summary, "Medium")
            h.tapName(this, "extraDimSwitch")
            compare(conf(extraDimKey), true)
            verify(chip("extraDimSwitch").checked)
            h.shot(this, "modes-04-extra-dim")
            h.tapName(this, "extraDimIntensity")
            h.settle(this)
            var list = h.find(h.current(), "choiceList")
            compare(list.count, 3)
            compare(list.currentIndex, 1)
            h.shot(this, "modes-05-extra-dim-intensity")
            h.tap(this, h.listItem(this, list, 2))
            h.settle(this)
            compare(conf("/org/asteroidos/modes/extra-dim-intensity"), 90)
            compare(chip("extraDimIntensity").summary, "High")
            h.tapName(this, "extraDimSwitch")
            compare(conf(extraDimKey), false)
            h.back(this)
            compare(chip("extraDimItem").summary, "Off")
            verify(chip("brightnessItem").active)
        }

        function test_04_bedtime_under_do_not_disturb() {
            open(["appsItem", "dndItem"])
            verify(h.shown(chip("bedtimeSwitch")))
            compare(chip("bedtimeSwitch").title, "Off")
            h.tapName(this, "bedtimeSwitch")
            compare(conf(bedtimeKey), true)
            compare(chip("bedtimeSwitch").title, "On")
            h.shot(this, "modes-06-dnd-bedtime")
            h.back(this)
            compare(chip("dndItem").summary, "Bedtime mode is on")
            h.tapName(this, "dndItem")
            h.settle(this)
            // Do Not Disturb on: the launcher's engine ends Bedtime (here: by hand)
            h.tapName(this, "dndSwitch")
            compare(conf(dndKey), true)
            Backend.confSet(bedtimeKey, false)
            wait(50)
            compare(chip("dndSwitch").title, "On")
            compare(chip("bedtimeSwitch").title, "Off")
            h.back(this)
            compare(chip("dndItem").summary, "On")
        }

        function test_05_battery_saver() {
            open(["batteryItem"])
            var sw = chip("batterySaverSwitch")
            verify(sw.active && !sw.checked)
            h.tap(this, sw)
            verify(dialog().visible)
            compare(dialog().title, "Turn on Battery Saver?")
            compare(dialog().message, "Turns off Always-on screen and Tilt-to-wake to extend battery life")
            h.shot(this, "modes-07-battery-saver-dialog")
            accept()
            compare(conf(saverKey), true)
            verify(sw.checked)
            h.shot(this, "modes-08-battery-saver")
            // off at once
            h.tap(this, sw)
            verify(!dialog().visible)
            compare(conf(saverKey), false)
            // on the charger: unchecked, greyed out
            Backend.confSet(saverKey, true)
            Backend.chargerType = 1
            wait(50)
            verify(!sw.active && !sw.checked)
        }

        function test_06_suggested_at_low_battery() {
            var s = h.find(h.current(), "batterySaverSuggestion")
            verify(!h.shown(s), "not at 57 %")
            Backend.batteryPercent = 14
            wait(50)
            verify(h.shown(s), "at 14 %")
            compare(s.title, "Battery saver")
            compare(s.summary, "Suggested")
            h.shot(this, "modes-09-settings-suggested")
            h.tap(this, s)
            compare(dialog().title, "Turn on Battery Saver?")
            accept()
            compare(conf(saverKey), true)
            verify(!h.shown(s), "gone once on")
            // on the charger: not suggested
            Backend.confSet(saverKey, false)
            Backend.chargerType = 1
            wait(50)
            verify(!h.shown(s))
        }
    }
}
