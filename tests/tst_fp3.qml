/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * FP-S3 (new pages), on the mocks of tests/mocks (Backend records every
 * dconf write): Display > Color theme writes exactly the four theme keys of
 * qml-asteroid's Theme (theme/color-source, seed, accent, style; design-
 * tokens-08). Screenshots go to /tmp/fp3-shots.
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
    }
}
