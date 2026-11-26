/*
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * What Settings makes before its first frame (D60-46): the main list and
 * nothing else. Every page type loads at its first push (a PageType in
 * main.qml stands in for the page's Component); the selection dialog, the
 * confirmation, the toast and the reset screen are made after the first
 * frame (main.cpp sets firstFrameDrawn), and at once when one is wanted
 * sooner, also while it is being made; a page request waiting at start
 * opens its pages before the first frame (CP3A starts the NavHost at the
 * requested route, ComposeRouteNavHostKt.java:146-153) and loads only
 * their types.
 */

import QtQuick
import QtTest
import SettingsTest

SettingsHarness {
    id: h

    TestCase {
        name: "Start"
        when: windowShown

        readonly property string openKey: "/org/asteroidos/settings/ui/open"
        // the app (untyped: the harness Loader item)
        readonly property var app: h.app

        // the PageType stand-ins of main.qml, in their order there
        function pageTypes() {
            var out = []
            var d = app.data
            for (var i = 0; i < d.length; i++) {
                if (d[i] && d[i].hasOwnProperty("page") && d[i].hasOwnProperty("initial"))
                    out.push(d[i])
            }
            return out
        }
        function pageType(page) {
            var types = pageTypes()
            for (var i = 0; i < types.length; i++) {
                if (types[i].page === page)
                    return types[i]
            }
            return null
        }
        // the pages whose type was loaded
        function loadedPages() {
            var out = []
            var types = pageTypes()
            for (var i = 0; i < types.length; i++) {
                if (types[i].loaded !== null)
                    out.push(types[i].page)
            }
            return out
        }
        // the items made after the first frame (main.qml Later)
        function laters() {
            var out = []
            var d = app.data
            for (var i = 0; i < d.length; i++) {
                if (d[i] && d[i].hasOwnProperty("made") && d[i].hasOwnProperty("asynchronous"))
                    out.push(d[i])
            }
            return out
        }
        // by its file; "" is the toast (an org.asteroid.controls type)
        function later(file) {
            var l = laters()
            for (var i = 0; i < l.length; i++) {
                var s = String(l[i].source)
                if (file === "" ? s === "" : s.substring(s.length - file.length) === file)
                    return l[i]
            }
            return null
        }
        function allMade() {
            var l = laters()
            for (var i = 0; i < l.length; i++) {
                if (l[i].status !== Loader.Ready || l[i].item === null)
                    return false
            }
            return true
        }
        function stackNames() {
            var out = []
            for (var i = 0; i < h.stack.layers.length; i++)
                out.push(h.stack.layers[i].objectName)
            return out
        }
        // the main list's rows in stock order (main.qml firstRows, then
        // MainListRows.qml)
        readonly property var firstRows: ["connectivityItem", "displayItem", "gesturesItem"]
        readonly property var moreRows: ["buttonsItem", "appsItem", "modesItem", "soundItem", "vibrationItem",
            "batteryItem", "generalItem", "healthProfileItem", "locationItem", "safetyItem", "accessibilityItem",
            "securityItem", "systemItem", "developerItem"]
        function mainList() { return h.stack.firstPageItem }
        // the rows of the main list's column, by name, in their order there
        function rowNames() {
            var col = h.find(mainList(), "settingsColumn")
            var out = []
            for (var i = 0; i < col.children.length; i++) {
                if (col.children[i].objectName !== "")
                    out.push(col.children[i].objectName)
            }
            return out
        }

        function test_01_only_the_main_list_before_the_first_frame() {
            h.start(this, null, true)
            compare(app.firstFrameDrawn, false)
            compare(h.current().objectName, "mainPage")
            compare(pageTypes().length, 56, "a PageType for each page main.qml opens")
            compare(loadedPages(), [], "no page type loaded before a push")
            compare(laters().length, 4)
            var l = laters()
            for (var i = 0; i < l.length; i++) {
                compare(l[i].active, false)
                compare(l[i].item, null)
                compare(l[i].asynchronous, true)
                // each fills the screen, as the item it makes did
                compare(l[i].width, 384)
                compare(l[i].height, 384)
            }
            // the stacking the items had: selection dialog, confirmation, toast, reset screen
            compare(later("ChoicePage.qml").z, 1000)
            compare(later("ConfirmDialog.qml").z, 1100)
            compare(later("").z, 1200)
            compare(later("FactoryResetScreen.qml").z, 1500)
            var names = ["choiceDialog", "confirmDialog", "toast", "factoryResetScreen"]
            for (i = 0; i < names.length; i++)
                compare(h.find(h.app, names[i]), null, names[i] + " is not made yet")
            // the list: the rows of its first screen, in its column; the
            // others (and the Battery row's level) after the first frame
            compare(rowNames(), firstRows)
            compare(app.mainListMade, false)
            compare(mainList().rowsMade, false)
            compare(h.find(h.app, "batteryItem"), null)
            wait(300)
            compare(rowNames(), firstRows, "nothing more without the first frame")
        }

        function test_02_made_after_the_first_frame() {
            h.start(this, null, true)
            app.firstFrameDrawn = true
            var c = later("ChoicePage.qml")
            compare(rowNames(), firstRows, "the other rows in the background")
            compare(c.active, false, "after the list's rows")
            tryCompare(app, "mainListMade", true, 20000)
            compare(rowNames(), firstRows.concat(moreRows), "every row, in stock order, in the list's column")
            compare(c.active, true)
            compare(c.item, null, "made in the background, not there and then")
            tryVerify(allMade, 20000, "all four made after the first frame")
            compare(h.find(h.app, "batteryItem").summary, "57%")
            verify(!h.shown(h.find(h.app, "developerItem")), "Developer options hidden until the 7 taps")
            var d = h.find(h.app, "choiceDialog")
            var cf = h.find(h.app, "confirmDialog")
            var r = h.find(h.app, "factoryResetScreen")
            var t = h.find(h.app, "toast")
            compare(d.behind, h.stack)
            compare(cf.behind, h.stack)
            compare(d.shown, false)
            compare(cf.shown, false)
            compare(r.running, false)
            compare(r.visible, false)
            verify(h.find(t, "toastText") !== null, "the toast label is named")
            compare([d.width, d.height, cf.width, cf.height, r.width, r.height, t.width, t.height],
                    [384, 384, 384, 384, 384, 384, 384, 384])
            compare(loadedPages(), [], "still no page type")
        }

        function test_03_wanted_before_it_is_made() {
            h.start(this, null, true)
            var d = app.choose("Title", ["One", "Two"], 1, function () { return true })
            verify(d !== null && d !== undefined, "the selection dialog made at once")
            compare(d.objectName, "choiceDialog")
            compare(d.shown, true)
            compare(d.currentIndex, 1)
            compare(d.behind, h.stack)
            compare(later("ChoicePage.qml").asynchronous, false)
            d.pop()
            var yes = 0
            later("ConfirmDialog.qml").ask("Restart", "Are you sure?", function () { yes++ })
            var cf = h.find(h.app, "confirmDialog")
            verify(cf !== null, "the confirmation made at once")
            compare(cf.shown, true)
            compare(cf.behind, h.stack)
            compare(h.find(cf, "dialogTitle").text, "Restart")
            compare(h.find(cf, "dialogMessage").text, "Are you sure?")
            cf.accept()
            compare(yes, 1)
            compare(cf.shown, false)
            later("").show("Hello")
            compare(h.find(h.app, "toastText").text, "Hello")
            // asked for nothing: not made
            compare(later("FactoryResetScreen.qml").item, null)
            later("FactoryResetScreen.qml").start()
            var r = h.find(h.app, "factoryResetScreen")
            verify(r !== null, "the reset screen made at once")
            compare(r.running, true)
            compare(r.visible, true)
        }

        function test_04_wanted_while_it_is_being_made() {
            h.start(this, null, true)
            app.firstFrameDrawn = true
            compare(later("ChoicePage.qml").item, null)
            compare(later("ConfirmDialog.qml").item, null)
            var d = app.choose("Title", ["One", "Two"], 0, function () { return true })
            verify(d !== null && d !== undefined, "the selection dialog finished at once")
            compare(d.shown, true)
            later("ConfirmDialog.qml").ask("Turn off?", "", function () {})
            var cf = h.find(h.app, "confirmDialog")
            verify(cf !== null, "the confirmation finished at once")
            compare(cf.shown, true)
            // over the selection dialog that asks for it
            compare(cf.behind, d)
            later("ConfirmDialog.qml").close()
            d.pop()
            compare(cf.behind, h.stack)
            tryVerify(allMade, 20000, "the other two made in the background")
        }

        function test_05_a_page_type_loads_at_its_first_push() {
            h.start(this)
            compare(loadedPages(), [])
            h.tapName(this, "connectivityItem")
            compare(h.current().objectName, "connectivityPage")
            compare(loadedPages(), ["ConnectivityPage"])
            var type = pageType("ConnectivityPage").loaded
            compare(type.status, Component.Ready)
            h.back(this)
            h.tapName(this, "connectivityItem")
            verify(pageType("ConnectivityPage").loaded === type, "the type is loaded once")
            // a page of a page: Wi-Fi under Connectivity
            h.tapName(this, "wifiItem")
            compare(h.current().objectName, "wifiPage")
            compare(loadedPages(), ["ConnectivityPage", "WiFiPage"])
        }

        function test_06_every_page_loads() {
            h.start(this)
            var types = pageTypes()
            for (var i = 0; i < types.length; i++) {
                var page = h.stack.push(types[i])
                verify(page !== null && page !== undefined, types[i].page + " is made")
                compare(types[i].loaded.status, Component.Ready, types[i].page)
                compare(h.typeName(page), types[i].page)
                compare(h.stack.currentLayer, page)
                if (types[i].initial.hasOwnProperty("mode"))
                    compare(page.mode, types[i].initial.mode)
                h.stack.pop(h.stack.currentLayer)
            }
            compare(loadedPages().length, 56)
            compare(h.stack.layers.length, 0)
        }

        function test_07_a_request_at_start_opens_only_its_pages() {
            // the battery complication: Battery > Battery saver (CR-16)
            h.start(this, function () { Backend.confSet(openKey, "battery_saver@" + Date.now()) }, true)
            compare(app.firstFrameDrawn, false)
            compare(stackNames(), ["batteryPage", "batterySaverPage"])
            compare(Backend.confGet(openKey), "", "the request is consumed")
            compare(loadedPages(), ["BatteryPage", "BatterySaverPage"])
            var l = laters()
            for (var i = 0; i < l.length; i++)
                compare(l[i].item, null, "no dialog made for the request")
            // the page is the first screen: at rest, nothing under it drawn
            compare(h.stack.pushing, false)
            compare(h.current().objectName, "batterySaverPage")
            verify(h.shown(h.current()), "the page is drawn")
            verify(!h.shown(mainList()), "the list is not drawn under it")
            verify(!h.shown(h.stack.layers[0]), "nor Battery")
            // the list gets its rows after the first frame, all of them
            compare(rowNames(), [])
            app.firstFrameDrawn = true
            tryCompare(app, "mainListMade", true, 20000)
            compare(rowNames(), firstRows.concat(moreRows))
            // Back: Battery, then the list
            h.back(this)
            compare(h.current().objectName, "batteryPage")
            h.back(this)
            compare(h.current().objectName, "mainPage")
            verify(h.shown(mainList()))
        }

        // Back from a page opened at start before the first frame: the list's
        // first rows are made there and then
        function test_08_back_to_the_list_before_its_rows() {
            h.start(this, function () { Backend.confSet(openKey, "battery@" + Date.now()) }, true)
            compare(stackNames(), ["batteryPage"])
            compare(h.stack.pushing, false)
            verify(!h.shown(mainList()))
            compare(rowNames(), [])
            h.back(this)
            compare(h.current().objectName, "mainPage")
            compare(rowNames(), firstRows)
            app.firstFrameDrawn = true
            tryCompare(app, "mainListMade", true, 20000)
            compare(rowNames(), firstRows.concat(moreRows))
        }

        // a request at start that opens no page (the main route, an unknown
        // one, a stale one): the list with its first rows, as without one
        function test_09_a_request_at_start_for_the_list() {
            var requests = ["main@" + Date.now(), "magic_cue_settings@" + Date.now(), "battery@" + (Date.now() - 120000)]
            for (var i = 0; i < requests.length; i++) {
                h.start(this, function () { Backend.confSet(openKey, requests[i]) }, true)
                compare(stackNames(), [], requests[i])
                compare(Backend.confGet(openKey), "", "the request is consumed")
                compare(rowNames(), firstRows, requests[i])
                compare(loadedPages(), [])
            }
        }

        // a request while Settings runs: its pages at once, at rest, over
        // nothing but the stack it replaces (Back goes to the list as before)
        function test_10_a_request_while_running() {
            h.start(this)
            h.tapName(this, "displayItem")
            compare(h.current().objectName, "displayPage")
            Backend.confSet(openKey, "battery_saver@" + Date.now())
            tryVerify(function () { return h.current().objectName === "batterySaverPage" }, 5000, "the request opens its page")
            compare(stackNames(), ["batteryPage", "batterySaverPage"])
            compare(h.stack.pushing, false, "no push motion over the list")
            verify(!h.shown(mainList()))
            h.back(this)
            h.back(this)
            compare(h.current().objectName, "mainPage")
            compare(rowNames(), firstRows.concat(moreRows))
        }
    }
}
