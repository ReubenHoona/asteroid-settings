/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * W1-settings-structure: the Settings frame as stock CP3A, on the mocks of
 * tests/mocks (Backend records every dconf write): the main list in stock
 * order with its icons, the stub pages, the TimeText, the M3 rows (navigation,
 * switch, radio, disabled, information), the page title and category
 * headers, captions, the slider, the selection dialog, the confirmation and
 * the toast, and the deep-link table. Every number is the stock one in px
 * on the 384 px Pixel Watch 2 (2 px per dp); the sources are cited in the
 * QML files.
 */

import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls

SettingsHarness {
    id: h

    TestCase {
        name: "Structure"
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
        function chip(name) { return h.find(h.current(), name) }
        function chipsOf(page) {
            return h.findAll(page, function (o) {
                return o.hasOwnProperty("control") && o.hasOwnProperty("clickable") && o.hasOwnProperty("summary")
            })
        }
        function titlesShown(page) {
            var out = []
            var chips = chipsOf(page)
            for (var i = 0; i < chips.length; i++)
                if (h.shown(chips[i]))
                    out.push(chips[i].title)
            return out
        }
        function open(names) {
            for (var i = 0; i < names.length; i++) {
                h.tapName(this, names[i])
                h.settle(this)
            }
        }
        function request(page, age) {
            Backend.confSet("/org/asteroidos/settings/ui/open", page + "@" + (Date.now() - (age || 0)))
            wait(150)
        }
        function stackNames() {
            var out = []
            for (var i = 0; i < h.stack.layers.length; i++)
                out.push(h.stack.layers[i].objectName)
            return out
        }
        function waitClosed(d) {
            tryVerify(function () { return !d.shown }, 2000, "the dialog closes")
            tryVerify(function () { return !d.active }, 2000, "the dialog has left")
        }

        // settings-a-03, settings-a-05, settings-a-07: the paired main list
        function test_01_main_list_in_stock_order() {
            compare(h.current().objectName, "mainPage")
            compare(titlesShown(h.current()),
                    ["Connectivity", "Display", "Gestures", "Buttons", "Apps & notifications", "Modes",
                     "Sound", "Vibration", "Battery", "General", "System"])
            // no Watch face & style (settings-a-03 / face-interaction-30)
            compare(h.find(h.current(), "styleItem"), null)
            // the stock slots of the stub pages, hidden until they have rows
            var order = ["connectivityItem", "displayItem", "gesturesItem", "buttonsItem", "appsItem", "modesItem",
                         "soundItem", "vibrationItem", "batteryItem", "generalItem", "healthProfileItem",
                         "locationItem", "safetyItem", "accessibilityItem", "securityItem", "systemItem",
                         "developerItem"]
            var col = h.find(h.current(), "settingsColumn")
            var last = -1
            for (var i = 0; i < order.length; i++) {
                var c = h.find(col, order[i])
                verify(c !== null, order[i])
                var at = -1
                for (var k = 0; k < col.children.length; k++)
                    if (col.children[k] === c)
                        at = k
                verify(at > last, order[i] + " after the one before it")
                last = at
            }
            var hidden = ["healthProfileItem", "locationItem", "safetyItem", "accessibilityItem", "securityItem"]
            for (i = 0; i < hidden.length; i++)
                verify(!h.shown(chip(hidden[i])), hidden[i] + " hidden until its page has rows")
            compare(chip("healthProfileItem").title, "Health profile")
            compare(chip("safetyItem").title, "Safety & Emergency")
            // the icons drawn to the stock shapes (System is a gear, not an info circle)
            var icons = { "connectivityItem": "eos-settings-connectivity", "gesturesItem": "eos-settings-gestures",
                          "buttonsItem": "eos-settings-buttons", "modesItem": "eos-settings-modes",
                          "batteryItem": "eos-settings-battery", "systemItem": "eos-settings-system",
                          "locationItem": "eos-settings-location", "accessibilityItem": "eos-settings-accessibility",
                          "securityItem": "eos-settings-security" }
            for (var n in icons)
                compare(chip(n).iconName, "../../asteroid-settings/icons/" + icons[n])
            compare(chip("displayItem").iconName, "ios-sunny-outline")
            // the icon files exist and are drawn in primary: pale pixels in
            // the 52 px icon square on the screen
            for (n in icons) {
                var c2 = chip(n)
                var xhr = new XMLHttpRequest()
                xhr.open("GET", Qt.resolvedUrl("../src/icons/" + icons[n] + ".svg"), false)
                xhr.send()
                verify(xhr.responseText.indexOf("<svg") === 0, icons[n] + ".svg")
                if (!h.shown(c2))
                    continue
                h.bringIntoView(this, c2)
                wait(100)
                var ic = h.findAll(c2, function (o) { return h.typeName(o) === "Icon" })[0]
                compare(ic.width, 52)
                rgb(ic.color, "#dbe2f9", n + " icon colour")
                var at = ic.mapToItem(h, 0, 0)
                var img = grabImage(h)
                var lit = 0
                for (var yy = 0; yy < 52; yy += 2)
                    for (var xx = 0; xx < 52; xx += 2) {
                        var px = img.pixel(Math.round(at.x + xx), Math.round(at.y + yy))
                        if (px.r > 0.6 && px.b > 0.7)
                            lit++
                    }
                verify(lit > 20, n + ": its icon is drawn (" + lit + ")")
            }
            compare(chip("batteryItem").summary, "57%")
        }

        // settings-a-06: TimeText on every Settings screen; the list padding
        function test_02_time_text_and_page_padding() {
            verify(h.app.showTime, "Settings shows the TimeText")
            var tt = h.findAll(h.app, function (o) { return h.typeName(o) === "TimeText" })
            verify(tt.length > 0 && h.shown(tt[0]), "a TimeText is shown")
            var page = h.current()
            var col = h.find(page, "settingsColumn")
            compare(col.y, 64)            // round(16.64 % of 384)
            compare(col.x, 20)            // round(5.2 % of 384)
            compare(col.width, 344)
            compare(col.spacing, 8)       // 4 dp (controls-components-13)
            var f = h.find(page, "settingsFlickable")
            compare(f.contentHeight - (col.y + col.height), 140)   // round(36.46 % of 384)
        }

        // controls-components-10: the page title as a ListHeader
        function test_03_page_title() {
            var title = h.find(h.current(), "settingsTitle")
            compare(title.text, "Settings")
            compare(title.parent.objectName, "settingsColumn")
            compare(title.horizontalPadding, 46)
            compare(title.topPadding, 8)
            compare(title.bottomPadding, 24)
            verify(title.height >= 96, "at least 48 dp")
            var l = title.label
            compare(l.font.pixelSize, 32)
            compare(l.font.weight, 550)
            rgb(l.color, "#ffffff", "title colour")
            compare(l.horizontalAlignment, Text.AlignHCenter)
            compare(l.maximumLineCount, 3)
            near(l.lineHeight, 35.2, 0.01, "line height 1.1 em")
            compare(l.width, 344 - 2 * 46)
        }

        // controls-components-05, -06, -17, design-tokens-19: a navigation row
        function test_04_navigation_row() {
            var c = chip("displayItem")
            var b = c.button
            compare(c.height, 104)
            rgb(b.containerColor, "#2f3036", "container")
            compare(b.radius, 52)
            compare(b.horizontalPadding, 28)
            compare(b.verticalPadding, 12)
            compare(b.iconSize, 52)
            compare(b.iconSpacing, 12)
            compare(b.label.font.pixelSize, 30)
            compare(b.label.font.weight, 500)
            rgb(b.label.color, "#e8e7ee", "title")
            rgb(b.iconColor, "#dbe2f9", "icon")
            compare(b.label.maximumLineCount, 5)       // no second line, no control
            compare(c.opacity, 1)
            var bat = chip("batteryItem").button
            compare(bat.secondaryLabel.font.pixelSize, 26)
            rgb(bat.secondaryLabel.color, "#cecdd4", "summary")
            compare(bat.label.maximumLineCount, 3)
            compare(bat.secondaryLabel.maximumLineCount, 2)
            // the text starts 28 + 52 + 12 px in
            var p = b.label.mapToItem(b, 0, 0)
            compare(p.x, 28 + 52 + 12)
        }

        // controls-components-01, -02, -04: a switch row
        function test_05_switch_row() {
            open(["gesturesItem"])
            var c = chip("tiltSwitch")
            verify(c !== null, "a switch row")
            compare(c.control, "toggle")
            var b = c.button
            compare(b.verticalPadding, 16)
            compare(b.trailingWidth, 64)
            compare(b.trailingSpacing, 12)
            compare(c.colorDuration, Motion.springDuration(260))
            near(c.colorDuration, 412, 15, "slow effects spring")
            near(c.controlDuration, 177, 10, "fast effects spring")
            var sw = h.find(c, "chipSwitch")
            compare(sw.width, 64)
            compare(sw.height, 48)
            compare(sw.trackWidth, 64)
            compare(sw.trackHeight, 44)
            compare(sw.borderWidth, 4)
            // 28 px from the row end: the slot ends at width - 28
            var end = sw.mapToItem(b, sw.width, 0).x
            compare(end, b.width - 28)
            verify(c.checked, "tilt-to-wake on in the mocks")
            wait(500)
            rgb(b.containerColor, "#404759", "on: primaryContainer")
            rgb(b.label.color, "#d9e0f7", "on: onPrimaryContainer")
            compare(sw.thumbSize, 36)
            compare(sw.thumbCenter, 42)
            h.tap(this, c)
            wait(600)
            if (!c.checked) {
                rgb(b.containerColor, "#2f3036", "off: surfaceContainer")
                rgb(b.label.color, "#e8e7ee", "off: onSurface")
                compare(sw.thumbSize, 24)
                compare(sw.thumbCenter, 22)
            }
            if (h.find(h.app, "confirmDialog").shown)
                h.tap(this, h.find(h.app, "dialogNo"))
        }

        // the summary of a checked row at 90 %
        function test_06_checked_summary_alpha() {
            var col = h.find(h.current(), "settingsColumn")
            var c = Qt.createQmlObject('import QtQuick; import "../src/qml"; SettingsChip { title: "T"; summary: "S"; control: "toggle"; checked: true }', col)
            wait(500)
            rgb(c.button.secondaryLabel.color, "#d9e0f7", "summary hue")
            near(c.button.secondaryLabel.color.a, 0.9, 0.01, "summary 90 %")
            c.destroy()
        }

        // controls-components-03: a radio row (in the selection dialog)
        function test_07_radio_row() {
            var col = h.find(h.current(), "settingsColumn")
            var on = Qt.createQmlObject('import QtQuick; import "../src/qml"; SettingsChip { title: "A"; control: "radio"; checked: true }', col)
            var off = Qt.createQmlObject('import QtQuick; import "../src/qml"; SettingsChip { title: "B"; control: "radio"; checked: false }', col)
            wait(500)
            var ring = h.find(on, "chipRadioRing"), dot = h.find(on, "chipRadioDot")
            compare(ring.width, 40)
            compare(ring.border.width, 4)
            compare(dot.width, 20)
            compare(dot.scale, 1)
            rgb(ring.border.color, "#dbe2f9", "selected ring")
            rgb(on.button.containerColor, "#404759", "selected row")
            rgb(h.find(off, "chipRadioRing").border.color, "#a5a5ac", "unselected ring")
            verify(!h.find(off, "chipRadioDot").visible, "no dot")
            rgb(off.button.containerColor, "#2f3036", "unselected row")
            compare(on.button.verticalPadding, 16)
            compare(on.button.trailingWidth, 64)
            on.destroy(); off.destroy()
        }

        // controls-components-08, -09: disabled and information rows
        function test_08_disabled_and_info_rows() {
            var col = h.find(h.current(), "settingsColumn")
            var d = Qt.createQmlObject('import QtQuick; import "../src/qml"; SettingsChip { title: "D"; summary: "s"; iconName: "ios-watch"; active: false }', col)
            var i = Qt.createQmlObject('import QtQuick; import "../src/qml"; SettingsChip { title: "I"; iconName: "ios-watch"; clickable: false }', col)
            compare(d.opacity, 1)
            compare(d.height, 104)
            rgb(d.button.containerColor, "#e8e7ee", "disabled container hue")
            near(d.button.containerColor.a, 0.12, 0.01, "disabled container 12 %")
            near(d.button.label.color.a, 0.38, 0.01, "disabled title 38 %")
            near(d.button.secondaryLabel.color.a, 0.38, 0.01, "disabled summary 38 %")
            near(d.button.iconColor.a, 0.38, 0.01, "disabled icon 38 %")
            compare(i.button.containerColor.a, 0)
            compare(i.button.radius, 32)
            rgb(i.button.label.color, "#e8e7ee", "info title")
            near(i.button.label.color.a, 1, 0.01, "info title opaque")
            rgb(i.button.iconColor, "#e8e7ee", "info icon hue")
            near(i.button.iconColor.a, 0.38, 0.01, "info icon 38 %")
            d.destroy(); i.destroy()
        }

        // controls-components-11, -12: category header and caption
        function test_09_category_and_caption() {
            open(["modesItem", "modesDndItem", "dndCustomize"])
            var cats = h.findAll(h.current(), function (o) { return h.typeName(o) === "SettingsCategory" })
            verify(cats.length >= 2, "the Do Not Disturb customize page has categories")
            var first = cats[0], second = cats[1]
            compare(first.font.pixelSize, 28)
            compare(first.font.weight, 550)
            rgb(first.color, "#e8e7ee", "category colour")
            compare(first.leftPadding, 16)
            compare(first.rightPadding, 16)
            compare(first.bottomPadding, 16)
            compare(first.verticalAlignment, Text.AlignBottom)
            verify(first.height >= 96, "at least 48 dp")
            verify(first.firstInPage, "the first row under the title")
            compare(first.topPadding, 0)
            verify(!second.firstInPage)
            compare(second.topPadding, 24)
            var texts = h.findAll(h.current(), function (o) { return h.typeName(o) === "SettingsText" })
            verify(texts.length > 0)
            var t = texts[0]
            compare(t.font.pixelSize, 24)
            compare(t.font.weight, 500)
            rgb(t.color, "#cecdd4", "caption colour")
            compare(t.leftPadding, 28)
            compare(t.rightPadding, 28)
            compare(t.topPadding, 12)
            compare(t.bottomPadding, 12)
        }

        // controls-components-14, -15: the slider
        function test_10_slider() {
            open(["displayItem", "brightnessItem"])
            var s = h.findAll(h.current(), function (o) { return h.typeName(o) === "SettingsSlider" })[0]
            verify(s !== undefined, "the brightness slider")
            verify(s.segmented, "brightness is segmented in stock")
            compare(s.segments, s.steps)
            compare(s.height, 104)
            var box = h.find(s, "sliderContainer")
            rgb(box.color, "#2f3036", "slider container")
            compare(box.radius, 52)
            var minus = h.find(s, "sliderMinus"), plus = h.find(s, "sliderPlus")
            compare(minus.width, 96)
            compare(plus.width, 96)
            compare(minus.height, 104)
            var g = h.find(s, "sliderPlusGlyph")
            compare(g.width, 48)
            compare(g.children[0].width, 28)
            compare(g.children[0].height, 4)
            compare(g.children[1].height, 28)
            rgb(g.color, "#e8e7ee", "glyph")
            var bar = h.find(s, "sliderBar")
            compare(bar.width, s.width - 2 * 96)
            compare(bar.height, 24)
            var sel = h.find(s, "sliderSelected"), un = h.find(s, "sliderUnselected")
            compare(sel.height, 24)
            compare(sel.radius, 12)
            rgb(sel.color, "#dbe2f9", "selected part")
            compare(un.height, 8)
            compare(un.radius, 4)
            rgb(un.color, "#000000", "rest")
            near(un.color.a, 0.3, 0.01, "rest at 30 %")
            wait(300)
            // segmented: 4 dp + (W + 4 dp) * f, clipped to the bar
            function segLength(f) { return f > 0 ? Math.min(bar.width, 8 + (bar.width + 8) * f) : 0 }
            verify(s.position > 0 && s.position < 1, "a level inside the range")
            near(sel.width, segLength(s.position), 0.5, "selected length")
            near(un.x, sel.width, 0.5, "the rest starts at the selection")
            near(un.width, bar.width - sel.width, 0.5, "the rest to the end")
            var dots = h.findAll(bar, function (o) { return o.hasOwnProperty("inSelection") })
            compare(dots.length, s.steps - 1)
            var level = Math.round(s.position * s.steps)
            for (var i = 0; i < dots.length; i++) {
                compare(dots[i].width, 8)
                near(dots[i].x + 4, (bar.width + 8) * (i + 1) / s.steps - 4, 0.01, "dot " + i)
                compare(dots[i].inSelection, i + 1 <= level, "dot " + i + " in the selection")
                if (i + 1 === level)
                    near(sel.width - 12, dots[i].x + 4, 0.5, "the selection's round end centred on its dot")
                if (dots[i].inSelection)
                    rgb(dots[i].color, "#404759", "dot in the selection")
                else {
                    rgb(dots[i].color, "#dbe2f9", "dot outside")
                    near(dots[i].color.a, 0.5, 0.01, "dot outside at 50 %")
                }
            }
            // the selected length moves over 150 ms
            var before = sel.width
            h.tap(this, minus)
            wait(40)
            verify(sel.width < before && sel.width > segLength(s.position) - 0.5, "moving at 40 ms")
            wait(300)
            near(sel.width, segLength(s.position), 0.5, "settled")
            // the top step fills the bar, the bottom one leaves it empty
            s.value = s.to
            wait(300)
            near(sel.width, bar.width, 0.01, "full")
            compare(un.width, 0)
            s.value = s.from
            wait(300)
            compare(sel.width, 0)
            verify(!sel.visible)
            near(un.width, bar.width, 0.01, "empty")
        }

        // controls-components-14 (review): volume is a plain slider in stock,
        // no dots, the selected part W * f (the volume mask leaves segmented false)
        function test_10b_slider_plain() {
            open(["soundItem"])
            var s = h.find(h.current(), "volumeSlider")
            verify(s !== null && s !== undefined, "the volume slider")
            verify(!s.segmented, "not segmented by default")
            compare(s.steps, 10)
            compare(s.segments, 1)
            var bar = h.find(s, "sliderBar")
            var sel = h.find(s, "sliderSelected"), un = h.find(s, "sliderUnselected")
            var dots = h.findAll(bar, function (o) { return o.hasOwnProperty("inSelection") })
            compare(dots.length, 0, "no step dots")
            s.value = 50
            wait(300)
            near(sel.width, bar.width * 0.5, 0.5, "half")
            near(un.x, sel.width, 0.5, "the rest starts at the selection")
            s.value = 100
            wait(300)
            near(sel.width, bar.width, 0.01, "full")
            // the same slider segmented gets its nine dots
            s.segmented = true
            compare(s.segments, 10)
            dots = h.findAll(bar, function (o) { return o.hasOwnProperty("inSelection") })
            compare(dots.length, 9)
            s.segmented = false
            dots = h.findAll(bar, function (o) { return o.hasOwnProperty("inSelection") })
            compare(dots.length, 0)
        }

        // dialogs-pickers-feedback-06, settings-a-41: the selection dialog
        function test_11_selection_dialog() {
            var applied = []
            var d = h.app.choose("Screen timeout", ["10 seconds", "15 seconds", "30 seconds"], 0,
                                 function (i) { applied.push(i); return i !== 2 }, [],
                                 "When display will turn off after inactivity")
            wait(500)
            verify(d.shown, "open")
            compare(d.objectName, "choiceDialog")
            compare(h.current(), d)
            var list = h.find(d, "choiceList")
            verify(list.dialog)
            var title = h.find(d, "choiceTitle"), msg = h.find(d, "choiceMessage")
            compare(title.text, "Screen timeout")
            compare(title.font.pixelSize, 32)
            compare(title.font.weight, 550)
            compare(title.horizontalAlignment, Text.AlignHCenter)
            compare(title.maximumLineCount, 3)
            compare(title.mapToItem(list, 0, 0).x, 46)
            near(title.mapToItem(list.contentItem, 0, 0).y - list.originY, 39, 0.5, "top padding ceil(10 %)")
            compare(msg.text, "When display will turn off after inactivity")
            compare(msg.font.pixelSize, 28)
            compare(msg.font.weight, 450)
            compare(msg.horizontalAlignment, Text.AlignHCenter)
            compare(msg.mapToItem(list, 0, 0).x, 36)
            compare(msg.topPadding, 16)
            compare(list.sidePadding, 20)
            compare(list.bottomMargin, 140)
            var row1 = h.listItem(this, list, 1)
            var row0 = h.listItem(this, list, 0)
            compare(row1.y - row0.y, row0.height)
            compare(row0.height, 104 + 8)
            compare(row0.children[0].x, 20)
            compare(row0.children[0].control, "radio")
            verify(row0.children[0].checked)
            // a tap marks the row at once, applies it, closes 300 ms later
            compare(d.closeDelay, 300)
            h.tap(this, h.listItem(this, list, 1))
            compare(applied, [1])
            compare(list.currentIndex, 1)
            verify(d.shown && d.closing, "still up, closing")
            waitClosed(d)
            // apply() false keeps it open with the old mark (the caller asks first)
            d = h.app.choose("T", ["a", "b", "c"], 0, function (i) { applied.push(i); return i !== 2 })
            wait(500)
            list = h.find(d, "choiceList")
            verify(!h.find(d, "choiceMessage").visible, "no message line")
            h.tap(this, h.listItem(this, list, 2))
            wait(500)
            verify(d.shown && !d.closing, "kept open")
            // a confirmation asked meanwhile scales the selection dialog behind it
            compare(h.find(h.app, "confirmDialog").behind, d)
            compare(list.currentIndex, 0)
            d.pop()
            waitClosed(d)
        }

        // a list row of a page opens the dialog, the screen behind scaled
        function test_12_list_row_opens_dialog() {
            open(["generalItem"])
            h.tapName(this, "temperatureItem")
            wait(500)
            var d = h.chooser()
            verify(d.shown)
            compare(d.behind, h.stack)
            near(h.stack.scale, 0.85, 0.01, "the screen behind at 0.85")
            compare(h.stack.layers.length, 1, "no page pushed")
            var before = Backend.confHas("/org/asteroidos/settings/use-fahrenheit") ? Backend.confGet("/org/asteroidos/settings/use-fahrenheit") : false
            h.tap(this, h.listItem(this, h.find(d, "choiceList"), before ? 0 : 1))
            waitClosed(d)
            compare(Backend.confGet("/org/asteroidos/settings/use-fahrenheit"), !before)
            near(h.stack.scale, 1, 0.01, "back to full size")
        }

        // power-boot-warnings-02: the confirmation is the M3 AlertDialog
        function test_13_confirmation() {
            var dlg = h.find(h.app, "confirmDialog")
            var yes = 0, no = 0
            dlg.ask("Power off", "Are you sure?", function () { yes++ }, function () { no++ })
            wait(500)
            verify(dlg.shown)
            compare(dlg.buttons, "confirmDismiss")
            compare(dlg.titleLabel.font.pixelSize, 36)     // Settings titleLarge
            compare(dlg.titleLabel.maximumLineCount, 3)
            compare(dlg.textLabel.font.pixelSize, 28)       // bodyMedium
            compare(h.find(h.app, "dialogTitle"), dlg.titleLabel)
            compare(h.find(h.app, "dialogMessage"), dlg.textLabel)
            compare(dlg.dismissButton.width, 120)
            compare(dlg.confirmButton.width, 126)
            compare(dlg.confirmButton.height, 108)
            verify(dlg.z > h.chooser().z, "over the selection dialog")
            compare(dlg.behind, h.stack)
            h.tap(this, h.find(h.app, "dialogYes"))
            compare(yes, 1)
            waitClosed(dlg)
            dlg.ask("Restart", "Are you sure?", function () { yes++ }, function () { no++ })
            wait(500)
            h.tap(this, h.find(h.app, "dialogNo"))
            compare(no, 1)
            waitClosed(dlg)
            // tell(): only the confirm action, the edge button
            dlg.tell("About", "Text", function () { yes++ })
            wait(500)
            compare(dlg.buttons, "edge")
            compare(h.find(h.app, "dialogYes"), dlg.edgeButton)
            h.tap(this, h.find(h.app, "dialogYes"))
            compare(yes, 2)
            waitClosed(dlg)
        }

        function test_14_toast() {
            var t = h.find(h.app, "toast")
            verify(t.hasOwnProperty("shortDuration"), "the org.asteroid.controls Toast")
            t.show("Hello")
            wait(100)
            compare(h.find(t, "toastText").text, "Hello")
            verify(t.visible)
            compare(t.duration, 2000)
        }

        // the stub pages
        function test_15_stub_pages() {
            open(["buttonsItem"])
            compare(h.current().objectName, "buttonsPage")
            compare(h.find(h.current(), "settingsTitle").text, "Buttons")
            h.home(this)
            open(["modesItem"])
            compare(h.current().objectName, "modesPage")
            compare(h.find(h.current(), "settingsTitle").text, "Modes")
            compare(titlesShown(h.current()), ["Do Not Disturb", "Bedtime", "Theater"])
            open(["modesDndItem"])
            compare(h.current().objectName, "dndPage")
            h.home(this)
            var pages = { "LocationPage.qml": ["locationPage", "Location"],
                          "AccessibilityPage.qml": ["accessibilityPage", "Accessibility"],
                          "SecurityPage.qml": ["securityPage", "Security"],
                          "DisplaySizePage.qml": ["displaySizePage", "Display size & text"] }
            for (var f in pages) {
                var comp = Qt.createComponent(Qt.resolvedUrl("../src/qml/" + f))
                compare(comp.status, Component.Ready, f)
                var p = comp.createObject(h.app, { width: 384, height: 384 })
                compare(p.objectName, pages[f][0])
                compare(h.find(p, "settingsTitle").text, pages[f][1])
                p.destroy()
            }
        }

        // app-inventory-02: the deep-link table
        function test_16_deep_links() {
            var cases = {
                "connectivity": ["connectivityPage"],
                "wifi": ["connectivityPage", "wifiPage"],
                "bluetooth": ["connectivityPage", "bluetoothPage"],
                "display": ["displayPage"],
                "brightness": ["displayPage", "brightnessPage"],
                "gestures": ["gesturesPage"],
                "buttons": ["buttonsPage"],
                "apps": ["appsPage"],
                "modes": ["modesPage"],
                "mode_do_not_disturb": ["modesPage", "dndPage"],
                "mode_do_not_disturb_customize": ["modesPage", "dndPage", "dndCustomizePage"],
                "mode_bedtime": ["modesPage", "bedtimePage"],
                "mode_bedtime_customize": ["modesPage", "bedtimePage", "bedtimeCustomizePage"],
                "mode_theater": ["modesPage", "theaterPage"],
                "mode_theater_customize": ["modesPage", "theaterPage", "theaterCustomizePage"],
                "dnd": ["modesPage", "dndPage"],
                "bedtime": ["modesPage", "bedtimePage"],
                "theater": ["modesPage", "theaterPage"],
                "sound": ["soundPage"],
                "vibration": ["vibrationPage"],
                "battery": ["batteryPage"],
                "battery_saver": ["batteryPage", "batterySaverPage"],
                "general": ["generalPage"],
                "system": ["systemPage"],
                "date_time": ["systemPage", "dateTimePage"],
                "device_info": ["systemPage", "aboutPage"],
                "updates": ["systemPage", "updatesPage"],
                "main": []
            }
            for (var k in cases) {
                request(k)
                compare(stackNames(), cases[k], k)
                compare(Backend.confGet("/org/asteroidos/settings/ui/open"), "", k + " request consumed")
            }
            request("language")
            compare(h.stack.layers.length, 2)
            compare(h.stack.layers[0].objectName, "systemPage")
            // an unknown route: the main list (stock NoMatch)
            request("display")
            request("magic_cue_settings")
            compare(stackNames(), [])
            // Developer options only while they are on
            request("developer_options")
            compare(stackNames(), [])
            Backend.confSet("/org/asteroidos/settings/developer-options", true)
            wait(50)
            request("developer_options")
            compare(stackNames(), ["developerPage"])
            // older than a minute: ignored
            request("display", 61000)
            compare(stackNames(), ["developerPage"])
            // a route closes an open selection dialog first
            h.app.choose("T", ["a", "b"], 0, function () {})
            wait(400)
            request("display")
            compare(stackNames(), ["displayPage"])
            verify(!h.chooser().shown)
        }
    }
}
