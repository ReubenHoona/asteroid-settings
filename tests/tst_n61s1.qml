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
        function rgb(c, hex, what) {
            var want = Qt.color(hex)
            verify(Math.abs(c.r - want.r) < 0.003 && Math.abs(c.g - want.g) < 0.003 && Math.abs(c.b - want.b) < 0.003,
                   what + ": " + c + " is not " + hex)
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

        // the text lines drawn in a band: [{ top, bottom, left, right }] of
        // the rows with ink brighter than thr, and the brightest pixel
        function lines(img, x0, x1, y0, y1, thr) {
            var out = [], run = null, best = null
            for (var y = Math.max(0, Math.round(y0)); y < Math.min(384, Math.round(y1)); y++) {
                var l = 999, r = -1
                for (var x = x0; x < x1; x++) {
                    var p = img.pixel(x, y)
                    if (lum(p) > thr) {
                        l = Math.min(l, x); r = Math.max(r, x)
                        if (!best || lum(p) > lum(best))
                            best = p
                    }
                }
                if (r >= 0) {
                    if (!run)
                        run = { top: y, bottom: y, left: l, right: r }
                    run.bottom = y; run.left = Math.min(run.left, l); run.right = Math.max(run.right, r)
                } else if (run) {
                    out.push(run)
                    run = null
                }
            }
            if (run)
                out.push(run)
            out.best = best
            return out
        }

        // N61-41: captions grey #9AA0A6, 13 sp on 28 px lines from x 49, the
        // first cap 12 px under the row above, the next row 14 px under the
        // last baseline (S20-b: row bottom 227, lines at 239 / 267 / 295,
        // last baseline 313, next row 327)
        function test_03_captions() {
            open(["batteryItem", "batterySaverItem"])
            compare(h.current().objectName, "batterySaverPage")
            var cap = h.find(h.current(), "batterySaverCaption")
            var above = h.find(h.current(), "batterySaverSwitch")
            var below = h.find(h.current(), "autoSaverOnSwitch")
            compare(cap.font.pixelSize, 26)
            compare(cap.fontInfo.styleName, "Medium")
            compare(cap.lineHeightMode, Text.FixedHeight)
            compare(cap.lineHeight, 28)
            compare(cap.color, Theme.color.caption)
            compare(cap.color.toString(), "#9aa0a6")
            wait(300)
            var img = grabImage(h)
            h.shot(this, "caption-battery-saver")
            // the first line: its cap top, its left edge, its colour
            var ls = lines(img, 30, 354, drawnTop(cap), drawnTop(cap) + 4 + 18, 0.3)
            verify(ls.length >= 1, "the first line is drawn")
            near(ls[0].top - drawnBottom(above), 12, 2, "first cap top under the row above")
            verify(ls[0].left >= 48 && ls[0].left <= 53, "the first line from x " + ls[0].left)
            // #9AA0A6 (at the edge effect's alpha: this caption is longer than
            // the emulator's and reaches into the bottom edge)
            var a = cap.opacity
            verify(a > 0.9, "almost whole at rest: " + a)
            near(ls.best.r * 255, 154 * a, 4, "caption red")
            near(ls.best.g * 255, 160 * a, 4, "caption green")
            near(ls.best.b * 255, 166 * a, 4, "caption blue")
            // the lines 28 px apart: each baseline the ascent under its line top
            var fm = Qt.createQmlObject('import QtQuick; FontMetrics {}', cap)
            fm.font = cap.font
            var lastBaseline = drawnTop(cap) + cap.topPadding + fm.ascent + (cap.lineCount - 1) * 28
            near(drawnTop(below) - lastBaseline, 14, 2, "next row under the last baseline")
            near(drawnBottom(cap) + 8, drawnTop(below), 1, "the list's 8 px")
            fm.destroy()
        }

        // the visible row before and after an item in its column
        function neighbours(item) {
            var rows = rowsOf(h.current())
            var i = rows.indexOf(item)
            return { above: i > 0 ? rows[i - 1] : null, below: i + 1 < rows.length ? rows[i + 1] : null }
        }

        // N61-41: sub-headers at x 52, 13 sp Medium, the cap 38 px under the
        // row above, the next row 22 px under the baseline (S21-d: row
        // bottom 223, 'N' 261-277; 'R' 82-98, the stepper from 120)
        function test_04_sub_headers() {
            open(["soundItem"])
            var cats = h.findAll(h.current(), function (o) { return h.typeName(o) === "SettingsCategory" && h.shown(o) })
            verify(cats.length > 0, "a sub-header on the Sound page")
            var cat = cats[0]
            var nb = neighbours(cat)
            verify(cat.hasOwnProperty("firstInPage"), "a SettingsCategory")
            verify(!cat.firstInPage)
            compare(cat.label.font.pixelSize, 26)
            compare(cat.label.fontInfo.styleName, "Medium")
            compare(cat.label.color, Theme.color.onSurface)
            compare(cat.textInset, 32)
            compare(cat.rowGap, 8)
            h.bringIntoView(this, nb.below)
            wait(300)
            var img = grabImage(h)
            h.shot(this, "subheader-sound")
            var ls = lines(img, 30, 354, drawnTop(cat), drawnBottom(cat), 0.45)
            compare(ls.length, 1)
            near(ls[0].left, 52, 1, "ink from x 52")
            // the first letter (a capital with a flat foot: M, R, N) from
            // its cap top to the baseline
            var r = lines(img, ls[0].left, ls[0].left + 4, drawnTop(cat), drawnBottom(cat), 0.45)
            near(r[0].bottom - r[0].top + 1, 18, 1, "cap height")
            near(r[0].top - drawnBottom(nb.above), 38, 2, "cap top under the row above")
            near(drawnTop(nb.below) - (r[0].bottom + 1), 22, 2, "next row under the baseline")
        }

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
        // a row brought to the middle of the screen, its springs settled
        function settled(name) {
            var c = h.find(h.current(), name)
            verify(c !== null && h.shown(c), name)
            h.bringIntoView(this, c)
            wait(700)
            return c
        }

        // N61-38: the Settings toggle row as the Wear OS 6 emulator draws it
        // (S18-b, S20-b, S20, S23-b)
        function test_05_toggle_rows() {
            // Display > Always-on screen, on: the checked gradient, the
            // tertiary thumb at x 309-334 (S18-b)
            open(["displayItem"])
            var c = settled("aodSwitch")
            if (!c.checked) {
                h.tap(this, c)
                wait(700)
            }
            verify(c.checked, "Always-on screen on")
            var sw = h.find(c, "chipSwitch")
            var y = c.mapToItem(h, 0, c.height / 2).y
            near(c.mapToItem(h, 0, 0).x, 20, 0.5, "a full-width row")
            near(sw.mapToItem(h, sw.width, 0).x, 336, 0.5, "the switch ends 28 px in from the row end")
            var img = grabImage(h)
            h.shot(this, "toggle-aod-on")
            nearRgb(rgbAt(img, 30, y), "#35363D", 4, "gradient at x 30")
            nearRgb(rgbAt(img, 355, y), "#646772", 4, "gradient at x 355")
            var t = sw._thumb.mapToItem(h, sw._thumb.width / 2, sw._thumb.height / 2)
            near(sw._thumb.mapToItem(h, 0, 0).x, 308, 1, "on thumb from x 309")
            nearRgb(rgbAt(img, t.x, t.y), "#D4C7FF", 4, "on thumb")
            nearRgb(rgbAt(img, sw.mapToItem(h, 4, 0).x, t.y), "#8985A1", 6, "on track")
            rgb(c.button.label.color, "#e8e7ee", "the label stays onSurface")

            // Battery > Battery Saver, off: the grey thumb at x 288-315 on a
            // 48 x 20 track (S20-b)
            h.home(this)
            open(["batteryItem"])
            var item = settled("batterySaverItem")
            img = grabImage(h)
            h.shot(this, "battery-summary")
            // the second line in primary: 'Will turn on at 10%' (S20)
            nearRgb(brightest(img, item.button.secondaryLabel), "#DBE2F9", 4, "second line primary")
            h.tapName(this, "batterySaverItem")
            h.settle(this)
            c = settled("batterySaverSwitch")
            verify(!c.checked, "Battery Saver off in the mocks")
            sw = h.find(c, "chipSwitch")
            compare(sw._track.width, 48)
            compare(sw._track.height, 20)
            img = grabImage(h)
            t = sw._thumb.mapToItem(h, sw._thumb.width / 2, sw._thumb.height / 2)
            near(sw._thumb.mapToItem(h, 0, 0).x, 288, 1, "off thumb from x 288")
            nearRgb(rgbAt(img, t.x, t.y), "#8B8B8F", 4, "off thumb")
            nearRgb(rgbAt(img, sw.mapToItem(h, sw.width - 4, 0).x, t.y), "#74757C", 6, "off track")
            y = c.mapToItem(h, 0, c.height / 2).y
            nearRgb(rgbAt(img, 30, y), "#2F3036", 3, "no gradient when off")

            // System > Date & time, automatic on: 'Set time' greyed (S23-b)
            h.home(this)
            open(["systemItem", "dateTimeItem"])
            c = settled("setTimeItem")
            verify(!c.active, "Set time is off while the time is automatic")
            img = grabImage(h)
            h.shot(this, "disabled-set-time")
            y = c.mapToItem(h, 0, c.height / 2).y
            nearRgb(rgbAt(img, 30, y), "#2F3036", 3, "the disabled container")
            nearRgb(brightest(img, c.button.label), "#80868B", 4, "the disabled label")
            nearRgb(brightest(img, c.button.secondaryLabel), "#80868B", 4, "the disabled second line")
        }
    }
}
