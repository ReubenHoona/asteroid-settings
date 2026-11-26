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
    }
}
