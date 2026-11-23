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
        // Theme is one for the whole run: No theme, no face colours and no
        // Bold text again after each test
        function cleanup() {
            if (Theme.boldText)
                Backend.confSet("/org/asteroidos/ux/bold-text", false)
            if (Theme.colorSource !== "static")
                Theme.setColorTheme("static", "")
            if (Theme._faceSeedValue)
                Backend.confSet("/org/asteroidos/theme/face-seed", "")
            if (Theme._faceAccentValue)
                Backend.confSet("/org/asteroidos/theme/face-accent", "")
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
            // the title of the legacy DeviceInfoFragment: labelMedium (Flex
            // label_medium, 15 sp on 18 sp lines) in onSurface, centred, 64 px
            // from the screen edges, its first baseline 14 sp under the list
            // top (y 64), 36 px tall, then the column's 8 px to the first row
            var about = h.current()
            var title = h.find(about, "settingsTitle")
            compare(title.text, "About")
            verify(h.shown(title))
            verify(h.findAll(about, function (o) { return h.typeName(o) === "ListHeader" && h.shown(o) }).length === 0,
                   "no M3 ListHeader")
            compare(title.font.pixelSize, 30)
            compare(title.font.weight, 500)
            compare(title.lineHeight, 36)
            rgb(title.color, "#e8e7ee", "title onSurface")
            compare(title.horizontalAlignment, Text.AlignHCenter)
            compare(title.maximumLineCount, 3)
            compare(title.mapToItem(about, title.leftPadding, 0).x, 64)
            compare(title.mapToItem(about, title.width - title.rightPadding, 0).x, 384 - 64)
            near(title.mapToItem(about, 0, 0).y, 64, 0.5, "title at the list top")
            near(title.baselineOffset, 28, 0.5, "title baseline 14 sp under its top")
            near(title.height, 36, 0.5, "title box")
            near(chip("aboutSystem").mapToItem(about, 0, 0).y, 108, 0.5, "first row 8 px under it")
            // drawn: the title's cap at y 68, the first row's 61 px under it
            // (S22-b: "About" 68, "Wear OS" 129); no edge effect on the title
            wait(200)
            var top = screen()
            var ti = ink(top, 60, 48, 324, 104, function (r, g, b) { return r > 120 })
            var fl = chip("aboutSystem").button.label
            var fi = ink(top, 30, Math.round(at(fl).y), 340, Math.round(at(fl).y + fl.height),
                         function (r, g, b) { return r > 120 })
            near(ti.y0, 68, 2, "title cap")
            near(fi.y0 - ti.y0, 61, 2, "title cap to the first row's cap")
            near((ti.x0 + ti.x1) / 2, 192, 2, "title centred")
            var tcol = brightest(top, 60, 48, 324, 104)
            verify(Math.abs(tcol[0] - 0xe8) <= 3 && Math.abs(tcol[1] - 0xe7) <= 3 && Math.abs(tcol[2] - 0xee) <= 3,
                   "title ink " + tcol)
            h.shot(this, "d60-40-about-top")
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
            // the one-line rows: 16 + 34 + 34 + 16 = 100 px, 108 px apart
            // (the 8 px gap of the list; S22-b 108); each text's first
            // baseline 26 px under its top (the stock font's ascent, over
            // Body4's 12 sp), its last 8 px over its bottom
            var m = chip("aboutModel"), d = chip("aboutDeviceName")
            near(m.height, 100, 1, "row height")
            near(d.y - m.y, 108, 1, "row pitch")
            var mb = m.button
            near(mb.label.baselineOffset, 26, 0.5, "title first baseline")
            near(mb.secondaryLabel.baselineOffset, 26, 0.5, "value first baseline")
            near(mb.secondaryLabel.height - mb.secondaryLabel.baselineOffset, 8, 0.5, "value last baseline to bottom")
            near(mb.label.height - mb.label.baselineOffset, 8, 0.5, "title last baseline to bottom")
            // in the row's own coordinates (the edge effect scales it on the screen)
            near(mb.label.mapToItem(m, 0, 0).y, 16, 0.5, "8 dp above")
            var pitch = mb.secondaryLabel.mapToItem(m, 0, mb.secondaryLabel.baselineOffset).y
                        - mb.label.mapToItem(m, 0, mb.label.baselineOffset).y
            near(pitch, 34, 0.5, "line pitch")
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
            // on the screen, cap to cap (S22-b: Wear OS 129, 6.0 163,
            // Model 236: 34 and 107 px; the rows near the middle are not scaled)
            var dl = d.button.label
            var tm = ink(img, 30, Math.round(at(mb.label).y), 340, Math.round(at(mb.label).y + mb.label.height),
                         function (r, g, b) { return r > 120 })
            var td = ink(img, 30, Math.round(at(dl).y), 340, Math.round(at(dl).y + dl.height),
                         function (r, g, b) { return r > 120 })
            near(td.y0 - tm.y0, 108, 2, "row pitch on the screen")
            h.shot(this, "d60-40-about")
        }

        // the image version moved to Versions > Build number (stock: the
        // system image's build); before an install the os-release build id
        function test_40_build_number() {
            Backend.confSet("/org/asteroidos/eos-update/version", "59")
            open(["systemItem", "aboutItem", "versionsItem"])
            var b = chip("buildItem")
            // DeviceVersionFragment: the same legacy title as About
            var vp = h.current()
            var vt = h.find(vp, "settingsTitle")
            compare(vt.text, "Versions")
            compare(vt.font.pixelSize, 30)
            rgb(vt.color, "#e8e7ee", "title onSurface")
            near(vt.mapToItem(vp, 0, vt.baselineOffset).y, 92, 0.5, "title baseline")
            near(b.mapToItem(vp, 0, 0).y, 108, 0.5, "first row 8 px under the title")
            near(b.button.label.mapToItem(vp, 0, b.button.label.baselineOffset).y, 150, 0.5,
                 "first row baseline (S22-b: 149)")
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
            near(chip("kernelItem").height, 100, 1, "row height")
        }

        // ---- D60-41: Legal notices is the stock info popup

        function dialog() { return h.find(h.app, "confirmDialog") }
        function test_41_legal_notices_popup() {
            open(["systemItem", "aboutItem"])
            h.tapName(this, "legalNoticesItem")
            var d = dialog()
            tryVerify(function () { return d.shown && d.contentScale === 1 && d.alpha === 1 }, 3000, "settled")
            compare(d.buttons, "info")
            verify(d.info)
            compare(d.title, "")
            compare(d.text, "For licences and source code, see asteroidos.org")
            verify(!h.shown(d.titleLabel) || d.titleLabel.text === "", "no title")
            // the message: titleMedium 32 px, onSurface, centred, 3 lines
            var t = d.textLabel
            compare(t.font.pixelSize, 32)
            rgb(t.color, "#e8e7ee", "message colour")
            compare(t.horizontalAlignment, Text.AlignHCenter)
            compare(t.lineCount, 3)
            verify(!d.scrolling, "fits without scrolling")
            // one round check, named for the tests and the screen reader
            var ok = h.find(h.app, "dialogYes")
            compare(ok, d.infoButton)
            compare(ok.width, 104)
            compare(ok.Accessible.name, "OK")
            verify(!h.shown(d.edgeButton), "no edge button")
            var img = screen()
            // the first line's caps from y 111 (stock 111 / 147 / 183)
            var msg = ink(img, 40, 40, 344, 250, function (r, g, b) { return r > 150 && Math.abs(b - r) < 14 })
            near(msg.y0, 111, 3, "first cap top")
            // the circle: primary #DBE2F9, 104 px at x 140-243, y 257-360
            var c = ink(img, 100, 230, 284, 384, function (r, g, b) { return b > 220 && r > 190 })
            near(c.x0, 140, 1, "circle left")
            near(c.x1, 243, 1, "circle right")
            near(c.y0, 257, 1, "circle top")
            near(c.y1, 360, 1, "circle bottom")
            h.shot(this, "d60-41-legal")
            h.tap(this, ok)
            tryVerify(function () { return !d.shown }, 3000, "the check closes it")
            compare(h.current().objectName, "aboutPage")
        }

        // ---- D60-39: Battery header start-aligned with a progress bar

        function test_39_battery_header() {
            open(["batteryItem"])
            var head = chip("batteryHeader")
            var digits = chip("batteryPercent"), bar = chip("batteryBar"), label = chip("batteryRemaining")
            verify(bar !== null, "the progress bar")
            h.bringIntoView(this, head)
            wait(200)
            // in the header's own coordinates: 14 dp (28 px) in, 6 dp (12 px)
            // above, the bar right under the digits, the label 6 dp under it
            var d = digits.mapToItem(head, 0, 0), b = bar.mapToItem(head, 0, 0), l = label.mapToItem(head, 0, 0)
            compare(d.x, 28)
            compare(d.y, 12)
            compare(b.x, 28)
            compare(bar.width, head.width - 56)
            compare(b.y, d.y + digits.parent.parent.height)
            compare(bar.height, 8)
            compare(l.x, 28)
            compare(l.y, b.y + bar.height + 12)
            compare(head.height, l.y + label.height + 12 + 12)
            compare(label.effectiveHorizontalAlignment, Text.AlignLeft)
            // the CP3A colours: digits and label onSurfaceVariant, the bar
            // tertiary on surfaceContainer, 57 %
            rgb(digits.color, Theme.color.onSurfaceVariant.toString(), "digits")
            rgb(label.color, Theme.color.onSurfaceVariant.toString(), "label")
            compare(bar.color.toString(), Theme.color.tertiary.toString())
            compare(bar.trackColor.toString(), Theme.color.surfaceContainer.toString())
            near(bar.progress, 0.57, 0.001, "progress")
            Backend.batteryPercent = 20
            tryVerify(function () { return Math.abs(bar.progress - 0.2) < 0.001 }, 2000, "follows the level")
            Backend.batteryPercent = 57
            tryVerify(function () { return Math.abs(bar.progress - 0.57) < 0.001 }, 2000, "back to 57 %")
            // on the screen: digits, bar and label all start at x 48
            compare(Math.round(at(head).x), 20)
            var img = screen()
            var dy = Math.round(at(digits).y), dh = Math.round(digits.height)
            var dInk = ink(img, 20, dy, 300, dy + dh, function (r, g, b) { return r > 120 })
            near(dInk.x0, 48, 3, "digits ink x")
            var by = Math.round(at(bar).y)
            var bInk = ink(img, 20, by, 364, by + 8, function (r, g, b) { return r > 60 || g > 60 || b > 60 })
            near(bInk.x0, 48, 1, "bar from x 48")
            near(bInk.x1, 335, 1, "bar (track) to x 335")
            var ly = Math.round(at(label).y), lh = Math.round(label.height)
            var lInk = ink(img, 20, ly, 340, ly + lh, function (r, g, b) { return r > 120 })
            near(lInk.x0, 48, 3, "label ink x")
            verify(lInk.x1 <= 48 + label.contentWidth + 2, "label left-aligned, not centred: ends at " + lInk.x1)
            h.shot(this, "d60-39-battery")
        }

        // ---- D60-42: System licenses lists the parts, each opens its text

        // the rows a page shows, top to bottom
        function rowsOf(page) {
            var rows = h.findAll(page, function (o) {
                return o.hasOwnProperty("control") && o.hasOwnProperty("summary") && h.shown(o)
            })
            rows.sort(function (a, b) { return at(a).y - at(b).y })
            return rows
        }
        // the row (SettingsChip) of part i of a ChoiceList, made and
        // scrolled to first (a ListView makes the rows near the screen only)
        function listChip(view, i) {
            var row = h.listItem(this, view, i)
            return h.findAll(row, function (o) { return o.hasOwnProperty("control") && o.hasOwnProperty("summary") })[0]
        }
        function test_42_licences() {
            open(["systemItem", "aboutItem", "licensesItem"])
            var list = h.current()
            compare(list.objectName, "licensesPage")
            compare(h.find(list, "choiceTitle").text, "System licenses")
            // one plain row per part (a source recipe of the installed
            // packages, PackageInfo.readLicenses(): the test double has six of
            // the image's), sorted by name, listed once they are read
            tryVerify(function () { return list.loaded }, 3000, "the parts are read")
            compare(list.parts.length, 6)
            var view = h.find(list, "choiceList")
            compare(view.count, 6)
            var titles = []
            for (var i = 0; i < view.count; i++) {
                var row = listChip(view, i)
                titles.push(row.title)
                compare(row.summary, "", row.title + ": no second line")
                compare(row.iconName, "", row.title + ": no icon")
                compare(row.control, "none", row.title + ": no radio mark")
                verify(row.clickable)
            }
            compare(titles, ["asteroid-settings", "eos-kernel-boot", "glibc", "kmod", "qml-asteroid", "qtbase"])
            view.positionViewAtBeginning()
            wait(100)
            verify(!h.shown(h.find(list, "choiceMessage")), "no message while there are parts")
            verify(h.findAll(list, function (o) { return h.typeName(o) === "SettingsText" }).length === 0,
                   "no paragraphs on the list")
            h.shot(this, "d60-42-list")
            h.tap(this, listChip(view, 1))
            h.settle(this)
            var page = h.current()
            compare(page.objectName, "licenseTextPage")
            var head = h.find(page, "licenseHeading"), text = h.find(page, "licenseText")
            compare(head.text, "eos-kernel-boot")
            compare(text.text, "GPL-2.0-only")
            verify(!h.shown(h.find(page, "settingsTitle")), "the header is the part's name, no page title")
            // the header: textAppearanceMedium over Title3: 14 sp (titleSmall
            // 28 px, weight 500, no tracking) onSurfaceVariant, centred, on
            // Title3's 18 sp lines
            compare(head.font.pixelSize, 28)
            compare(head.font.weight, 500)
            compare(head.font.letterSpacing, 0)
            compare(head.lineHeight, 36)
            rgb(head.color, "#cecdd4", "header colour")
            compare(head.horizontalAlignment, Text.AlignHCenter)
            // the text: 12 sp on 14 sp lines in outline, from x 59, 12 dp under the header
            compare(text.font.pixelSize, 24)
            compare(text.lineHeight, 28)
            rgb(text.color, "#a5a5ac", "text colour")
            // a plain TextView (TextAppearance.Material.Small): sans-serif
            // regular, no tracking, not bodySmall's 500 and 0.4 sp
            compare(text.font.weight, 400)
            compare(text.font.letterSpacing, 0)
            // Bold text adds its 300 (fontWeightAdjustment), and takes it back
            Backend.confSet("/org/asteroidos/ux/bold-text", true)
            compare(text.font.weight, 700, "Bold text")
            Backend.confSet("/org/asteroidos/ux/bold-text", false)
            compare(text.font.weight, 400, "Bold text off")
            compare(text.font.letterSpacing, 0)
            tryVerify(function () { return Math.abs(page.mapToItem(h, 0, 0).x) < 0.01 && Math.abs(at(page, 384, 0).x - 384) < 0.01 },
                      3000, "the page at rest")
            compare(text.mapToItem(page, text.leftPadding, 0).x, 59)
            compare(text.mapToItem(page, text.width - text.rightPadding, 0).x, 384 - 59)
            // the header's baseline at y 94 (S35-c; Title3's box from 14 sp
            // above it to 4 sp under it, so 66-102), 12 dp to the text, whose
            // first baseline is 26 px under its top (S35-c: y 152)
            var hb = head.mapToItem(page, 0, head.baselineOffset).y
            near(hb, 94, 0.5, "header baseline")
            var tTop = text.mapToItem(page, 0, 0).y
            near(tTop - (hb + 8), 24, 0.5, "12 dp under the header's box")
            near(text.baselineOffset, 26, 0.5, "text first baseline under its top")
            near(tTop + text.baselineOffset, 152, 0.5, "text first baseline")
            // the pushed page fades in after it has moved: let it settle
            wait(400)
            var img = screen()
            var hy = Math.round(at(head).y), hh = Math.round(head.height - head.bottomPadding)
            var hInk = ink(img, 20, hy, 364, hy + hh, function (r, g, b) { return r > 120 })
            near((hInk.x0 + hInk.x1) / 2, 192, 3, "header centred")
            // "eos-kernel-boot" has no descenders: its ink ends on the baseline
            // (stock: to y 93), its ascenders 22 px or less (32 px text: 25)
            near(hInk.y1, 93, 1, "header ink bottom")
            verify(hInk.y1 - hInk.y0 + 1 <= 22, "header ink height " + (hInk.y1 - hInk.y0 + 1))
            var hc = brightest(img, 20, hy, 364, hy + hh)
            verify(Math.abs(hc[0] - 0xce) <= 3 && Math.abs(hc[2] - 0xd4) <= 3, "header ink " + hc)
            var ty = Math.round(at(text).y), th = Math.round(text.height)
            var tInk = ink(img, 20, ty, 364, ty + th, function (r, g, b) { return r > 90 })
            near(tInk.x0, 59, 2, "text ink x")
            near(tInk.y0, 134, 4, "first line's cap top (stock 134)")
            var tc = brightest(img, 20, ty, 364, ty + th)
            verify(Math.abs(tc[0] - 0xa5) <= 3 && Math.abs(tc[2] - 0xac) <= 3, "text ink " + tc)
            h.shot(this, "d60-42-text")
            // a longer text wraps in the 266 px between the paddings, 28 px apart
            h.back(this)
            h.tap(this, listChip(view, 5))
            h.settle(this)
            text = h.find(h.current(), "licenseText")
            compare(h.find(h.current(), "licenseHeading").text, "qtbase")
            verify(text.text.indexOf("LGPL-3.0-only") >= 0)
            verify(text.lineCount >= 3, "wrapped: " + text.lineCount)
            compare(text.lineHeightMode, Text.FixedHeight)
            verify(!text.truncated)
            // packages of one part with different licences: one line each
            h.back(this)
            h.tap(this, listChip(view, 3))
            h.settle(this)
            compare(h.find(h.current(), "licenseText").text,
                    "kmod: GPL-2.0-or-later & LGPL-2.1-or-later\nlibkmod2: LGPL-2.1-or-later")
            // no package data: no rows, the list says where the licences are
            h.back(this)
            h.back(this)
            compare(h.current().objectName, "aboutPage")
            Backend.confSet("/test/package-info/no-licenses", true)
            open(["licensesItem"])
            list = h.current()
            tryVerify(function () { return list.loaded }, 3000, "read")
            compare(h.find(list, "choiceList").count, 0)
            compare(rowsOf(list).length, 0)
            var msg = h.find(list, "choiceMessage")
            verify(h.shown(msg))
            verify(msg.text.indexOf("asteroidos.org") >= 0, msg.text)
        }
        // the list is a ListView: with the image's ~260 parts only the rows
        // near the screen are made
        function test_42_licences_many() {
            open(["systemItem", "aboutItem", "licensesItem"])
            var list = h.current()
            tryVerify(function () { return list.loaded }, 3000, "the parts are read")
            var many = []
            for (var i = 0; i < 260; i++)
                many.push({ "name": "part-" + (1000 + i), "license": "MIT", "packages": ["part-" + (1000 + i)] })
            list.parts = many
            var view = h.find(list, "choiceList")
            tryCompare(view, "count", 260)
            wait(100)
            var made = h.findAll(list, function (o) { return o.hasOwnProperty("control") && o.hasOwnProperty("summary") })
            verify(made.length < 30, "rows made: " + made.length)
            var last = h.listItem(this, view, 259)
            compare(h.findAll(last, function (o) { return o.hasOwnProperty("control") && o.hasOwnProperty("summary") })[0].title,
                    "part-1259")
        }

        // ---- D60-38: Display > Color theme opens the theme page

        function titlesOf(page) {
            var rows = rowsOf(page), out = []
            for (var i = 0; i < rows.length; i++)
                out.push(rows[i].title)
            return out
        }
        function px(img, x, y) {
            return [img.red(Math.round(x), Math.round(y)), img.green(Math.round(x), Math.round(y)),
                    img.blue(Math.round(x), Math.round(y))]
        }
        function same(p, hex, tol, what) {
            var c = Qt.color(hex)
            var want = [Math.round(c.r * 255), Math.round(c.g * 255), Math.round(c.b * 255)]
            verify(Math.abs(p[0] - want[0]) <= tol && Math.abs(p[1] - want[1]) <= tol && Math.abs(p[2] - want[2]) <= tol,
                   what + ": " + p + " want " + want)
        }
        function test_38_color_theme() {
            compare(Theme.colorSource, "static")
            open(["displayItem"])
            compare(titlesOf(h.current()).slice(0, 3), ["Change watch face", "Color theme", "Brightness"])
            var item = chip("colorThemeItem")
            compare(item.summary, "")
            compare(item.iconName, "")
            compare(item.control, "none")
            wait(600)
            h.shot(this, "d60-38-display")
            open(["colorThemeItem"])
            var page = h.current()
            compare(page.objectName, "colorThemePage")
            compare(h.find(page, "settingsTitle").text, "Color theme")
            var rows = rowsOf(page)
            compare(titlesOf(page), ["Match watch face", "Moonstone", "Ivy", "Porcelain", "Iris", "Lemongrass",
                                     "Jade", "Indigo", "Peony", "No theme"])
            // the harness has no dconf defaults: qml-asteroid's own, No
            // theme, is checked (the image sets Match watch face)
            for (var i = 0; i < rows.length; i++) {
                compare(rows[i].control, "select")
                compare(rows[i].summary, "")
                compare(rows[i].checked, i === 9, rows[i].title + " checked")
                compare(rows[i].button.trailingWidth, 0)
            }
            rgb(rows[9].button.containerColor, Theme.color.primaryContainer.toString(), "checked container")
            rgb(rows[9].button.contentColor, Theme.color.onPrimaryContainer.toString(), "checked text")
            rgb(rows[1].button.containerColor, "#2f3036", "container")
            rgb(rows[1].button.contentColor, "#e8e7ee", "text")
            // the avatar: 38 dp, 10 dp from the chip's start, the text 8 dp after it
            var av = h.find(rows[1], "colorThemeAvatar")
            compare(av.width, 76)
            compare(av.height, 76)
            compare(av.mapToItem(rows[1], 0, 0).x, 20)
            near(av.mapToItem(rows[1], 0, 38).y, rows[1].height / 2, 0.5, "avatar centred")
            var lb = rows[1].button.label
            compare(lb.mapToItem(rows[1], lb.leftPadding, 0).x, 112)
            verify(h.shown(h.find(rows[9], "colorThemePalette")), "No theme: the palette")
            verify(!h.shown(h.find(rows[1], "colorThemePalette")))
            // Moonstone's swatch: the top half primary_fixed_dim, the bottom
            // left secondary_fixed, the bottom right secondary_container
            var sw = page.swatchOf("#9A9EAD", "")
            compare(sw.length, 3)
            h.bringIntoView(this, rows[1])
            wait(300)
            var img = screen()
            var o = at(av)
            var cx = o.x + 38, cy = o.y + 38
            same(px(img, cx - 14, cy - 14), sw[0], 2, "top left")
            same(px(img, cx + 14, cy - 14), sw[0], 2, "top right")
            same(px(img, cx - 14, cy + 14), sw[1], 2, "bottom left")
            same(px(img, cx + 14, cy + 14), sw[2], 2, "bottom right")
            // the disc: radius rint(38 - 0.75 dp - 3 dp) = 30 px, nothing out to the ring
            same(px(img, cx, cy - 28), sw[0], 2, "inside the disc")
            same(px(img, cx - 34, cy), Theme.color.surfaceContainer.toString(), 2, "no ring unchecked")
            h.shot(this, "d60-38-themes")
            // a tap applies the preset at once, the page stays
            h.tap(this, rows[2])
            compare(Backend.confGet("/org/asteroidos/theme/color-source"), "preset")
            compare(Backend.confGet("/org/asteroidos/theme/seed"), "#404945")
            compare(Theme.colorSource, "preset")
            compare(Theme.colorSeed, "#404945")
            verify(Theme.colorThemed)
            verify(rows[2].checked && !rows[9].checked, "Ivy checked, No theme not")
            compare(h.current().objectName, "colorThemePage")
            tryVerify(function () {
                var c = rows[2].button.containerColor, w = Theme.color.primaryContainer
                return Math.abs(c.r - w.r) < 0.01 && Math.abs(c.g - w.g) < 0.01 && Math.abs(c.b - w.b) < 0.01
            }, 2000, "Ivy's container the themed primaryContainer")
            verify(Theme.color.primary.toString() !== "#dbe2f9", "the palette changed")
            // the checked swatch has its ring in onPrimaryContainer at the edge
            h.bringIntoView(this, rows[2])
            wait(600)
            img = screen()
            av = h.find(rows[2], "colorThemeAvatar")
            o = at(av)
            same(px(img, o.x + 38, o.y + 1.5), Theme.color.onPrimaryContainer.toString(), 6, "ring")
            h.shot(this, "d60-38-ivy")
            // Match watch face, then No theme again
            h.tap(this, rows[0])
            compare(Theme.colorSource, "watchface")
            verify(rows[0].checked && !rows[2].checked)
            h.tap(this, rows[9])
            compare(Backend.confGet("/org/asteroidos/theme/color-source"), "static")
            compare(Theme.colorSource, "static")
            verify(!Theme.colorThemed)
            compare(Theme.color.primary.toString(), "#dbe2f9")
            verify(rows[9].checked)
        }
        // Match watch face shows the colours the face reported whatever
        // theme is in use (sysui jbp.java:41, jrx.java:139-142, 251-253),
        // Moonstone before the face reports any
        function swatchAt(img, av, sw, what) {
            var o = at(av)
            var cx = o.x + 38, cy = o.y + 38
            same(px(img, cx - 14, cy - 14), sw[0], 2, what + ": top left")
            same(px(img, cx + 14, cy - 14), sw[0], 2, what + ": top right")
            same(px(img, cx - 14, cy + 14), sw[1], 2, what + ": bottom left")
            same(px(img, cx + 14, cy + 14), sw[2], 2, what + ": bottom right")
        }
        function test_38_match_face_swatch() {
            open(["displayItem", "colorThemeItem"])
            var page = h.current()
            compare(page.objectName, "colorThemePage")
            var row = h.find(page, "colorTheme_watchface")
            var av = h.find(row, "colorThemeAvatar")
            compare(row.seed, "#9A9EAD", "no face colours: Moonstone")
            compare(row.accent, "")
            var moon = page.swatchOf("#9A9EAD", "")
            compare(JSON.stringify(av.swatch), JSON.stringify(moon))
            // the face reports its colours while No theme is in use
            Backend.confSet("/org/asteroidos/theme/face-seed", "#C04030")
            Backend.confSet("/org/asteroidos/theme/face-accent", "#30A0C0")
            compare(Theme.colorSource, "static")
            compare(row.seed, "#C04030", "No theme: the face's seed")
            compare(row.accent, "#30A0C0", "No theme: the face's accent")
            var sw = page.swatchOf("#C04030", "#30A0C0")
            compare(JSON.stringify(av.swatch), JSON.stringify(sw))
            verify(JSON.stringify(sw) !== JSON.stringify(moon), "not Moonstone's swatch")
            verify(!row.checked, "No theme stays the checked row")
            h.bringIntoView(this, row)
            wait(300)
            swatchAt(screen(), av, sw, "No theme")
            h.shot(this, "d60-38-face-static")
            // a preset in use: the row keeps the face's colours
            h.tap(this, h.find(page, "colorTheme_ivy"))
            compare(Theme.colorSource, "preset")
            compare(Theme.colorSeed, "#404945")
            compare(row.seed, "#C04030", "a preset: the face's seed")
            compare(row.accent, "#30A0C0", "a preset: the face's accent")
            compare(JSON.stringify(av.swatch), JSON.stringify(sw))
            h.bringIntoView(this, row)
            wait(600)
            swatchAt(screen(), av, sw, "Ivy")
            h.shot(this, "d60-38-face-preset")
            // Match watch face itself: the same colours, now the theme's
            h.tap(this, row)
            compare(Theme.colorSource, "watchface")
            compare(Theme.colorSeed, "#C04030")
            compare(Theme.colorAccent, "#30A0C0")
            compare(row.seed, "#C04030")
            compare(JSON.stringify(av.swatch), JSON.stringify(sw))
            // a face that reports nothing: Moonstone again
            Backend.confSet("/org/asteroidos/theme/face-seed", "")
            Backend.confSet("/org/asteroidos/theme/face-accent", "")
            compare(row.seed, "#9A9EAD")
            compare(row.accent, "")
            compare(JSON.stringify(av.swatch), JSON.stringify(moon))
        }
        // stock route names: color_theme opens Display, then the theme page
        function test_38_color_theme_deep_link() {
            Backend.confSet("/org/asteroidos/settings/ui/open", "color_theme@" + Date.now())
            tryVerify(function () { return h.stack.layers.length === 2 }, 5000, "two pages pushed")
            compare(h.stack.layers[0].objectName, "displayPage")
            compare(h.stack.layers[1].objectName, "colorThemePage")
        }

        // ---- D60-43: Sound ends with Wireless emergency alerts (no Watch
        // ringtone: CP3A hides it on the Pixel Watch)

        function test_43_sound_rows() {
            open(["soundItem"])
            compare(h.current().objectName, "soundPage")
            var titles = titlesOf(h.current())
            compare(titles.slice(-3), ["Screen unlocking sound", "Charging sounds", "Wireless emergency alerts"])
            verify(titles.indexOf("Watch ringtone") < 0, "no Watch ringtone row")
            var row = chip("emergencyAlertsItem")
            compare(row.summary, "")
            compare(row.iconName, "")
            compare(row.control, "none")
            verify(row.clickable && row.active)
            verify(h.scrollToEnd(this), "the list scrolls")
            wait(300)
            h.shot(this, "d60-43-sound-end")
            // UI-first (Q61): no receiver before M7, the info popup says so
            Backend.clearCalls()
            h.tap(this, row)
            var d = dialog()
            tryVerify(function () { return d.shown && d.contentScale === 1 && d.alpha === 1 }, 3000, "settled")
            compare(d.buttons, "info")
            compare(d.text, "Emergency alerts are not available on this watch yet")
            compare(d.textLabel.lineCount, 3)
            compare(Backend.calls.length, 0, "nothing written")
            h.tap(this, h.find(h.app, "dialogYes"))
            tryVerify(function () { return !d.shown }, 3000, "closed")
            compare(h.current().objectName, "soundPage")
        }
    }
}
