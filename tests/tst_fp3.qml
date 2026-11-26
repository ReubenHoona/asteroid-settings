/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * FP-S3 (new pages), on the mocks of tests/mocks (Backend records every
 * dconf write): Display > Color theme writes exactly the four theme keys of
 * qml-asteroid's Theme (theme/color-source, seed, accent, style; design-
 * tokens-08); Apps & notifications > Assistant > Tile actions removes a chip
 * of the Assistant tile (assistant/tile-actions, tiles-individual-25).
 * Screenshots go to /tmp/fp3-shots.
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
    }
}
