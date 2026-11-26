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
    }
}
