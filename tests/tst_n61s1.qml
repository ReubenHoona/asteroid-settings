/*
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * WO-61-S1 (the Wear OS 6 emulator's look for the Settings rows and page
 * frame, NEWLOOK-61 N61-38 ... N61-42 and the Settings part of N61-11),
 * measured on the rendered screen (384 x 384 inside the round mask of
 * SettingsHarness) where a number is about pixels. Screenshots go to
 * /tmp/n61s1-shots.
 */

import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls

SettingsHarness {
    id: h
    shots: "/tmp/n61s1-shots"

    TestCase {
        name: "SettingsN61S1"
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
        // the rows of a page's column that take part in the packing, top down
        function rowsOf(page) {
            var col = h.find(page, "settingsColumn")
            var out = []
            for (var i = 0; i < col.children.length; i++) {
                var c = col.children[i]
                if (c.visible && c.height > 0)
                    out.push(c)
            }
            out.sort(function (a, b) { return a.y - b.y })
            return out
        }
        // where a row is drawn on the screen (its transforms included)
        function drawnTop(item) { return item.mapToItem(h, 0, 0).y }
        function drawnBottom(item) { return item.mapToItem(h, 0, item.height).y }
        function scaleOf(item) { return (drawnBottom(item) - drawnTop(item)) / item.height }

        // N61-39: the rows of the Settings list shrink about their edge
        // nearest the middle and close up, 8 px apart at every scale
        function test_01_rows_packed() {
            var page = h.current()
            var f = h.find(page, "settingsFlickable")
            var rows = rowsOf(page)
            var hi = f.contentHeight - f.height
            var bestTop = null, bestBottom = null
            for (var y = 0; y <= hi; y += 2) {
                f.contentY = y
                wait(20)
                for (var i = 1; i < rows.length; i++) {
                    var b = drawnBottom(rows[i - 1]), t = drawnTop(rows[i])
                    if (b > 0 && t < 384)
                        near(t - b, 8, 1.01, "gap above row " + i + " at contentY " + y)
                    if (Math.abs(b - 74) < (bestBottom ? bestBottom.d : 2))
                        bestBottom = { d: Math.abs(b - 74), y: y, i: i - 1 }
                    if (Math.abs(t - 347) < (bestTop ? bestTop.d : 2))
                        bestTop = { d: Math.abs(t - 347), y: y, i: i }
                }
            }
            verify(bestBottom !== null && bestTop !== null, "rows reach y 74 and 347")
            // the emulator (N61-04): a row bottom at y 74 at 0.85 / 0.75
            f.contentY = bestBottom.y
            wait(50)
            var r = rows[bestBottom.i]
            near(drawnBottom(r), 74, 1, "row bottom")
            near(scaleOf(r), 0.85, 0.02, "scale at the top")
            near(r.contentAlpha, 0.75, 0.03, "alpha at the top")
            // it shrinks about its bottom: the next row 8 px under it
            near(drawnTop(rows[bestBottom.i + 1]) - drawnBottom(r), 8, 1, "gap under it")
            // the text keeps clear of the bezel: the label moves in with the row
            var lx = r.button.label.mapToItem(h, 0, 0).x
            verify(lx > 20 + 92, "the label at x " + lx + ", inside where it was")
            // a row top at y 347 at 0.75 / 0.58, 8 px under the row above
            f.contentY = bestTop.y
            wait(50)
            r = rows[bestTop.i]
            near(drawnTop(r), 347, 1, "row top")
            near(scaleOf(r), 0.75, 0.02, "scale at the bottom")
            near(r.contentAlpha, 0.58, 0.03, "alpha at the bottom")
            near(drawnTop(r) - drawnBottom(rows[bestTop.i - 1]), 8, 1, "gap above it")
            h.shot(this, "packed-main")
        }

        // the title's ink: first and last row, the first letter's rows, the
        // x range, the brightest pixel
        function lum(p) { return (p.r + p.g + p.b) / 3 }
        function titleInk(img) {
            var y0 = -1, y1 = -1, x0 = 999, x1 = -1, best = null
            for (var y = 45; y < 122; y++) {
                var any = false
                for (var x = 60; x < 324; x++) {
                    var p = img.pixel(x, y)
                    if (lum(p) > 0.35) {
                        any = true
                        x0 = Math.min(x0, x); x1 = Math.max(x1, x)
                        if (!best || lum(p) > lum(best))
                            best = p
                    }
                }
                if (any) { if (y0 < 0) y0 = y; y1 = y }
            }
            // the first letter (a capital): its own rows
            var c0 = -1, c1 = -1
            for (y = 45; y < 122; y++)
                for (x = x0; x < x0 + 10; x++)
                    if (lum(img.pixel(x, y)) > 0.35) { if (c0 < 0) c0 = y; c1 = y }
            return { top: y0, bottom: y1, left: x0, right: x1, capTop: c0, capBottom: c1, color: best }
        }
        // N61-40: the title as the Wear OS 6 emulator draws it on every
        // Settings page (S16-S23): cap top y 69, cap 21 px (a flat letter),
        // onSurface #E8E7EE, first row at y 123; 'Connectivity' 183 px wide
        function test_02_titles() {
            var pages = [[], ["connectivityItem"], ["displayItem"], ["batteryItem"], ["systemItem"],
                         ["systemItem", "languageItem"]]
            for (var i = 0; i < pages.length; i++) {
                h.home(this)
                open(pages[i])
                var page = h.current()
                var name = page.objectName
                wait(300)
                var img = grabImage(h)
                h.shot(this, "title-" + name)
                var ink = titleInk(img)
                near(ink.top, 69, 2, name + " title cap top")
                near(ink.capBottom - ink.capTop, 21, 1, name + " cap height")
                var c = ink.color
                // the brightest title pixel: the title is whole at rest but
                // for the edge effect's 0.99 (its box reaches y 123)
                near(c.r * 255, 232, 5, name + " title red")
                near(c.g * 255, 231, 5, name + " title green")
                near(c.b * 255, 238, 5, name + " title blue")
                verify(c.b > c.r && c.r > c.g - 0.01, name + " the onSurface hue")
                // the first row under it (a SettingsPage or a ChoiceList page)
                var first = name === "languagePage" ? h.listItem(this, h.find(page, "choiceList"), 0).children[0]
                                                    : rowsOf(page)[0]
                if (name === "languagePage") {
                    h.find(page, "choiceList").positionViewAtBeginning()
                    wait(100)
                }
                near(drawnTop(first), 123, 2, name + " first row top")
                if (name === "connectivityPage")
                    near(ink.right - ink.left + 1, 183, 3, "'Connectivity' width")
            }
            // a page with no title: the first row at y 84 (the emulator's Brightness, S24)
            var comp = Qt.createComponent(Qt.resolvedUrl("../src/qml/SettingsPage.qml"))
            var p = comp.createObject(h.app, { width: 384, height: 384 })
            compare(h.find(p, "settingsColumn").y, 84)
            verify(!h.find(p, "settingsTitle").visible)
            p.destroy()
        }
    }
}
