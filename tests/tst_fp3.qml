/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * FP-S3 (new pages), on the mocks of tests/mocks (Backend records every
 * dconf write): Display > Color theme writes exactly the four theme keys of
 * qml-asteroid's Theme (theme/color-source, seed, accent, style; design-
 * tokens-08); Apps & notifications > Assistant > Tile actions removes a chip
 * of the Assistant tile (assistant/tile-actions, tiles-individual-25); an
 * app's Live updates switch writes ongoing/muted-apps (read by the
 * launcher's OngoingFeed). Screenshots go to /tmp/fp3-shots.
 */

import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls

SettingsHarness {
    id: h
    shots: "/tmp/fp3-shots"

    TestCase {
        name: "SettingsFp3"
        when: windowShown

        readonly property string kSource: "/org/asteroidos/theme/color-source"
        readonly property string kSeed: "/org/asteroidos/theme/seed"
        readonly property string kAccent: "/org/asteroidos/theme/accent"
        readonly property string kStyle: "/org/asteroidos/theme/style"
        readonly property string kActions: "/org/asteroidos/assistant/tile-actions"
        readonly property string kAssistant: "/org/asteroidos/assistant/enabled"
        readonly property string kOpen: "/org/asteroidos/settings/ui/open"
        readonly property string kMuted: "/org/asteroidos/ongoing/muted-apps"
        readonly property string kDisabled: "/org/asteroidos/notifications/disabled-apps"

        function init() {
            h.start(this)
            Backend.clearCalls()
        }
        // Theme is one for the whole run: No theme again after each test
        function cleanup() {
            if (Theme.colorSource !== "static")
                Theme.setColorTheme("static", "")
        }

        function chip(name) { return h.find(h.current(), name) }
        function conf(key) { return Backend.confGet(key) }
        function open(names) {
            for (var i = 0; i < names.length; i++) {
                h.tapName(this, names[i])
                h.settle(this)
            }
        }
        function title() { return h.find(h.current(), "settingsTitle").text }
        function accept() { h.tap(this, h.find(h.app, "dialogYes")); wait(50) }
        function reject() { h.tap(this, h.find(h.app, "dialogNo")); wait(50) }
        function dialogText() {
            return [h.find(h.app, "dialogTitle").text, h.find(h.app, "dialogMessage").text]
        }
        function rows(name) {
            return h.findAll(h.current(), function (o) { return o.objectName === name && h.shown(o) })
        }
        function titles(name) { return rows(name).map(function (r) { return r.title }) }
        function stackNames() { return h.stack.layers.map(function (l) { return l.objectName }) }
        function request(route) {
            Backend.confSet(kOpen, route + "@" + Date.now())
            wait(500)
            h.settle(this)
        }
        // what the page shows, top to bottom (as tst_w3ap.qml)
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
        function openApp(name) {
            var r = h.findAll(h.current(), function (o) { return o.title === name && o.hasOwnProperty("control") })
            verify(r.length > 0, "no row " + name)
            h.tap(this, r[0])
            h.settle(this)
        }
        // the dconf writes since the last clearCalls(): [[key, value], ...]
        function writes() {
            var out = []
            for (var i = 0; i < Backend.calls.length; i++)
                if (Backend.calls[i].target === "dconf")
                    out.push([Backend.calls[i].method, Backend.calls[i].args[0]])
            return out
        }

        // ---- design-tokens-08/settings-row: Display > Color theme

        // the four keys hold other values first, so each write shows
        function seedKeys(source) {
            Backend.confSet(kStyle, "vibrant")
            Backend.confSet(kAccent, "#123456")
            Backend.confSet(kSeed, "#ABCDEF")
            Backend.confSet(kSource, source)
            Backend.clearCalls()
        }

        // a tap writes the four keys of Theme.qml (style, accent, seed, then
        // the source, so the palette is made once) and nothing else
        function test_01_color_theme_writes_the_four_keys() {
            open(["displayItem", "colorThemeItem"])
            compare(h.current().objectName, "colorThemePage")
            var preset = Theme.colorPresets[1]
            seedKeys("watchface")
            h.tap(this, chip("colorTheme_" + preset.id))
            compare(JSON.stringify(writes()),
                    JSON.stringify([[kStyle, ""], [kAccent, ""], [kSeed, preset.seed], [kSource, "preset"]]))
            verify(chip("colorTheme_" + preset.id).checked)
            h.shot(this, "color-theme-preset")
            seedKeys("static")
            h.tap(this, chip("colorTheme_watchface"))
            compare(JSON.stringify(writes()),
                    JSON.stringify([[kStyle, ""], [kAccent, ""], [kSeed, ""], [kSource, "watchface"]]))
            verify(chip("colorTheme_watchface").checked)
            seedKeys("preset")
            h.tap(this, chip("colorTheme_static"))
            compare(JSON.stringify(writes()),
                    JSON.stringify([[kStyle, ""], [kAccent, ""], [kSeed, ""], [kSource, "static"]]))
            verify(chip("colorTheme_static").checked)
            // every value a string, as the keys are
            compare(typeof conf(kSource), "string")
            compare(typeof conf(kSeed), "string")
            compare(typeof conf(kAccent), "string")
            compare(typeof conf(kStyle), "string")
        }

        // every preset writes its own seed, and only the four keys
        function test_02_color_theme_every_row() {
            open(["displayItem", "colorThemeItem"])
            for (var i = 0; i < Theme.colorPresets.length; i++) {
                var p = Theme.colorPresets[i]
                seedKeys("watchface")
                h.tap(this, chip("colorTheme_" + p.id))
                compare(JSON.stringify(writes().map(function (x) { return x[0] })),
                        JSON.stringify([kStyle, kAccent, kSeed, kSource]), p.id)
                compare(conf(kSeed), p.seed, p.id)
                compare(conf(kSource), "preset", p.id)
                compare(conf(kStyle), "", p.id)
                compare(conf(kAccent), "", p.id)
            }
        }

        // ---- tiles-individual-25: Apps & notifications > Assistant > Tile actions

        function test_03_tile_actions_remove() {
            open(["appsItem", "assistantItem", "tileActionsItem"])
            compare(h.current().objectName, "tileActionsPage")
            compare(title(), "Tile actions")
            // unset: the three chips the tile always had, in its order
            compare(titles("tileActionItem"),
                    ["What's the weather?", "Set a timer for 5 minutes", "When is my next alarm?"])
            compare(chip("tileActionsCaption").text, "Tap an action to remove it from the Assistant tile")
            h.shot(this, "tile-actions")
            // a tap asks first; No keeps the list
            Backend.clearCalls()
            h.tap(this, rows("tileActionItem")[1])
            h.settle(this)
            compare(dialogText(), ["Remove action?", "Set a timer for 5 minutes"])
            reject()
            h.settle(this)
            compare(writes().length, 0)
            // Yes: the rest goes to the key, the launcher's list
            h.tap(this, rows("tileActionItem")[1])
            h.settle(this)
            accept()
            h.settle(this)
            compare(writes().length, 1)
            compare(writes()[0][0], kActions)
            compare(conf(kActions), ["What's the weather?", "When is my next alarm?"])
            compare(titles("tileActionItem"), ["What's the weather?", "When is my next alarm?"])
            // the last one gone: the launcher's mark for no action
            for (var i = 0; i < 2; i++) {
                h.tap(this, rows("tileActionItem")[0])
                h.settle(this)
                accept()
                h.settle(this)
            }
            compare(conf(kActions), ["@none"])
            compare(titles("tileActionItem"), [])
            compare(chip("tileActionsCaption").text, "No actions. Add one on the Assistant tile")
            h.shot(this, "tile-actions-none")
        }

        function test_04_tile_actions_stored_list() {
            // the launcher's parse: blanks, marks and repeats (any case) dropped
            Backend.confSet(kActions, ["Call home", " ", "call HOME", "Set a 5 minute timer", "@default"])
            open(["appsItem", "assistantItem", "tileActionsItem"])
            compare(titles("tileActionItem"), ["Call home", "Set a 5 minute timer"])
            h.tap(this, rows("tileActionItem")[0])
            h.settle(this)
            accept()
            h.settle(this)
            compare(conf(kActions), ["Set a 5 minute timer"])
            // a change made on the tile shows at once
            Backend.confSet(kActions, ["Send a message", "Set a 5 minute timer"])
            compare(titles("tileActionItem"), ["Send a message", "Set a 5 minute timer"])
            // the route: Apps & notifications, Assistant, Tile actions
            request("tile_actions")
            compare(stackNames(), ["appsPage", "assistantPage", "tileActionsPage"])
            compare(conf(kOpen), "")
            // the row greys with the Assistant off, as the others
            h.back(this)
            verify(chip("tileActionsItem").active)
            Backend.confSet(kAssistant, false)
            verify(!chip("tileActionsItem").active)
        }

        // ---- note: Settings per-app Live updates switch (ongoing/muted-apps)

        function test_05_live_updates_switch() {
            open(["appsItem", "notificationsItem", "appNotificationsItem"])
            openApp("Stopwatch")
            compare(h.current().objectName, "appNotificationPage")
            compare(shownRows(h.current()), ["category:Stopwatch", "row:On", "category:Live updates", "row:On",
                                             "text:Display ongoing, time-sensitive notifications on the watch face"])
            var sw = chip("liveUpdatesSwitch")
            verify(sw.checked)
            h.shot(this, "live-updates")
            // Off: the desktop id goes to the launcher's list, and only that
            Backend.clearCalls()
            h.tap(this, sw)
            compare(JSON.stringify(writes()), JSON.stringify([[kMuted, ["asteroid-stopwatch"]]]))
            verify(!sw.checked)
            compare(sw.title, "Off")
            // the app's notifications switch stays on: a separate key
            verify(chip("appNotificationSwitch").checked)
            h.tap(this, sw)
            compare(conf(kMuted), [])
            compare(sw.title, "On")
            compare(conf(kDisabled), undefined)
            // the others in the list stay; a ".desktop" entry (the chip's long
            // press may write one) counts as the app
            Backend.confSet(kMuted, ["asteroid-timer", " asteroid-stopwatch.desktop"])
            verify(!sw.checked)
            h.tap(this, sw)
            compare(conf(kMuted), ["asteroid-timer"])
            h.tap(this, sw)
            compare(conf(kMuted), ["asteroid-timer", "asteroid-stopwatch"])
        }

        function test_06_live_updates_only_for_ongoing_apps() {
            Backend.confSet("/org/asteroidos/notifications/known-apps", ["com.example.chat|Chat"])
            open(["appsItem", "notificationsItem", "appNotificationsItem"])
            var ongoing = ["Alarm clock", "Timer", "Stopwatch", "Exercise"]
            var ids = ["asteroid-alarmclock", "asteroid-timer", "asteroid-stopwatch", "asteroid-exercise"]
            for (var i = 0; i < ongoing.length; i++) {
                openApp(ongoing[i])
                verify(h.shown(chip("liveUpdatesSwitch")), ongoing[i])
                h.tap(this, chip("liveUpdatesSwitch"))
                compare(conf(kMuted), [ids[i]], ongoing[i])
                h.tap(this, chip("liveUpdatesSwitch"))
                h.back(this)
            }
            var plain = ["Assistant", "System updates", "Battery", "Bluetooth", "Chat"]
            for (var j = 0; j < plain.length; j++) {
                openApp(plain[j])
                verify(!h.shown(chip("liveUpdatesSwitch")), plain[j])
                verify(!h.shown(chip("liveUpdatesCategory")), plain[j])
                verify(!h.shown(chip("liveUpdatesCaption")), plain[j])
                h.back(this)
            }
        }
    }
}
