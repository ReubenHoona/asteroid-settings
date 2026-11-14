/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * W2-settings-battery-system, on the mocks of tests/mocks (Backend records
 * every dconf, mce and D-Bus write): Battery (header, rows, Battery Saver
 * page with the automatic on 15 % and off 25 %, Battery percentage, the rows
 * that wait for the charger driver), General, System (Input methods, the
 * language list, Disconnect & reset and its screen), Date & time (automatic
 * date, time and zone, greying, summaries, the time zone list, Set date
 * stores the picked date, Set time), System updates (check on open), About,
 * Versions, Developer options.
 */

import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls

SettingsHarness {
    id: h
    shots: "/tmp/w2bs-shots"

    TestCase {
        name: "SettingsBatterySystem"
        when: windowShown

        readonly property string kSaverAutoOn: "/org/asteroidos/modes/battery-saver-auto-on"
        readonly property string kSaverAutoOff: "/org/asteroidos/modes/battery-saver-auto-off"
        readonly property string kSaverOnLevel: "/org/asteroidos/modes/battery-saver-auto-on-level"
        readonly property string kSaver: "/org/asteroidos/modes/battery-saver"
        readonly property string kPercent: "/org/asteroidos/quickpanel/show-battery-percent"
        readonly property string kControl: "/org/asteroidos/battery/charge-control"
        readonly property string kHealth: "/org/asteroidos/battery/health-assistance"
        readonly property string kAdaptive: "/org/asteroidos/battery/adaptive-charging"
        readonly property string kAutoTime: "/org/asteroidos/settings/auto-time"
        readonly property string kAutoZone: "/org/asteroidos/settings/auto-time-zone"
        readonly property string kApp: "/desktop/asteroid/applauncher"
        readonly property string kInhibit: "/system/osso/dsm/display/inhibit_blank_mode"
        readonly property string kUnit: "org.freedesktop.systemd1.Manager.StartUnit"

        function init() {
            h.start(this)
            Backend.clearCalls()
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
        function units(unit) {
            var n = 0
            for (var i = 0; i < Backend.calls.length; i++)
                if (Backend.calls[i].method === kUnit && Backend.calls[i].args[0] === unit)
                    n++
            return n
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
                else if (c.hasOwnProperty("control") && c.hasOwnProperty("summary"))
                    out.push("row:" + c.title)
                else if (c.objectName === "batteryHeader")
                    out.push("header")
                else if (c.text !== undefined)
                    out.push("text:" + c.text)
            }
            return out
        }

        // ---- Battery (settings-b-11, settings-b-13, settings-b-01, charging-battery-20)

        function test_01_battery_header_and_rows() {
            open(["batteryItem"])
            compare(h.current().objectName, "batteryPage")
            compare(title(), "Battery")
            // the level in numeralSmall (30 sp = 60 px) with the % in titleLarge
            // (18 sp = 36 px), both onSurfaceVariant, and "Charge remaining" in
            // labelSmall (13 sp = 26 px) (BatteryStatusItemKt:80-81,202,270)
            var digits = chip("batteryPercent")
            var sign = chip("batteryPercentSign")
            var remaining = chip("batteryRemaining")
            compare(digits.text, "57")
            compare(sign.text, "%")
            compare(remaining.text, "Charge remaining")
            compare(digits.font.pixelSize, 60)
            compare(sign.font.pixelSize, 36)
            compare(remaining.font.pixelSize, 26)
            compare(digits.color.toString(), Theme.color.onSurfaceVariant.toString())
            compare(sign.color.toString(), Theme.color.onSurfaceVariant.toString())
            compare(remaining.color.toString(), Theme.color.onSurfaceVariant.toString())
            // no charger words, whatever the charger does
            Backend.batteryState = 1
            Backend.chargerType = 1
            wait(50)
            verify(chip("batteryStatus") === null)
            compare(shownRows(h.current()),
                    ["header", "row:Battery Saver", "row:Battery percentage",
                     "text:Show battery percentage in quick settings"])
            verify(chip("batteryHeader").y < chip("batterySaverItem").y)
            h.shot(this, "battery-01-page")
        }

        function test_02_battery_saver_summary() {
            open(["batteryItem"])
            // the automatic saver is on by default and the saver is off
            compare(chip("batterySaverItem").summary, "Will turn on at 15%")
            Backend.confSet(kSaver, true)
            compare(chip("batterySaverItem").summary, "")
            Backend.confSet(kSaver, false)
            compare(chip("batterySaverItem").summary, "Will turn on at 15%")
            Backend.confSet(kSaverAutoOn, false)
            compare(chip("batterySaverItem").summary, "")
            Backend.confSet(kSaverAutoOn, true)
            Backend.confSet(kSaverOnLevel, 20)
            compare(chip("batterySaverItem").summary, "Will turn on at 20%")
        }

        function test_03_battery_percentage_switch() {
            open(["batteryItem"])
            var sw = chip("batteryPercentSwitch")
            verify(sw.checked, "on by default (status_bar_show_battery_percent true)")
            verify(!Backend.confHas(kPercent), "the default is not written")
            h.tap(this, sw)
            compare(conf(kPercent), false)
            verify(!sw.checked)
            h.tap(this, sw)
            compare(conf(kPercent), true)
        }

        function test_04_battery_saver_page() {
            open(["batteryItem", "batterySaverItem"])
            compare(h.current().objectName, "batterySaverPage")
            compare(title(), "Battery Saver")
            compare(shownRows(h.current()),
                    ["row:Battery Saver",
                     "text:Limits background activity and turns off always-on-screen. Notifications may be delayed.",
                     "row:Turn on at 15%", "row:Turn off when charged",
                     "text:Battery Saver turns off when your watch charges above 25%"])
            // automatic on at 15 % and off above 25 %: both on by default
            verify(chip("autoSaverOnSwitch").checked)
            verify(chip("autoSaverOffSwitch").checked)
            verify(!chip("batterySaverSwitch").checked)
            verify(!Backend.confHas(kSaverAutoOn) && !Backend.confHas(kSaverAutoOff), "defaults are not written")
            h.shot(this, "battery-02-saver-page")
            // the switch toggles at once, no question
            h.tap(this, chip("batterySaverSwitch"))
            verify(!dialog().shown)
            compare(conf(kSaver), true)
            verify(chip("batterySaverSwitch").checked)
            h.tap(this, chip("batterySaverSwitch"))
            compare(conf(kSaver), false)
            // the automatic switches write the keys the modes engine reads
            h.tap(this, chip("autoSaverOnSwitch"))
            compare(conf(kSaverAutoOn), false)
            h.tap(this, chip("autoSaverOffSwitch"))
            compare(conf(kSaverAutoOff), false)
            h.tap(this, chip("autoSaverOnSwitch"))
            compare(conf(kSaverAutoOn), true)
            // on the charger the saver switch is greyed out and off
            Backend.confSet(kSaver, true)
            Backend.chargerType = 1
            wait(50)
            verify(!chip("batterySaverSwitch").active)
            verify(!chip("batterySaverSwitch").checked)
            // the levels follow the keys of the image
            Backend.confSet("/org/asteroidos/modes/battery-saver-auto-on-level", 10)
            Backend.confSet("/org/asteroidos/modes/battery-saver-auto-off-level", 90)
            compare(chip("autoSaverOnSwitch").title, "Turn on at 10%")
            compare(shownRows(h.current()).pop(), "text:Battery Saver turns off when your watch charges above 90%")
        }

        function test_05_saver_deep_link_and_main_list() {
            Backend.confSet("/org/asteroidos/settings/ui/open", "battery_saver@" + Date.now())
            wait(600)
            compare(h.current().objectName, "batterySaverPage")
            compare(h.stack.layers.length, 2)
            // no 'Suggested' chip in the main list at low battery (stock has none)
            h.home(this)
            Backend.batteryPercent = 12
            wait(50)
            verify(h.find(h.current(), "batterySaverSuggestion") === null)
        }

        function test_06_battery_rows_for_the_charger_driver() {
            open(["batteryItem"])
            // left out until the charger driver can limit charging
            verify(!h.shown(chip("batteryHealthSwitch")))
            verify(!h.shown(chip("chargingPrefsItem")))
            Backend.confSet(kControl, true)
            wait(50)
            compare(shownRows(h.current()),
                    ["header", "row:Battery Saver", "row:Battery percentage",
                     "text:Show battery percentage in quick settings",
                     "row:Battery health assistance",
                     "text:Helps to manage your battery's long term health by adjusting charging performance and capacity.",
                     "row:Charging preferences"])
            verify(chip("batteryHealthSwitch").checked, "on by default")
            h.tap(this, chip("batteryHealthSwitch"))
            compare(conf(kHealth), false)
            h.tapName(this, "chargingPrefsItem")
            h.settle(this)
            compare(h.current().objectName, "chargingPage")
            compare(title(), "Charging preferences")
            compare(shownRows(h.current()),
                    ["row:Adaptive charging",
                     "text:Extend battery lifespan by charging steadily during larger charging periods. Activated based on your usage cycle."])
            verify(!chip("adaptiveChargingSwitch").checked, "off by default")
            h.tap(this, chip("adaptiveChargingSwitch"))
            compare(conf(kAdaptive), true)
        }

        // ---- General (settings-b-15, status-indicators-09, setup-wizard-08, app-launcher-17)

        function test_07_general_rows() {
            open(["generalItem"])
            compare(h.current().objectName, "generalPage")
            compare(shownRows(h.current()),
                    ["row:Show unread notification indicator", "row:Autolaunch media controls",
                     "row:Start tutorial", "row:App view", "row:Temperature"])
            verify(chip("unreadDotSwitch").checked, "on by default")
            verify(!chip("autolaunchMediaSwitch").checked, "off by default")
            h.tap(this, chip("autolaunchMediaSwitch"))
            compare(conf("/org/asteroidos/ux/autolaunch-media"), true)
            h.shot(this, "general-01-page")
        }

        function test_08_app_view_list_or_grid() {
            open(["generalItem"])
            compare(chip("appViewItem").summary, "List view")
            h.tapName(this, "appViewItem")
            h.settle(this)
            var list = h.find(h.current(), "choiceList")
            compare(list.count, 2)
            compare(list.textOf(0), "List view")
            compare(list.textOf(1), "Grid view")
            h.shot(this, "general-02-app-view-dialog")
            h.tap(this, h.listItem(this, list, 1))
            wait(600)
            compare(conf(kApp), "file:///usr/share/asteroid-launcher/applauncher/007-wear-grid.qml")
            compare(chip("appViewItem").summary, "Grid view")
            h.tapName(this, "appViewItem")
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 0))
            wait(600)
            compare(conf(kApp), "file:///usr/share/asteroid-launcher/applauncher/006-wear-list.qml")
            compare(chip("appViewItem").summary, "List view")
        }

        function test_09_start_tutorial() {
            open(["generalItem"])
            var before = h.closeCount
            h.tapName(this, "startTutorialItem")
            verify(String(conf("/org/asteroidos/launcher/start-tutorial")).indexOf("tutorial@") === 0)
            tryCompare(h, "closeCount", before + 1)
        }

        // ---- System (settings-b-18, settings-b-20, setup-wizard-07)

        function test_10_system_rows() {
            open(["systemItem"])
            compare(shownRows(h.current()),
                    ["row:System updates", "row:Power off", "row:Restart", "row:Date & time",
                     "row:Input methods", "row:Language", "row:About", "row:Disconnect & reset"])
            // the Language row has no summary (the list names the current one)
            compare(chip("languageItem").summary, "")
            h.shot(this, "system-01-page")
        }

        function test_11_input_methods() {
            open(["systemItem", "inputMethodsItem"])
            compare(h.current().objectName, "inputMethodsPage")
            compare(title(), "Input methods")
            compare(shownRows(h.current()), ["row:Smart Reply", "row:Keyboard", "row:Handwriting", "row:Manage keyboards"])
            verify(chip("smartReplySwitch").checked, "show the reply chips by default")
            h.tap(this, chip("smartReplySwitch"))
            compare(conf("/org/asteroidos/notifications/smart-reply"), false)
            h.tapName(this, "manageKeyboardsItem")
            h.settle(this)
            compare(title(), "Manage keyboards")
            compare(shownRows(h.current()), ["category:Available virtual keyboard", "row:Keyboard", "row:Handwriting"])
            verify(chip("typingKeyboardSwitch").checked && chip("handwritingKeyboardSwitch").checked)
            h.tap(this, chip("handwritingKeyboardSwitch"))
            compare(conf("/org/asteroidos/keyboard/handwriting-enabled"), false)
            // the last keyboard that is on cannot be turned off
            verify(!chip("typingKeyboardSwitch").active)
            h.back(this)
            compare(shownRows(h.current()), ["row:Smart Reply", "row:Keyboard", "row:Manage keyboards"])
        }

        function test_12_language_list() {
            open(["systemItem", "languageItem"])
            var page = h.current()
            // the language in itself, the country in that language under it
            compare(page.nativeLanguage(0), "Deutsch")
            compare(page.nativeCountry(0), "Deutschland")
            compare(page.nativeLanguage(1), "English")
            compare(page.nativeCountry(1), "United Kingdom")
            compare(page.nativeLanguage(2), "Español")
            compare(page.nativeLanguage(3), "Français")
            compare(page.nativeCountry(3), "France")
            var list = h.find(page, "choiceList")
            compare(list.textOf(3), "Français")
            compare(list.summaryOf(3), "France")
            h.shot(this, "system-02-language")
        }

        function test_13_factory_reset_question() {
            open(["systemItem"])
            h.tapName(this, "factoryResetItem")
            verify(dialog().shown)
            compare(dialog().title, "Disconnect & reset?")
            // paired: the recommendation (stock has the app's name)
            compare(dialog().message, "This will reset watch to factory settings and delete all user data.\n\nIt's best to disconnect the watch using the Gadgetbridge app.")
            h.shot(this, "system-03-reset-question")
            reject()
            verify(!h.find(h.app, "factoryResetScreen").running)
            compare(units("eos-factory-reset-request.service"), 0)
            // no phone: only the first sentence
            Backend.btConnected = false
            h.tapName(this, "factoryResetItem")
            compare(dialog().message, "This will reset watch to factory settings and delete all user data.")
            reject()
        }

        function test_14_factory_reset_low_battery() {
            open(["systemItem"])
            Backend.batteryPercent = 29
            wait(50)
            h.tapName(this, "factoryResetItem")
            verify(dialog().infoOnly)
            compare(dialog().message, "Charge your watch to at least 30% to reset it.")
            accept()
            compare(units("eos-factory-reset-request.service"), 0)
            verify(!h.find(h.app, "factoryResetScreen").running)
            // on the charger it goes on at any level
            Backend.chargerType = 1
            wait(50)
            h.tapName(this, "factoryResetItem")
            verify(!dialog().infoOnly)
            reject()
            // 30 % is enough
            Backend.chargerType = 0
            Backend.batteryPercent = 30
            wait(50)
            h.tapName(this, "factoryResetItem")
            verify(!dialog().infoOnly)
            reject()
        }

        function test_15_factory_reset_screen() {
            open(["systemItem"])
            var screen = h.find(h.app, "factoryResetScreen")
            verify(!screen.visible)
            screen.holdMs = 300
            h.tapName(this, "factoryResetItem")
            accept()
            verify(screen.running && screen.visible)
            // the request to the root helper through its user unit
            compare(units("eos-factory-reset-request.service"), 1)
            compare(last("org.freedesktop.systemd1", kUnit).args, ["eos-factory-reset-request.service", "replace"])
            // the screen on and held, for the stock 30 s (here 300 ms), then released
            var mce = []
            for (var i = 0; i < Backend.calls.length; i++)
                if (Backend.calls[i].target === "com.nokia.mce")
                    mce.push(Backend.calls[i].method.replace("com.nokia.mce.request.", ""))
            compare(mce, ["req_display_state_on", "req_display_blanking_pause"])
            tryVerify(function () { return last("com.nokia.mce", "com.nokia.mce.request.req_display_cancel_blanking_pause") !== null }, 2000)
            // "Resetting...", titleLarge (or titleMedium), primaryDim, at most 2 lines, 89.6 % wide;
            // it fades in over 300 ms after 100 ms
            var t = screen.title
            compare(t.text, "Resetting...")
            compare(t.color.toString(), Theme.color.primaryDim.toString())
            compare(t.maximumLineCount, 2)
            verify(Math.abs(t.width - 0.896 * screen.width) < 1, "89.6 % wide")
            tryCompare(t, "opacity", 1, 2000)
            verify(t.font.pixelSize === Theme.type.titleLarge.pixelSize)
            h.shot(this, "system-04-resetting")
            // it takes every touch: the page under it cannot be reached
            var item = h.find(h.app, "dialogYes")
            var p = h.find(h.app, "factoryResetScreen")
            mouseClick(h, 192, 100)
            wait(100)
            verify(!dialog().shown)
            compare(units("eos-factory-reset-request.service"), 1)
            verify(p.running, "no way back")
        }

        // ---- Date & time (settings-b-24..27, dialogs-pickers-feedback-15)

        function test_16_date_time_rows_and_greying() {
            open(["systemItem", "dateTimeItem"])
            compare(h.current().objectName, "dateTimePage")
            compare(shownRows(h.current()),
                    ["row:Automatic date & time", "row:Automatic time zone", "row:Automatic time format",
                     "row:Use 24-hour format", "row:Set date", "row:Set time", "row:Set time zone"])
            // both automatic switches are on by default and grey the manual rows
            verify(chip("autoDateTimeSwitch").checked && chip("autoTimeZoneSwitch").checked)
            verify(!Backend.confHas(kAutoTime) && !Backend.confHas(kAutoZone))
            verify(!chip("setDateItem").active && !chip("setTimeItem").active && !chip("setZoneItem").active)
            h.shot(this, "datetime-01-automatic")
            h.tap(this, chip("autoDateTimeSwitch"))
            compare(conf(kAutoTime), false)
            verify(chip("setDateItem").active && chip("setTimeItem").active)
            verify(!chip("setZoneItem").active, "the zone follows its own switch")
            // connman stops taking the time from the network, as timed does it
            var set = Backend.calls.filter(function (c) { return c.target === "net.connman" })
            compare(set.length, 2)
            compare(set[0].method, "net.connman.Clock.SetProperty")
            compare(set[0].args[0], "TimeUpdates")
            compare(set[0].args[1].value, "manual")
            compare(set[1].args[0], "TimezoneUpdates")
            h.tap(this, chip("autoTimeZoneSwitch"))
            compare(conf(kAutoZone), false)
            verify(chip("setZoneItem").active)
            h.shot(this, "datetime-02-manual")
            // and back on: greyed again, the network sets the time
            h.tap(this, chip("autoDateTimeSwitch"))
            compare(conf(kAutoTime), true)
            verify(!chip("setDateItem").active)
            compare(Backend.find("net.connman", "net.connman.Clock.SetProperty").args[1].value, "auto")
        }

        function test_17_date_time_summaries() {
            open(["systemItem", "dateTimeItem"])
            var page = h.current()
            // Set date: the locale's long date without the weekday (mock clock 2 November 2026)
            compare(chip("setDateItem").summary, "2 November 2026")
            compare(page.longDate(new Date(2026, 10, 2), Qt.locale("en_US")), "November 2, 2026")
            compare(page.longDate(new Date(2026, 10, 2), Qt.locale("en_GB")), "2 November 2026")
            compare(page.longDate(new Date(2026, 10, 2), Qt.locale("de_DE")), "2. November 2026")
            // Set time zone: GMT+hh:mm, and the short name when it is not GMT-like
            compare(chip("setZoneItem").summary, "GMT+00:00")
            Backend.timezone = "Pacific/Auckland"
            page.zone = "Pacific/Auckland"
            compare(chip("setZoneItem").summary, "GMT+13:00 NZDT")
            page.zone = "Asia/Istanbul"
            compare(chip("setZoneItem").summary, "GMT+03:00")
            page.zone = "America/New_York"
            compare(chip("setZoneItem").summary, "GMT-05:00 EST")
        }

        function test_18_time_zone_list() {
            Backend.confSet(kAutoZone, false)
            open(["systemItem", "dateTimeItem", "setZoneItem"])
            var list = h.find(h.current(), "choiceList")
            // one flat list sorted by offset, then city; two lines: city and GMT+hh:mm
            var rows = []
            for (var i = 0; i < list.count; i++)
                rows.push(list.textOf(i) + "|" + list.summaryOf(i))
            compare(rows, ["Honolulu|GMT-10:00", "New York|GMT-05:00", "Abidjan|GMT+00:00", "London|GMT+00:00",
                           "Zulu|GMT+00:00", "Berlin|GMT+01:00", "Paris|GMT+01:00", "Istanbul|GMT+03:00",
                           "Auckland|GMT+13:00"])
            compare(h.find(h.current(), "dialogTitle"), null)
            // the current zone is marked
            compare(h.chooser().currentIndex, 3)
            h.shot(this, "datetime-03-time-zone-dialog")
            h.tap(this, h.listItem(this, list, 8))
            wait(700)
            compare(last("org.freedesktop.timedate1", "org.freedesktop.timedate1.SetTimezone").args, ["Pacific/Auckland", false])
            compare(h.current().objectName, "dateTimePage")
            compare(chip("setZoneItem").summary, "GMT+13:00 NZDT")
        }

        function test_19_set_date_stores_the_picked_date() {
            Backend.confSet(kAutoTime, false)
            open(["systemItem", "dateTimeItem", "setDateItem"])
            wait(300)
            var page = h.current()
            compare(page.objectName, "datePage")
            var picker = h.find(page, "datePicker")
            verify(picker !== null)
            // the bug: the day, month and year were set one after the other on today's
            // date, so 31 December on a day of a 30-day month rolled over to 1 December
            picker.setDate(new Date(2026, 11, 31), false)
            wait(400)
            compare(picker.selectedYear, 2026)
            compare(picker.selectedMonth, 12)
            compare(picker.selectedDay, 31)
            picker.accepted()
            var set = last("timedate1", "SetDate").args[0]
            compare(set.getFullYear(), 2026)
            compare(set.getMonth(), 11)
            compare(set.getDate(), 31)
            tryVerify(function () { return h.current().objectName === "dateTimePage" }, 3000)
        }

        function test_20_set_date_clamps_and_keeps_the_time() {
            Backend.confSet(kAutoTime, false)
            open(["systemItem", "dateTimeItem", "setDateItem"])
            wait(300)
            var page = h.current()
            // a day the month lacks never reaches the date (31 February 2027 -> 28 February)
            page.store(2027, 2, 31)
            var d = last("timedate1", "SetDate").args[0]
            compare([d.getFullYear(), d.getMonth(), d.getDate()], [2027, 1, 28])
            page.store(2028, 2, 31)
            d = last("timedate1", "SetDate").args[0]
            compare([d.getFullYear(), d.getMonth(), d.getDate()], [2028, 1, 29])
            page.store(2026, 11, 31)
            d = last("timedate1", "SetDate").args[0]
            compare([d.getFullYear(), d.getMonth(), d.getDate()], [2026, 10, 30])
            // the time of day stays as it was
            var now = new Date()
            verify(Math.abs(d.getHours() * 60 + d.getMinutes() - (now.getHours() * 60 + now.getMinutes())) <= 2)
            h.shot(this, "datetime-04-set-date")
        }

        function test_21_set_time_picker() {
            Backend.confSet(kAutoTime, false)
            Backend.confSet("/org/asteroidos/settings/use-12h-format", false)
            open(["systemItem", "dateTimeItem", "setTimeItem"])
            wait(300)
            var page = h.current()
            compare(page.objectName, "timePage")
            var picker = h.find(page, "timePicker")
            verify(picker !== null)
            verify(!picker.twelveHour, "24-hour format")
            picker.setTime(13, 45, 0, false)
            wait(400)
            picker.accepted()
            compare(last("timedate1", "SetTime").args, [13, 45])
            tryVerify(function () { return h.current().objectName === "dateTimePage" }, 3000)
            h.shot(this, "datetime-05-set-time-24h")
            // 12-hour: hours 01-12 and AM/PM; the picked time is still the 24-hour one
            Backend.confSet("/org/asteroidos/settings/use-12h-format", true)
            h.tapName(this, "setTimeItem")
            h.settle(this)
            wait(300)
            picker = h.find(h.current(), "timePicker")
            verify(picker.twelveHour, "12-hour format")
            picker.setTime(0, 5, 0, false)
            wait(400)
            picker.accepted()
            compare(last("timedate1", "SetTime").args, [0, 5])
            h.shot(this, "datetime-06-set-time-12h")
        }

        // ---- System updates (settings-b-19)

        function test_22_updates_checks_on_open() {
            open(["systemItem", "updatesItem"])
            compare(units("eos-update-check-request.service"), 1)
            // not again within the minute
            h.back(this)
            h.tapName(this, "updatesItem")
            h.settle(this)
            compare(units("eos-update-check-request.service"), 1)
            // the button retries
            h.back(this)
            h.tapName(this, "updatesItem")
            h.settle(this)
            var page = h.current()
            page.checking = false
            var btn = h.findAll(page, function (o) { return o.text === "Check for update" })
            verify(btn.length >= 1)
            h.tap(this, btn[0])
            compare(units("eos-update-check-request.service"), 2)
        }

        function test_23_updates_no_check_while_ready() {
            Backend.confSet("/org/asteroidos/eos-update/state", "staged")
            open(["systemItem", "updatesItem"])
            compare(units("eos-update-check-request.service"), 0)
        }

        // ---- About, Versions, Developer options (settings-b-21, -22, -23)

        function test_24_about_rows() {
            Backend.confSet("/org/asteroidos/eos-update/version", "44")
            open(["systemItem", "aboutItem"])
            compare(shownRows(h.current()),
                    ["row:AsteroidOS", "row:System version", "row:Model", "row:Device name", "row:Versions",
                     "row:Serial number", "row:Manufactured year", "row:Connection", "row:Battery",
                     "row:System licenses", "row:Legal notices"])
            // no status group, no uptime timer, no Wi-Fi address (stock has none)
            verify(chip("aboutManufactured").summary === "Unknown", "the mock serial does not start with a digit")
            compare(chip("aboutBattery").summary, "57%")
            var page = h.current()
            compare(page.manufacturedYear("3AB123"), "2023")
            compare(page.manufacturedYear("0X"), "2020")
            compare(page.manufacturedYear("X0"), "Unknown")
            compare(page.manufacturedYear(""), "Unknown")
            h.shot(this, "about-01-page")
            h.tapName(this, "legalNoticesItem")
            verify(dialog().shown && dialog().infoOnly)
            compare(dialog().title, "Legal notices")
            verify(dialog().message.indexOf("free software") >= 0)
            accept()
            h.tapName(this, "licensesItem")
            h.settle(this)
            compare(h.current().objectName, "licensesPage")
            compare(title(), "System licenses")
        }

        function test_25_versions_rows_and_toasts() {
            open(["systemItem", "aboutItem", "versionsItem"])
            compare(shownRows(h.current()), ["row:Build number", "row:System UI", "row:Kernel version", "row:Qt version"])
            compare(chip("systemUiItem").summary, "2.0+git0+0a1b2c3-r0")
            // already a developer: the notice only after more than 3 taps
            Backend.confSet("/org/asteroidos/settings/developer-options", true)
            var build = chip("buildItem")
            for (var i = 0; i < 3; i++)
                h.tap(this, build)
            verify(!toast().visible || toast().text === "", "no notice for taps 1-3")
            h.tap(this, build)
            compare(h.find(toast(), "toastText").text, "No need, you are already a developer.")
        }

        function test_26_developer_page() {
            Backend.confSet("/org/asteroidos/settings/developer-options", true)
            wait(500)
            open(["developerItem"])
            compare(title(), "Developer options")
            // Vibrate on connectivity change (stock order 30) came with W3-settings-connectivity
            compare(shownRows(h.current()), ["row:Use developer options", "row:Stay awake when charging", "row:Vibrate on connectivity change", "row:Restart to bootloader"])
            // off by default: mce keeps blanking
            verify(!chip("stayAwakeSwitch").checked)
            h.tap(this, chip("stayAwakeSwitch"))
            compare(Backend.mce[kInhibit], 1)
            verify(chip("stayAwakeSwitch").checked)
            h.tap(this, chip("stayAwakeSwitch"))
            compare(Backend.mce[kInhibit], 0)
            h.shot(this, "developer-01-page")
        }
    }
}
