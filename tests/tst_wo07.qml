import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls

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
    }
}
