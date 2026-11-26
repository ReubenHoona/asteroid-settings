/*
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * WO-61-S2 (the Wear OS 6 emulator's look for the Settings page content,
 * NEWLOOK-61 N61-43 ... N61-46 and the Settings part of N61-15), measured
 * on the rendered screen (384 x 384 inside the round mask of
 * SettingsHarness) against the emulator's screenshots (S16, S17, S17-b,
 * S20, S24). Screenshots go to /tmp/n61s2-shots.
 */

import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls

SettingsHarness {
    id: h
    shots: "/tmp/n61s2-shots"

    TestCase {
        name: "SettingsN61S2"
        when: windowShown

        function init() { h.start(this) }

        function near(a, b, tol, what) {
            verify(Math.abs(a - b) <= (tol === undefined ? 0.5 : tol), what + ": " + a + " is not " + b)
        }
        function open(names) {
            for (var i = 0; i < names.length; i++) {
                h.tapName(this, names[i])
                h.settle(this)
            }
        }
        function lum(p) { return (p.r + p.g + p.b) / 3 }
        // a pixel of the screen as [r, g, b] in 0..255
        function rgbAt(img, x, y) {
            var p = img.pixel(Math.round(x), Math.round(y))
            return [p.r * 255, p.g * 255, p.b * 255]
        }
        function nearRgb(c, hex, tol, what) {
            var w = Qt.color(hex)
            var want = [w.r * 255, w.g * 255, w.b * 255]
            for (var k = 0; k < 3; k++)
                verify(Math.abs(c[k] - want[k]) <= tol,
                       what + ": " + c.map(Math.round) + " is not " + hex + " +- " + tol)
        }
        // the brightest pixel of an item's area on the screen
        function brightest(img, item) {
            var a = item.mapToItem(h, 0, 0), b = item.mapToItem(h, item.width, item.height)
            var best = null
            for (var y = Math.max(0, Math.round(a.y)); y < Math.min(384, Math.round(b.y)); y++)
                for (var x = Math.max(0, Math.round(a.x)); x < Math.min(384, Math.round(b.x)); x++) {
                    var p = img.pixel(x, y)
                    if (!best || lum(p) > lum(best))
                        best = p
                }
            return [best.r * 255, best.g * 255, best.b * 255]
        }
        // the box of the pixels brighter than thr in a part of the screen
        function inkBox(img, x0, y0, x1, y1, thr) {
            var box = { left: 999, right: -1, top: 999, bottom: -1 }
            for (var y = Math.max(0, Math.round(y0)); y < Math.min(384, Math.round(y1)); y++)
                for (var x = Math.max(0, Math.round(x0)); x < Math.min(384, Math.round(x1)); x++)
                    if (lum(img.pixel(x, y)) > thr) {
                        box.left = Math.min(box.left, x); box.right = Math.max(box.right, x)
                        box.top = Math.min(box.top, y); box.bottom = Math.max(box.bottom, y)
                    }
            box.width = box.right - box.left + 1
            box.height = box.bottom - box.top + 1
            return box
        }
        function drawnTop(item) { return item.mapToItem(h, 0, 0).y }
        // a row brought to the middle of the screen, its springs settled
        function settled(name) {
            var c = h.find(h.current(), name)
            verify(c !== null && h.shown(c), name)
            h.bringIntoView(this, c)
            wait(700)
            return c
        }
        // the first row from y0 down where the pixel at x is not black
        function firstLit(img, x, y0, y1) {
            for (var y = y0; y < y1; y++)
                if (lum(img.pixel(x, y)) > 0.05)
                    return y
            return -1
        }

        // N61-43: Brightness has no title and no header: the time, the
        // stepper pill from y 84, the Adaptive brightness row from y 196 (S24)
        function test_01_brightness_page() {
            open(["displayItem", "brightnessItem"])
            var page = h.current()
            compare(page.objectName, "brightnessPage")
            compare(page.title, "")
            verify(!h.shown(h.find(page, "settingsTitle")), "no title")
            compare(h.find(page, "brightnessHeader"), null)
            compare(h.findAll(page, function (o) { return h.typeName(o) === "SettingsCategory" }).length, 0,
                    "no header over the slider")
            var s = h.find(page, "brightnessSlider")
            var sw = h.find(page, "adaptiveSwitch")
            // the header's words are the slider's name for the screen reader
            compare(s.Accessible.name, sw.checked ? "Adaptive brightness" : "Fixed brightness")
            // adaptive brightness off, as S24
            if (sw.checked) {
                h.tapName(this, "adaptiveSwitch")
                wait(700)
            }
            compare(s.Accessible.name, "Fixed brightness")
            verify(/^\d+ percent screen brightness$/.test(s.valueDescription), s.valueDescription)
            compare(s.decreaseDescription, "Decrease brightness")
            h.find(page, "settingsFlickable").contentY = 0
            wait(500)
            near(drawnTop(s), 84, 2, "the pill top")
            near(drawnTop(sw), 196, 2, "the toggle row top")
            var img = grabImage(h)
            h.shot(this, "brightness")
            near(firstLit(img, 192, 60, 200), 84, 2, "the pill top on the screen")
            near(firstLit(img, 192, 190, 300), 196, 2, "the row top on the screen")
            // nothing drawn between the time and the pill
            var box = inkBox(img, 60, 45, 324, 83, 0.45)
            compare(box.right, -1, "no text between the time and the pill")
        }

        // N61-44: the battery header as the emulator draws it (S20): white
        // digits with their cap top at y 133, a flat 16 px bar at y 184-199
        // (white to the level on #3C4043 from x 48 to 335, no gap, no stop
        // dot), 'Charge remaining' #E8E7EE with its cap top at y 220, the
        // next row at y 268
        function test_02_battery_header() {
            open(["batteryItem"])
            var head = h.find(h.current(), "batteryHeader")
            var digits = h.find(head, "batteryPercent"), sign = h.find(head, "batteryPercentSign")
            var label = h.find(head, "batteryRemaining"), bar = h.find(head, "batteryBar")
            h.find(h.current(), "settingsFlickable").contentY = 0
            wait(500)
            near(drawnTop(head), 123, 1, "the header is the first row")
            var img = grabImage(h)
            h.shot(this, "battery-57")
            // the bar: 16 rows of the track at x 300, of the fill at x 100
            var rows = [], fill = []
            for (var y = 170; y < 215; y++) {
                var t = rgbAt(img, 300, y), f = rgbAt(img, 100, y)
                if (Math.abs(t[0] - 60) <= 3 && Math.abs(t[1] - 64) <= 3 && Math.abs(t[2] - 67) <= 3)
                    rows.push(y)
                if (f[0] > 250 && f[1] > 250 && f[2] > 250)
                    fill.push(y)
            }
            near(rows[0], 184, 1, "track top")
            near(rows[rows.length - 1], 199, 1, "track bottom")
            compare(rows.length, 16, "the track rows")
            compare(fill.length, 16, "the fill rows")
            near(fill[0], 184, 1, "fill top")
            var mid = 191
            // the fill: white from x 48 to 48 + 288 x 57 %
            var x0 = -1, x1 = -1, end = -1
            for (var x = 20; x < 364; x++) {
                var p = rgbAt(img, x, mid)
                if (p[0] > 240 && p[1] > 240 && p[2] > 240) {
                    if (x0 < 0) x0 = x
                    x1 = x
                }
                if (p[0] > 30 || p[1] > 30 || p[2] > 30)
                    end = x
            }
            near(x0, 48, 1, "fill from x 48")
            near(x1, 48 + Math.round(288 * 0.57) - 1, 1, "fill to the level")
            near(end, 335, 1, "track to x 335")
            // no gap after the fill, no stop dot at the end
            for (x = x1 + 2; x <= 330; x += 4)
                nearRgb(rgbAt(img, x, mid), "#3C4043", 3, "track at x " + x)
            nearRgb(rgbAt(img, 100, mid), "#FFFFFF", 3, "fill")
            // the digits and the % sign white, the digits' cap top at y 133
            nearRgb(brightest(img, digits), "#FFFFFF", 3, "digits")
            nearRgb(brightest(img, sign), "#FFFFFF", 3, "% sign")
            var d = inkBox(img, 40, 120, 160, 180, 0.5)
            near(d.top, 133, 1, "digits cap top")
            near(d.left, 48, 3, "digits from x 48")
            // the label: cap top 220, onSurface, from x 49
            var l = inkBox(img, 40, 205, 340, 236, 0.5)
            var c = inkBox(img, l.left, 205, l.left + 10, 250, 0.5)
            near(c.top, 220, 1, "label cap top")
            near(l.left, 49, 2, "label from x 49")
            nearRgb(brightest(img, label), "#E8E7EE", 4, "label onSurface")
            near(drawnTop(h.find(h.current(), "batterySaverItem")), 268, 1, "the next row")

            // 91 %, as S20: white to x 310
            Backend.batteryPercent = 91
            tryVerify(function () { return Math.abs(bar.progress - 0.91) < 0.001 }, 2000, "91 %")
            wait(100)
            img = grabImage(h)
            h.shot(this, "battery-91")
            x1 = -1
            for (x = 20; x < 364; x++) {
                p = rgbAt(img, x, mid)
                if (p[0] > 240 && p[1] > 240 && p[2] > 240)
                    x1 = x
            }
            near(x1, 310, 1, "91 %: white to x 310")
            // 2 %: a round dot, the bar's height
            Backend.batteryPercent = 2
            tryVerify(function () { return Math.abs(bar.progress - 0.02) < 0.001 }, 2000, "2 %")
            wait(100)
            img = grabImage(h)
            x1 = -1
            for (x = 20; x < 364; x++) {
                p = rgbAt(img, x, mid)
                if (p[0] > 200 && p[1] > 200 && p[2] > 200)
                    x1 = x
            }
            near(x1, 63, 1, "2 %: a 16 px dot")
        }

        // N61-45: Display, Sound, Vibration and System take the emulator's
        // glyphs (S16, S17, S17-b), primary #DBE2F9 in the 48 px slot from
        // x 48 (centre x 71.5), the label where it was (its first letter's
        // ink at x 112-114). Ink boxes of the emulator: Display 44 x 44,
        // Sound 36 x 34, Vibration 48 x 40 (two arcs at each side;
        // Material's watch_vibration has one, 44 px), System 40 x 40
        function test_03_list_glyphs() {
            var want = [["displayItem", "ms-brightness_medium", 44, 44, 3, 114],
                        ["soundItem", "ms-volume_up", 36, 34, 3, 113],
                        ["vibrationItem", "ms-watch_vibration-fill", 48, 40, 4, 112],
                        ["systemItem", "ms-info", 40, 40, 3, 113]]
            for (var i = 0; i < want.length; i++) {
                var c = settled(want[i][0])
                compare(c.iconName, want[i][1])
                var ic = h.findAll(c, function (o) { return h.typeName(o) === "Icon" })[0]
                compare(ic.width, 48)
                var a = ic.mapToItem(h, 0, 0)
                near(a.x, 48, 0.5, want[i][0] + " slot from x 48")
                var img = grabImage(h)
                h.shot(this, "glyph-" + want[i][0])
                var box = inkBox(img, a.x - 8, a.y - 8, a.x + 56, a.y + 56, 0.43)
                near(box.width, want[i][2], want[i][4], want[i][0] + " glyph width")
                near(box.height, want[i][3], 3, want[i][0] + " glyph height")
                near((box.left + box.right) / 2, 71.5, 1, want[i][0] + " glyph centre")
                nearRgb(brightest(img, ic), "#DBE2F9", 4, want[i][0] + " glyph colour")
                var lab = c.button.label.mapToItem(h, 0, 0)
                var t = inkBox(img, 100, lab.y, 300, lab.y + c.button.label.height, 0.6)
                near(t.left, want[i][5], 1, want[i][0] + " label x")
            }
        }

        // N61-46: System's Language row names the current language in its
        // second line, as the list names it ("English"), in primary
        // #DBE2F9, and follows a language chosen on the list
        function test_04_language_row() {
            open(["systemItem"])
            var page = h.current()
            var c = settled("languageItem")
            compare(c.summary, "English")
            var img = grabImage(h)
            h.shot(this, "system-language")
            nearRgb(brightest(img, c.button.secondaryLabel), "#DBE2F9", 4, "the second line in primary")
            // one list of languages for the app
            verify(page.languages === h.app.languageModel(), "System uses the app's languages")
            h.tapName(this, "languageItem")
            h.settle(this)
            var lp = h.current()
            compare(lp.objectName, "languagePage")
            verify(lp.langSettings === page.languages, "the list and the row share it")
            var list = h.find(lp, "choiceList")
            compare(list.textOf(list.currentIndex), "English")
            // Français: the row follows
            h.tap(this, h.listItem(this, list, 3))
            wait(300)
            compare(lp.langSettings.currentIndex, 3)
            h.back(this)
            h.settle(this)
            compare(h.current().objectName, "systemPage")
            compare(c.summary, "Français")
            // a language the list does not know: no second line
            Backend.languageIndex = -1
            compare(c.summary, "")
        }

        // N61-15: with the key unset, General > App view reads Grid view
        function test_05_app_view_default() {
            verify(!Backend.confHas("/desktop/asteroid/applauncher"), "the key is unset")
            open(["generalItem"])
            var c = settled("appViewItem")
            compare(c.summary, "Grid view")
            verify(h.current().grid)
            h.shot(this, "general-app-view")
        }
    }
}
