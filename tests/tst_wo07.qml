import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls
import org.asteroid.utils

/*
 * WO-07 of the image 60 defect list (D60-38 ... D60-45): the Settings page
 * contents against stock CP3A, measured on the rendered screen (384 x 384,
 * the round mask of SettingsHarness) where a number is about pixels.
 */
SettingsHarness {
    id: h
    shots: "/tmp/wo07-shots"

    TestCase {
        name: "SettingsWo07"
        when: windowShown

        function init() {
            h.start(this)
            Backend.clearCalls()
        }

        function chip(name) { return h.find(h.current(), name) }
        function open(names) {
            for (var i = 0; i < names.length; i++) {
                h.tapName(this, names[i])
                h.settle(this)
            }
        }
        function near(a, b, tol, what) {
            verify(Math.abs(a - b) <= tol, what + ": " + a + " (want " + b + " +- " + tol + ")")
        }
        function rgb(c, hex, what) {
            compare(Qt.rgba(c.r, c.g, c.b, 1).toString(), hex, what)
        }
        // the screen as drawn, and the box of the pixels in [x0, x1) x [y0, y1)
        // that pass test(r, g, b): {x0, x1, y0, y1, n} (x1, y1 inclusive)
        function screen() { wait(150); return grabImage(h) }
        function ink(img, x0, y0, x1, y1, test) {
            var box = { x0: 9999, x1: -1, y0: 9999, y1: -1, n: 0 }
            for (var y = y0; y < y1; y++)
                for (var x = x0; x < x1; x++) {
                    if (!test(img.red(x, y), img.green(x, y), img.blue(x, y)))
                        continue
                    box.n++
                    box.x0 = Math.min(box.x0, x); box.x1 = Math.max(box.x1, x)
                    box.y0 = Math.min(box.y0, y); box.y1 = Math.max(box.y1, y)
                }
            return box
        }
        function at(item, x, y) { return item.mapToItem(h, x || 0, y || 0) }

        // ---- D60-45: the list icon is 24 dp (settings_list_icon_size) and
        // the text keeps its place

        function test_45_list_icon_slot() {
            var c = chip("displayItem")
            h.bringIntoView(this, c)
            wait(200)
            var b = c.button
            compare(b.iconSize, 48)
            compare(b.iconSpacing, 16)
            // the row starts at x 20, the slot 28 px in, the text 28 + 52 + 12
            var lp = at(b.label)
            compare(Math.round(at(c).x), 20)
            compare(Math.round(lp.x), 112)
            // the icon box: 48 x 48 at the start of the 52 px slot (x 48)
            var ic = h.findAll(c, function (o) { return h.typeName(o) === "Icon" })[0]
            compare(ic.width, 48)
            compare(ic.height, 48)
            compare(Math.round(at(ic).x), 48)
            near(at(ic).y + 24, at(c).y + c.height / 2, 0.5, "icon centred in the row")
            var img = screen()
            var y0 = Math.round(at(c).y), y1 = y0 + Math.round(c.height)
            // the icon: primary #DBE2F9 (blue above red), inside x 48-96
            var icon = ink(img, 30, y0, 110, y1, function (r, g, b) { return b > 150 && b - r > 15 })
            verify(icon.n > 50, "icon drawn: " + icon.n)
            verify(icon.x0 >= 48 && icon.x1 < 96, "icon ink inside the 48 px box at x 48: " + icon.x0 + "-" + icon.x1)
            verify(icon.y1 - icon.y0 < 48, "icon ink under 48 px high: " + (icon.y1 - icon.y0 + 1))
            // the label: onSurface #E8E7EE, first ink at x 114 +- 1 as before
            var label = ink(img, 100, y0, 300, y1, function (r, g, b) { return r > 150 && Math.abs(b - r) < 14 })
            verify(label.n > 50, "label drawn")
            near(label.x0, 114, 1, "label ink x")
            h.shot(this, "d60-45-icon-slot")
        }

        // ---- D60-40: About rows are plain text, the value as the title

        // the brightest pixel in a box: the colour of the text's stems
        function brightest(img, x0, y0, x1, y1) {
            var best = [0, 0, 0]
            for (var y = y0; y < y1; y++)
                for (var x = x0; x < x1; x++) {
                    var r = img.red(x, y), g = img.green(x, y), b = img.blue(x, y)
                    if (r + g + b > best[0] + best[1] + best[2])
                        best = [r, g, b]
                }
            return best
        }
        function test_40_about_rows() {
            Backend.confSet("/org/asteroidos/eos-update/version", "59")
            open(["systemItem", "aboutItem"])
            compare(h.current().objectName, "aboutPage")
            verify(chip("aboutEos") === null, "no System version row")
            var rows = ["aboutSystem", "aboutModel", "aboutDeviceName", "aboutSerial", "aboutManufactured",
                        "aboutConnection", "aboutBattery"]
            for (var i = 0; i < rows.length; i++) {
                var r = chip(rows[i])
                verify(r.dataRow && !r.clickable, rows[i] + " is a data row")
                var b = r.button
                compare(b.containerColor.a, 0, rows[i] + ": no container")
                // Body4 of the Flex theme: body_medium 14 sp, weight 450
                compare(b.label.font.pixelSize, 28, rows[i] + ": title 14 sp")
                compare(b.secondaryLabel.font.pixelSize, 28, rows[i] + ": value 14 sp")
                compare(b.label.font.weight, 450)
                compare(b.secondaryLabel.font.weight, 450)
                rgb(b.label.color, "#e8e7ee", rows[i] + ": title onSurface")
                rgb(b.secondaryLabel.color, "#e8e7ee", rows[i] + ": value onSurface")
                compare(b.label.maximumLineCount, 1)
                compare(b.secondaryLabel.maximumLineCount, 4)
                compare(b.verticalPadding, 16)
            }
            // the one-line rows: 16 + 32 + 32 + 16 = 96 px, 104 px apart
            // (the 8 px gap of the list); each text's first baseline 24 px
            // under its top, its last 8 px over its bottom
            var m = chip("aboutModel"), d = chip("aboutDeviceName")
            near(m.height, 96, 1, "row height")
            near(d.y - m.y, 104, 1, "row pitch")
            var mb = m.button
            near(mb.label.baselineOffset, 24, 0.5, "title first baseline")
            near(mb.label.height - mb.label.baselineOffset, 8, 0.5, "title last baseline to bottom")
            // in the row's own coordinates (the edge effect scales it on the screen)
            near(mb.label.mapToItem(m, 0, 0).y, 16, 0.5, "8 dp above")
            var pitch = mb.secondaryLabel.mapToItem(m, 0, mb.secondaryLabel.baselineOffset).y
                        - mb.label.mapToItem(m, 0, mb.label.baselineOffset).y
            near(pitch, 32, 0.5, "line pitch")
            // Versions is still a button row
            verify(!chip("versionsItem").dataRow && chip("versionsItem").clickable)
            // on the screen: the value drawn #E8E7EE from x 50 (stock x 50)
            h.bringIntoView(this, m)
            wait(200)
            var img = screen()
            var vy = Math.round(at(mb.secondaryLabel).y)
            var vh = Math.round(mb.secondaryLabel.height)
            var c = brightest(img, 40, vy, 300, vy + vh)
            verify(Math.abs(c[0] - 0xe8) <= 3 && Math.abs(c[1] - 0xe7) <= 3 && Math.abs(c[2] - 0xee) <= 3,
                   "value colour " + c)
            var v = ink(img, 30, vy, 340, vy + vh, function (r, g, b) { return r > 120 })
            near(v.x0, 50, 2, "value ink x")
            var t = ink(img, 30, Math.round(at(mb.label).y), 340, Math.round(at(mb.label).y + mb.label.height),
                        function (r, g, b) { return r > 120 })
            near(t.x0, 50, 2, "title ink x")
            h.shot(this, "d60-40-about")
        }

        // the image version moved to Versions > Build number (stock: the
        // system image's build); before an install the os-release build id
        function test_40_build_number() {
            Backend.confSet("/org/asteroidos/eos-update/version", "59")
            open(["systemItem", "aboutItem", "versionsItem"])
            var b = chip("buildItem")
            verify(b.dataRow && b.clickable, "a data row that takes the seven taps")
            compare(b.button.containerColor.a, 0)
            compare(b.summary, "59")
            Backend.confSet("/org/asteroidos/eos-update/version", "0")
            compare(b.summary, DeviceSpecs.buildID)
            Backend.confSet("/org/asteroidos/eos-update/version", "")
            compare(b.summary, DeviceSpecs.buildID)
            var names = ["systemUiItem", "kernelItem", "qtItem"]
            for (var i = 0; i < names.length; i++)
                verify(chip(names[i]).dataRow, names[i] + " is a data row")
            near(chip("kernelItem").height, 96, 1, "row height")
        }
    }
}
