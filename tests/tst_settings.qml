/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Settings as the stock Wear OS app (src/qml/main.qml) on mocks of its
 * backends (tests/mocks: Backend records every write): the top level list
 * in the stock order, every row of every page doing something (no dead
 * entries) with no text cut off, each switch, list and slider reaching its
 * backend, the dialogs before what stock asks about, Developer options
 * after seven taps, and the open request of a system update notification.
 * Run by settings-stock/run-tests.sh (qemu-aarch64, offscreen 384x384).
 */

import QtQuick
import QtTest
import SettingsTest
import Connman

SettingsHarness {
    id: h

    TestCase {
        name: "Settings"
        when: windowShown

        property var visited: []
        property var problems: []

        function init() { h.start(this) }

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
        function dialog() { return h.find(h.app, "confirmDialog") }
        function toast() { return h.find(h.app, "toast") }
        function accept() { h.tap(this, h.find(h.app, "dialogYes")); wait(50) }
        function reject() { h.tap(this, h.find(h.app, "dialogNo")); wait(50) }
        function last(target, method) { return Backend.find(target, method) }
        function conf(key) { return Backend.confGet(key) }
        // the pages the stack shows by objectName, from the main list
        function open(names) {
            for (var i = 0; i < names.length; i++) {
                h.tapName(this, names[i])
                h.settle(this)
            }
        }

        function test_01_top_level_in_stock_order() {
            compare(h.current().objectName, "mainPage")
            compare(titlesShown(h.current()),
                    ["Connectivity", "Display", "Gestures", "Buttons", "Apps & notifications", "Modes",
                     "Sound", "Vibration", "Battery", "General", "System"])
            compare(h.find(h.current(), "batteryItem").summary, "57%")
            verify(!h.shown(h.find(h.current(), "developerItem")), "Developer options hidden until the 7 taps")
            // the title is the first row and scrolls with the list
            var title = h.find(h.current(), "settingsTitle")
            compare(title.text, "Settings")
            compare(title.parent.objectName, "settingsColumn")
        }

        // every row of every settings page does something: opens a page or
        // a dialog, changes a backend, or shows a toast; and no text on any
        // of them is cut off
        function crawl(depth) {
            var page = h.current()
            var name = page.objectName
            if (visited.indexOf(name) >= 0)
                return
            visited.push(name)
            var labels = h.findAll(page, function (o) { return o.hasOwnProperty("truncated") && o.text !== undefined })
            for (var l = 0; l < labels.length; l++)
                if (h.shown(labels[l]) && labels[l].truncated)
                    problems.push(name + ": cut off: " + labels[l].text)
            var chips = chipsOf(page)
            for (var i = 0; i < chips.length; i++) {
                var c = chips[i]
                if (!h.shown(c) || !c.clickable || !c.active || c.objectName === "developerSwitch")
                    continue
                var layers = h.stack.layers.length
                var calls = Backend.calls.length
                var before = c.checked
                h.tap(this, c)
                wait(50)
                var pushed = h.stack.layers.length > layers
                var asked = dialog().shown
                var chose = h.chooser().shown
                var toasted = toast().visible
                var wrote = Backend.calls.length > calls
                if (chose) {
                    // a list setting: its selection dialog, closed again
                    h.back(this)
                    continue
                }
                if (!(pushed || asked || toasted || wrote))
                    problems.push(name + ": dead entry: " + c.title)
                if (asked && dialog().infoOnly) {
                    // a notice with only the check (About Wi-Fi, Bluetooth first): read it, then as any row
                    accept()
                    asked = false
                }
                if (asked) {
                    reject()
                } else if (pushed) {
                    h.settle(this)
                    var top = h.current()
                    if (h.find(top, "settingsFlickable") && depth < 6)
                        crawl(depth + 1)
                    while (h.stack.layers.length > layers)
                        h.back(this)
                } else if (c.control === "toggle" && c.checked !== before) {
                    // put the switch back (accepting what it asks)
                    h.tap(this, c)
                    if (dialog().shown)
                        accept()
                }
            }
        }
        function test_02_no_dead_entries_no_cut_text() {
            Backend.confSet("/org/asteroidos/settings/developer-options", true)
            Backend.wifiServices = [netComponent.createObject(h, { name: "Home", connected: true, favorite: true }),
                                    netComponent.createObject(h, { name: "Cafe", favorite: false })]
            visited = []
            problems = []
            crawl(0)
            compare(problems, [])
            var expected = ["mainPage", "connectivityPage", "bluetoothPage", "wifiPage", "wifiAddPage", "wifiSavedPage",
                            "displayPage", "brightnessPage", "extraDimPage", "nightstandPage", "gesturesPage", "buttonsPage", "appsPage", "modesPage",
                            "dndPage", "assistantPage", "soundPage", "vibrationPage", "batteryPage", "generalPage", "systemPage",
                            "dateTimePage", "aboutPage", "versionsPage", "developerPage"]
            for (var i = 0; i < expected.length; i++)
                verify(visited.indexOf(expected[i]) >= 0, expected[i] + " reached")
        }
        Component { id: netComponent; NetworkService { } }

        function test_03_connectivity() {
            open(["connectivityItem", "bluetoothItem"])
            compare(h.find(h.current(), "phoneItem").summary, "Connected, 80% battery")
            // off asks first (stock words), ✕ keeps it on
            h.tapName(this, "bluetoothSwitch")
            verify(dialog().shown)
            compare(dialog().title, "Turn off Bluetooth?")
            reject()
            compare(Backend.btPowered, true)
            h.tapName(this, "bluetoothSwitch")
            accept()
            compare(last("bluez", "Adapter1.Powered").args, [false])
            verify(!h.shown(h.find(h.current(), "phoneItem")), "no phone row with Bluetooth off")
            // on: at once
            h.tapName(this, "bluetoothSwitch")
            compare(last("bluez", "Adapter1.Powered").args, [true])
            h.back(this)
            h.tapName(this, "wifiItem")
            h.settle(this)
            verify(last("connman", "requestScan") !== null, "a scan when the page opens")
            h.tapName(this, "wifiSwitch")
            accept()
            compare(last("connman", "wifi.Powered").args, [false])
            verify(!h.shown(h.find(h.current(), "wifiAdd")), "no Add network with Wi-Fi off")
            h.tapName(this, "wifiSwitch")
            compare(last("connman", "wifi.Powered").args, [true])
            h.tapName(this, "wifiAbout")
            verify(dialog().shown)
            verify(!h.shown(h.find(h.app, "dialogNo")), "About Wi-Fi has only the check")
            accept()
        }

        function chipTitled(page, t) {
            var c = chipsOf(page)
            for (var i = 0; i < c.length; i++)
                if (h.shown(c[i]) && c[i].title === t)
                    return c[i]
            return null
        }
        // Wi-Fi as stock: the current network shows only its addresses, Add network lists every
        // network in range (the connected one first, no 802.1X), a tap connects or asks for the
        // password, Forget is under Saved networks, and there is no Disconnect or Autoconnect
        function test_03a_wifi_as_stock() {
            Backend.wifiServices = [netComponent.createObject(h, { name: "Home", connected: true, favorite: true }),
                                    netComponent.createObject(h, { name: "Cafe" }),
                                    netComponent.createObject(h, { name: "Library", security: ["none"] }),
                                    netComponent.createObject(h, { name: "Office", security: ["ieee8021x"] })]
            var seen = []
            open(["connectivityItem", "wifiItem"])
            var p = h.current()
            compare(h.find(p, "wifiSwitch").summary, "Automatic")
            verify(Number(conf("/org/asteroidos/eos-wifi/settings-open")) > 0, "Wi-Fi held up while the page is open")
            compare(titlesShown(p), ["Wi-Fi", "Home", "Add network", "Saved networks", "About Wi-Fi"])
            compare(conf("/org/asteroidos/eos-wifi/last-used"), "Home")
            seen = seen.concat(titlesShown(p))
            h.tapName(this, "wifiCurrent")
            h.settle(this)
            compare(h.current().objectName, "wifiCurrentPage")
            compare(titlesShown(h.current()), ["IP address", "IPv6 addresses", "MAC address"])
            compare(h.find(h.current(), "wifiIp").summary, "192.0.2.10")
            h.back(this)
            h.tapName(this, "wifiAdd")
            h.settle(this)
            var add = h.current()
            compare(titlesShown(add), ["Home", "Cafe", "Library"])
            compare(chipTitled(add, "Home").summary, "Connected")
            compare(chipTitled(add, "Cafe").summary, "")
            seen = seen.concat(titlesShown(add))
            // an open network connects at once, from the list
            h.tap(this, chipTitled(add, "Library"))
            compare(last("connman", "requestConnect").args, ["Library"])
            compare(h.current(), add)
            // a new secured one asks for its password first
            h.tap(this, chipTitled(add, "Cafe"))
            h.settle(this)
            var cfg = h.find(h.current(), "wifiConnectPage")
            verify(cfg !== null, "the password page")
            compare(cfg.title, "Cafe")
            compare(titlesShown(cfg), ["Network password required", "Enter on watch"])
            seen = seen.concat(titlesShown(cfg))
            h.back(this)
            h.back(this)
            h.tapName(this, "wifiSaved")
            h.settle(this)
            compare(titlesShown(h.current()), ["Home"])
            h.tap(this, chipTitled(h.current(), "Home"))
            h.settle(this)
            compare(h.current().objectName, "wifiSavedNetworkPage")
            compare(titlesShown(h.current()), ["Forget"])
            seen = seen.concat(titlesShown(h.current()))
            h.tapName(this, "wifiForget")
            compare(dialog().title, "Forget network Home?")
            accept()
            compare(last("connman", "remove").args, ["Home"])
            verify(seen.indexOf("Disconnect") < 0 && seen.indexOf("Autoconnect") < 0, "no Disconnect or Autoconnect: " + seen)
        }
        // the switch: Automatic / Off is the setting the policy applies; off shows stock's
        // "Bluetooth first" once; not connected, the last network used shows, with no tap
        function test_03b_wifi_switch() {
            Backend.confSet("/org/asteroidos/eos-wifi/last-used", "Home")
            open(["connectivityItem", "wifiItem"])
            var lastRow = h.find(h.current(), "wifiLastUsed")
            verify(h.shown(lastRow), "Last used")
            compare(lastRow.title, "Home")
            compare(lastRow.summary, "Last used")
            compare(lastRow.clickable, false)
            h.tapName(this, "wifiSwitch")
            verify(dialog().shown)
            compare(dialog().title, "Bluetooth first")
            verify(!h.shown(h.find(h.app, "dialogNo")), "only the check")
            accept()
            compare(conf("/org/asteroidos/eos-wifi/bluetooth-first-shown"), true)
            compare(conf("/org/asteroidos/eos-wifi/enabled"), false)
            compare(last("connman", "wifi.Powered").args, [false])
            compare(h.find(h.current(), "wifiSwitch").summary, "Off")
            compare(titlesShown(h.current()), ["Wi-Fi", "About Wi-Fi"])
            h.tapName(this, "wifiSwitch")
            verify(!dialog().shown, "no notice the second time")
            compare(conf("/org/asteroidos/eos-wifi/enabled"), true)
            compare(last("connman", "wifi.Powered").args, [true])
            compare(h.find(h.current(), "wifiSwitch").summary, "Automatic")
        }

        function test_04_display() {
            var dim = "/system/osso/dsm/display/display_dim_timeout"
            var blank = "/system/osso/dsm/display/display_blank_timeout"
            open(["displayItem"])
            // the screen is on for dim + blank: 10 + 5 s is stock's 15 s
            var timeout = h.find(h.current(), "timeoutItem")
            compare(timeout.summary, "15 seconds")
            // a shorter timeout: at once, dim = T - 5; blank is 5 already
            h.tap(this, timeout)
            h.settle(this)
            var list = h.find(h.current(), "choiceList")
            compare(list.count, 3)
            compare(list.currentIndex, 1)
            compare(h.listItem(this, list, 1).children[0].title, "15 seconds (recommended)")
            h.tap(this, h.listItem(this, list, 0))
            h.settle(this)
            compare(last("mce", dim).args, [5])
            compare(last("mce", blank), null)
            compare(h.current().objectName, "displayPage")
            compare(timeout.summary, "10 seconds")
            // longer than the recommended 15 s: asks first
            h.tap(this, timeout)
            h.settle(this)
            list = h.find(h.current(), "choiceList")
            h.tap(this, h.listItem(this, list, 2))
            verify(dialog().shown)
            compare(dialog().title, "Change screen timeout")
            compare(dialog().message, "30 seconds reduces battery life")
            accept()
            h.settle(this)
            compare(last("mce", dim).args, [25])
            compare(timeout.summary, "30 seconds")
            compare(h.current().objectName, "displayPage")
        }

        // a timeout set some other way (eos-cool): the nearest choice shows,
        // nothing is written until one is chosen; then blank becomes 5 s
        function test_04b_odd_timeouts() {
            var dim = "/system/osso/dsm/display/display_dim_timeout"
            var blank = "/system/osso/dsm/display/display_blank_timeout"
            Backend.mce[dim] = 20
            Backend.mce[blank] = 30
            open(["displayItem"])
            var timeout = h.find(h.current(), "timeoutItem")
            compare(timeout.summary, "30 seconds")
            h.tap(this, timeout)
            h.settle(this)
            compare(h.find(h.current(), "choiceList").currentIndex, 2)
            h.back(this)
            compare(last("mce", dim), null)
            compare(last("mce", blank), null)
            // 15 s is shorter than the 50 s it is: no question
            h.tap(this, timeout)
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 1))
            h.settle(this)
            verify(!dialog().shown)
            compare(last("mce", blank).args, [5])
            compare(last("mce", dim).args, [10])
            compare(timeout.summary, "15 seconds")
            // 3 + 3 = 6 s shows as 10 s
            Backend.mceSet(dim, 3)
            Backend.mceSet(blank, 3)
            compare(timeout.summary, "10 seconds")
        }

        function test_04c_display_more() {
            open(["displayItem"])
            // always-on: off at once, on after the stock question
            h.tapName(this, "aodSwitch")
            compare(conf("/org/asteroidos/settings/always-on-display"), false)
            compare(last("mce", "use_low_power_mode").args, [false])
            verify(!h.shown(h.find(h.current(), "aodBrightnessItem")))
            h.tapName(this, "aodSwitch")
            compare(dialog().title, "Always-on screen reduces battery life.")
            accept()
            compare(conf("/org/asteroidos/settings/always-on-display"), true)
            compare(last("mce", "use_low_power_mode").args, [true])
            // on the charger with Nightstand, mce's mode is Nightstand's
            Backend.chargerType = 2
            Backend.clearCalls()
            h.tapName(this, "aodSwitch")
            compare(conf("/org/asteroidos/settings/always-on-display"), false)
            compare(last("mce", "use_low_power_mode"), null)
            Backend.chargerType = 0
            h.tapName(this, "aodSwitch")
            accept()
            // always-on brightness and burn-in protection: lists
            h.tapName(this, "aodBrightnessItem")
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 2))
            h.settle(this)
            compare(conf("/org/asteroidos/settings/always-on-brightness"), "high")
            compare(h.find(h.current(), "aodBrightnessItem").summary, "High")
            h.tapName(this, "burnInItem")
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 1))
            h.settle(this)
            compare(conf("/org/asteroidos/settings/burn-in-protection-level"), 0.25)
            // brightness: the slider's + and adaptive brightness
            h.tapName(this, "brightnessItem")
            h.settle(this)
            h.tap(this, h.find(h.current(), "sliderPlus"))
            compare(last("mce", "display_brightness").args, [70])
            h.tap(this, h.find(h.current(), "sliderMinus"))
            h.tap(this, h.find(h.current(), "sliderMinus"))
            compare(last("mce", "display_brightness").args, [50])
            h.tapName(this, "adaptiveSwitch")
            compare(last("mce", "als_enabled").args, [false])
            h.back(this)
            // Nightstand
            h.tapName(this, "nightstandItem")
            h.settle(this)
            h.tapName(this, "nightstandDelay")
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 2))
            h.settle(this)
            compare(conf("/desktop/asteroid/nightstand/delay"), 10)
            h.tap(this, h.find(h.current(), "sliderPlus"))
            compare(conf("/desktop/asteroid/nightstand/brightness"), 40)
            h.tapName(this, "nightstandSwitch")
            compare(conf("/desktop/asteroid/nightstand/enabled"), false)
            verify(!h.find(h.current(), "nightstandDelay").active, "the rest greyed out with Nightstand off")
        }

        function test_05_gestures() {
            open(["gesturesItem"])
            h.tapName(this, "tiltSwitch")
            compare(last("mce", "wrist_sensor_enabled").args, [false])
            h.tapName(this, "tiltSwitch")
            compare(dialog().title, "Tilt-to-wake reduces battery life.")
            accept()
            compare(last("mce", "wrist_sensor_enabled").args, [true])
            h.tapName(this, "touchSwitch")
            compare(last("mce", "actions_gesture4").args, [""])
            h.tapName(this, "touchSwitch")
            compare(last("mce", "actions_gesture4").args, ["unblank"])
            h.back(this)
            Backend.tiltAvailable = false
            h.tapName(this, "gesturesItem")
            h.settle(this)
            verify(!h.find(h.current(), "tiltSwitch").active, "no tilt sensor: greyed out")
        }

        function test_06_notifications_sound_vibration() {
            Backend.confSet("/desktop/asteroid/pre-mute-level", 0)
            open(["appsItem", "dndItem"])
            h.tapName(this, "dndSwitch")
            compare(conf("/org/asteroidos/notifications/do-not-disturb"), true)
            compare(h.find(h.current(), "dndSwitch").title, "On")
            h.back(this)
            compare(h.find(h.current(), "dndItem").summary, "On")
            h.home(this)
            open(["soundItem"])
            h.tap(this, h.find(h.current(), "sliderPlus"))
            compare(last("pulse", "MainVolume2.CurrentStep").args, [80])
            // muted from the quick panel (volume 0, the level kept): a step unmutes
            Backend.confSet("/desktop/asteroid/pre-mute-level", 60)
            Backend.volume = 0
            compare(h.find(h.current(), "volumeSlider").value, 0)
            h.tap(this, h.find(h.current(), "sliderPlus"))
            compare(last("pulse", "MainVolume2.CurrentStep").args, [10])
            compare(conf("/desktop/asteroid/pre-mute-level"), 0)
            h.home(this)
            open(["vibrationItem"])
            h.tapName(this, "quietSwitch")
            compare(conf("/org/asteroidos/notifications/quiet-on-charger"), false)
            h.tapName(this, "hapticsSwitch")
            compare(conf("/desktop/asteroid/vibration"), false)
        }

        function test_06b_voice_recognition() {
            var key = "/org/asteroidos/voice/recognition"
            open(["appsItem", "assistantItem"])
            // unset: the watch's own, as the assistant and btsyncd read it
            var item = h.find(h.current(), "recognitionItem")
            compare(item.summary, "On the watch")
            Backend.confSet(key, "auto")
            compare(item.summary, "Phone when connected")
            h.tap(this, item)
            h.settle(this)
            var list = h.find(h.current(), "choiceList")
            compare(list.count, 3)
            compare(list.currentIndex, 1)
            compare(h.listItem(this, list, 0).children[0].summary, "Works without the phone")
            // no choice is cut off; the second lines keep the stock limit of
            // two lines (RadioButtonItemKt), which the wider stand-in font can reach
            for (var i = 0; i < list.count; i++) {
                var chip = h.listItem(this, list, i).children[0]
                verify(!chip.button.label.truncated, "cut off: " + chip.title)
                compare(chip.button.secondaryLabel.maximumLineCount, 2)
            }
            h.tap(this, h.listItem(this, list, 2))
            h.settle(this)
            compare(conf(key), "phone")
            compare(item.summary, "Phone only")
            h.tap(this, item)
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 0))
            h.settle(this)
            compare(conf(key), "watch")
            // anything else counts as the watch's
            Backend.confSet(key, "bogus")
            compare(item.summary, "On the watch")
        }

        function test_07_battery_general() {
            Backend.batteryState = 1
            Backend.chargerType = 1
            open(["batteryItem"])
            compare(h.find(h.current(), "batteryPercent").text, "57%")
            compare(h.find(h.current(), "batteryStatus").text, "Charging")
            Backend.batteryState = 3
            compare(h.find(h.current(), "batteryStatus").text, "Connected, not charging")
            h.home(this)
            open(["generalItem"])
            h.tapName(this, "unreadDotSwitch")
            compare(conf("/org/asteroidos/notifications/unread-dot"), false)
            compare(h.find(h.current(), "appViewItem").summary, "Default horizontal")
            Backend.confSet("/desktop/asteroid/applauncher", "file:///usr/share/asteroid-launcher/applauncher/006-wear-list.qml")
            compare(h.find(h.current(), "appViewItem").summary, "List view")
            h.tapName(this, "temperatureItem")
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 1))
            h.settle(this)
            compare(conf("/org/asteroidos/settings/use-fahrenheit"), true)
            compare(h.find(h.current(), "temperatureItem").summary, "Fahrenheit (°F)")
        }

        function test_08_system() {
            open(["systemItem"])
            compare(h.find(h.current(), "languageItem").summary, "English (United Kingdom)")
            h.tapName(this, "powerOffItem")
            compare(dialog().title, "Power off")
            compare(dialog().message, "Are you sure?")
            reject()
            compare(last("org.freedesktop.login1", "org.freedesktop.login1.Manager.PowerOff"), null)
            h.tapName(this, "powerOffItem")
            accept()
            compare(last("org.freedesktop.login1", "org.freedesktop.login1.Manager.PowerOff").args, [false])
            h.tapName(this, "restartItem")
            accept()
            compare(last("org.freedesktop.login1", "org.freedesktop.login1.Manager.SetRebootParameter").args, [""])
            verify(last("org.freedesktop.login1", "org.freedesktop.login1.Manager.Reboot") !== null)
            // Date & time
            h.tapName(this, "dateTimeItem")
            h.settle(this)
            Backend.confSet("/org/asteroidos/settings/use-12h-format", true)
            compare(h.find(h.current(), "hourFormatSwitch").checked, false)
            compare(h.find(h.current(), "setTimeItem").summary, "10:09 AM")
            h.tapName(this, "hourFormatSwitch")
            compare(conf("/org/asteroidos/settings/use-12h-format"), false)
            compare(h.find(h.current(), "setTimeItem").summary, "10:09")
            compare(h.find(h.current(), "setZoneItem").summary, "GMT+00:00 London")
            // a zone: region, then city; back on Date & time
            h.tapName(this, "setZoneItem")
            h.settle(this)
            wait(200)
            var regions = h.find(h.current(), "choiceList")
            verify(regions.count > 5)
            h.tap(this, h.listItem(this, regions, 7))   // Europe
            h.settle(this)
            var zones = h.find(h.current(), "choiceList")
            compare(zones.count, 3)
            h.tap(this, h.listItem(this, zones, 0))     // Berlin
            wait(700)
            compare(last("org.freedesktop.timedate1", "org.freedesktop.timedate1.SetTimezone").args, ["Europe/Berlin", false])
            compare(h.current().objectName, "dateTimePage")
            h.back(this)
            // Language
            h.tapName(this, "languageItem")
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 3))
            compare(last("locale1", "SetLocale").args[0], "fr_FR")
        }

        function test_09_developer_options() {
            open(["systemItem", "aboutItem", "versionsItem"])
            var build = h.find(h.current(), "buildItem")
            for (var i = 0; i < 3; i++)
                h.tap(this, build)
            verify(!toast().visible || toast().text === "", "no toast for the first taps")
            h.tap(this, build)
            compare(h.find(toast(), "toastText").text, "You are now 3 steps away from being a developer.")
            h.tap(this, build)
            h.tap(this, build)
            compare(h.find(toast(), "toastText").text, "You are now 1 step away from being a developer.")
            h.tap(this, build)
            compare(h.find(toast(), "toastText").text, "You are now a developer!")
            compare(conf("/org/asteroidos/settings/developer-options"), true)
            h.home(this)
            var dev = h.find(h.current(), "developerItem")
            verify(h.shown(dev), "Developer options at the end of the list")
            compare(titlesShown(h.current()).pop(), "Developer options")
            h.tap(this, dev)
            h.settle(this)
            h.tapName(this, "bootloaderItem")
            accept()
            compare(last("org.freedesktop.login1", "org.freedesktop.login1.Manager.SetRebootParameter").args, ["bootloader"])
            h.tapName(this, "developerSwitch")
            h.settle(this)
            compare(conf("/org/asteroidos/settings/developer-options"), false)
            compare(h.current().objectName, "mainPage")
            verify(!h.shown(h.find(h.current(), "developerItem")))
        }

        function test_10_open_requests() {
            Backend.confSet("/org/asteroidos/settings/ui/open", "updates@" + Date.now())
            wait(600)
            compare(h.current().objectName, "updatesPage")
            compare(h.stack.layers.length, 2)
            compare(h.stack.layers[0].objectName, "systemPage")
            compare(conf("/org/asteroidos/settings/ui/open"), "")
            Backend.confSet("/org/asteroidos/settings/ui/open", "battery@" + Date.now())
            wait(600)
            compare(h.current().objectName, "batteryPage")
            compare(h.stack.layers.length, 1)
            // a stale request is dropped
            Backend.confSet("/org/asteroidos/settings/ui/open", "updates@" + (Date.now() - 120000))
            wait(300)
            compare(h.current().objectName, "batteryPage")
        }
    }
}
