/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * W3-settings-connectivity, on the mocks of tests/mocks (Backend records every
 * dconf write and every BlueZ and connman call): the Connectivity page (stock
 * order, Airplane mode with stock's 100 ms / 2000 ms), Bluetooth (order, the
 * Devices category, greyed rows, Pair new device and its scan, the pairing
 * failure, Answer calls on watch), Share heart rate, Mobile, the Wi-Fi network
 * rows (signal icons, No internet, unsupported security, Add hidden network),
 * Enter on watch (the keyboard at once) and the Developer option.
 */

import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls
import Connman

SettingsHarness {
    id: h
    shots: "/tmp/w3cn-shots"

    Component { id: netComponent; NetworkService { } }

    TestCase {
        name: "SettingsConnectivity"
        when: windowShown

        readonly property string kBtSnoop: "/org/asteroidos/btsyncd/connectivity-vibrate"
        readonly property string kCalls: "/org/asteroidos/btsyncd/calls-on-watch"
        readonly property string kShareHr: "/org/asteroidos/btsyncd/share-heart-rate"
        readonly property string kOffInApm: "/org/asteroidos/settings/bluetooth-off-in-airplane"
        readonly property string kMobile: "/org/asteroidos/settings/mobile-enabled"
        readonly property string kMobileAlways: "/org/asteroidos/settings/mobile-always-on"
        readonly property string kRoaming: "/org/asteroidos/settings/data-roaming"
        readonly property string kNoNet: "/org/asteroidos/eos-wifi/no-internet"
        readonly property string kPolicyFile: "/run/eos-wifi-policy/no-internet"

        function init() {
            h.start(this)
            Backend.clearCalls()
        }

        function chip(name) { return h.find(h.current(), name) }
        function conf(key) { return Backend.confGet(key) }
        function has(key) { return Backend.confHas(key) }
        function dialog() { return h.find(h.app, "confirmDialog") }
        function accept() { h.tap(this, h.find(h.app, "dialogYes")); wait(50) }
        function reject() { h.tap(this, h.find(h.app, "dialogNo")); wait(50) }
        function open(names) {
            for (var i = 0; i < names.length; i++) {
                h.tapName(this, names[i])
                h.settle(this)
            }
        }
        function title() { return h.find(h.current(), "settingsTitle").text }
        function dialogText() {
            return [h.find(h.app, "dialogTitle").text, h.find(h.app, "dialogMessage").text]
        }
        function calls(target, method) {
            var out = []
            for (var i = 0; i < Backend.calls.length; i++)
                if (Backend.calls[i].target === target && Backend.calls[i].method === method)
                    out.push(Backend.calls[i].args)
            return out
        }
        // what the page shows, top to bottom
        function shownRows(page) {
            var col = h.find(page, "settingsColumn")
            var out = []
            for (var i = 0; i < col.children.length; i++) {
                var c = col.children[i]
                if (!c.visible || c.objectName === "settingsTitle")
                    continue
                if (c.hasOwnProperty("firstInPage"))
                    out.push("category:" + c.text)
                else if (c.hasOwnProperty("control") && c.hasOwnProperty("summary"))
                    out.push("row:" + c.title)
                else if (c.hasOwnProperty("previewText"))
                    out.push("field:" + c.previewText)
                else if (c.text !== undefined)
                    out.push("text:" + c.text)
            }
            return out
        }
        function rowsNamed(objectName) {
            return h.findAll(h.current(), function (o) { return o.objectName === objectName })
        }
        function titles(objectName) {
            var rows = rowsNamed(objectName)
            var out = []
            for (var i = 0; i < rows.length; i++)
                out.push(rows[i].title)
            return out
        }
        function choices() {
            var list = h.find(h.current(), "choiceList")
            var out = []
            for (var i = 0; i < list.model; i++)
                out.push(list.textOf(i))
            return out
        }
        function pick(item, index) {
            h.tap(this, chip(item))
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), index))
            h.settle(this)
        }
        function net(props) { return netComponent.createObject(h, props) }
        function endsWith(s, t) { return s.length >= t.length && s.slice(s.length - t.length) === t }

        // ---- Connectivity (settings-a-08, -09, -10)

        function test_01_connectivity_in_stock_order() {
            open(["connectivityItem"])
            compare(h.current().objectName, "connectivityPage")
            // Bluetooth 10, Share heart rate 15, Wi-Fi 30, Mobile 40, Airplane mode 70
            // (no NFC, no Private DNS on this watch)
            compare(shownRows(h.current()), ["row:Bluetooth", "row:Share heart rate", "row:Wi-Fi", "row:Mobile", "row:Airplane mode"])
            compare(chip("bluetoothItem").iconName, "ios-bluetooth-outline")
            compare(chip("shareHeartRateItem").iconName, "ios-heart-outline")
            verify(chip("mobileItem").iconName.indexOf("eos-settings-cellular") >= 0, "the Mobile icon is ours")
            // the Airplane mode switch has no icon (stock: no icon, a switch row)
            compare(chip("airplaneSwitch").iconName, "")
            compare(chip("airplaneSwitch").control, "toggle")
            compare(chip("airplaneSwitch").checked, false)
            compare(chip("mobileItem").summary, "Automatic")
            h.shot(this, "connectivity-01-page")
        }

        // ---- Airplane mode (settings-a-08)

        function test_02_airplane_mode_timing_and_bluetooth() {
            open(["connectivityItem"])
            var sw = chip("airplaneSwitch")
            var t0 = Date.now()
            h.tap(this, sw)
            // connman powers Bluetooth down with the rest
            Backend.btPowered = false
            compare(Backend.offline, true)
            compare(calls("connman", "OfflineMode"), [[true]])
            compare(sw.checked, true)
            // stock: the switch is greyed 100 ms after the tap and back 2000 ms after it
            tryCompare(sw, "active", false, 1000)
            var greyed = Date.now() - t0
            tryCompare(sw, "active", true, 4000)
            var back = Date.now() - t0
            verify(greyed >= 90 && greyed < 700, "greyed after about 100 ms: " + greyed)
            verify(back >= 1900 && back < 3500, "enabled after about 2000 ms: " + back)
            // it comes back 1.5 s after the tap (as the quick settings tile does), as Wear OS
            // keeps Bluetooth on in airplane mode
            tryCompare(Backend, "btPowered", true, 3000)
            compare(calls("bluez", "Adapter1.Powered").length, 1)
            // off
            h.tap(this, sw)
            compare(Backend.offline, false)
            compare(calls("connman", "OfflineMode"), [[true], [false]])
            tryCompare(sw, "active", true, 4000)
            // when the person turned Bluetooth off in airplane mode it stays off the next time
            Backend.confSet(kOffInApm, true)
            h.tap(this, sw)
            Backend.btPowered = false
            wait(1900)
            compare(Backend.btPowered, false)
            h.shot(this, "connectivity-02-airplane-on")
        }

        // ---- Bluetooth page (settings-a-11, -13, calls-27)

        function test_03_bluetooth_order_and_devices() {
            open(["connectivityItem", "bluetoothItem"])
            compare(h.current().objectName, "bluetoothPage")
            compare(title(), "Bluetooth")
            // the switch first, Pair new device, Devices with one row per paired device
            // (the phone is one of them, titled with its name), Answer calls on watch + text
            compare(shownRows(h.current()),
                    ["row:Bluetooth", "row:Pair new device", "category:Devices", "row:Pocket phone", "row:Test buds",
                     "row:Answer calls on watch", "text:Audio plays through watch speaker"])
            compare(chip("bluetoothPairItem").iconName, "ios-search-outline")
            var devs = rowsNamed("bluetoothDevice")
            compare(devs.length, 2)
            // no battery percent, exactly Connected / Disconnected
            compare(devs[0].summary, "Connected")
            compare(devs[1].summary, "Disconnected")
            compare(devs[0].iconName, "ios-phone-portrait")
            compare(devs[1].iconName, "ios-headset-outline")
            verify(chip("phoneItem") === null, "no TWD9 Phone row")
            h.shot(this, "bluetooth-03-page")
            // a pairing, a connection in flight
            Backend.btSet("/dev/buds", { "connecting": true })
            compare(rowsNamed("bluetoothDevice")[1].summary, "Connecting…")
            Backend.btSet("/dev/buds", { "connecting": false, "pairing": true })
            compare(rowsNamed("bluetoothDevice")[1].summary, "Pairing…")
            Backend.btSet("/dev/buds", { "pairing": false, "connected": true })
            compare(rowsNamed("bluetoothDevice")[1].summary, "Connected")
            Backend.btSet("/dev/buds", { "connected": false })
        }

        function test_04_bluetooth_off_greys_not_hides() {
            open(["connectivityItem", "bluetoothItem"])
            // off asks first (stock words), the X keeps it on
            h.tapName(this, "bluetoothSwitch")
            compare(dialogText(), ["Turn off Bluetooth?", "Watch will be disconnected from the phone. Turning off Bluetooth for extended periods of time will use more battery power."])
            reject()
            compare(Backend.btPowered, true)
            h.tapName(this, "bluetoothSwitch")
            accept()
            compare(calls("bluez", "Adapter1.Powered"), [[false]])
            // the rows stay, greyed out
            compare(shownRows(h.current()),
                    ["row:Bluetooth", "row:Pair new device", "category:Devices", "row:Pocket phone", "row:Test buds",
                     "row:Answer calls on watch", "text:Audio plays through watch speaker"])
            compare(chip("bluetoothPairItem").active, false)
            compare(chip("answerCallsSwitch").active, false)
            var devs = rowsNamed("bluetoothDevice")
            compare(devs[0].active, false)
            compare(devs[1].active, false)
            h.shot(this, "bluetooth-04-off")
            // on: no question
            h.tapName(this, "bluetoothSwitch")
            verify(!dialog().shown, "no question when turning on")
            compare(calls("bluez", "Adapter1.Powered"), [[false], [true]])
            compare(chip("bluetoothPairItem").active, true)
        }

        function test_05_bluetooth_off_in_airplane_mode() {
            Backend.offline = true
            open(["connectivityItem", "bluetoothItem"])
            h.tapName(this, "bluetoothSwitch")
            compare(dialogText(), ["Bluetooth off in airplane mode",
                                   "Turning off Bluetooth disconnects your device from the phone. Your device will remember to keep it off next time you are in airplane mode"])
            accept()
            compare(Backend.btPowered, false)
            compare(conf(kOffInApm), true)
            // turning it on again forgets that
            h.tapName(this, "bluetoothSwitch")
            compare(Backend.btPowered, true)
            compare(conf(kOffInApm), false)
        }

        function test_06_answer_calls_on_watch() {
            open(["connectivityItem", "bluetoothItem"])
            var sw = chip("answerCallsSwitch")
            // stock: HFP is on unless disabled
            compare(sw.checked, true)
            compare(has(kCalls), false)
            h.tap(this, sw)
            compare(conf(kCalls), false)
            compare(chip("answerCallsSwitch").checked, false)
            h.tap(this, chip("answerCallsSwitch"))
            compare(conf(kCalls), true)
        }

        function test_07_device_page() {
            open(["connectivityItem", "bluetoothItem"])
            h.tap(this, rowsNamed("bluetoothDevice")[0])
            h.settle(this)
            compare(h.current().objectName, "bluetoothDevicePage")
            compare(title(), "Pocket phone")
            compare(shownRows(h.current()), ["row:Disconnect", "row:Forget", "row:Cancel"])
            h.shot(this, "bluetooth-07-device")
            h.tapName(this, "bluetoothConnectItem")
            compare(calls("bluez", "Device1.Disconnect"), [["/dev/phone"]])
            compare(chip("bluetoothConnectItem").title, "Connect")
            h.tapName(this, "bluetoothConnectItem")
            compare(calls("bluez", "Device1.Connect"), [["/dev/phone"]])
            compare(chip("bluetoothConnectItem").title, "Disconnect")
            // Cancel goes back, Forget removes it
            h.tapName(this, "bluetoothCancelItem")
            h.settle(this)
            compare(h.current().objectName, "bluetoothPage")
            h.tap(this, rowsNamed("bluetoothDevice")[1])
            h.settle(this)
            compare(title(), "Test buds")
            h.tapName(this, "bluetoothForgetItem")
            h.settle(this)
            compare(calls("bluez", "Adapter1.RemoveDevice"), [["/dev/buds"]])
            compare(h.current().objectName, "bluetoothPage")
            compare(titles("bluetoothDevice"), ["Pocket phone"])
        }

        // ---- Pair new device (settings-a-12)

        function test_08_scan_page_and_pairing() {
            var tStart = Date.now()
            open(["connectivityItem", "bluetoothItem", "bluetoothPairItem"])
            compare(h.current().objectName, "bluetoothScanPage")
            compare(title(), "Pair new device")
            // the scan starts with the page, once
            compare(calls("bluez", "Adapter1.StartDiscovery").length, 1)
            // the devices found, then the scan row (stock prefs_bluetooth_scan.xml order)
            compare(shownRows(h.current()), ["row:Gym bike", "row:Desk speaker", "row:Scanning for nearby devices…"])
            compare(chip("bluetoothScanRow").active, false)
            compare(rowsNamed("bluetoothFound")[1].iconName, "ios-musical-notes-outline")
            h.shot(this, "bluetooth-08-scan")
            // it ends by itself after 12.8 s (Android's inquiry), then the row is back
            tryCompare(Backend, "btDiscovering", false, 20000)
            var took = Date.now() - tStart
            verify(took >= 12500 && took < 17000, "the scan lasts about 12.8 s: " + took + " ms from opening the page")
            compare(calls("bluez", "Adapter1.StopDiscovery").length, 1)
            compare(chip("bluetoothScanRow").title, "Scan for nearby devices")
            compare(chip("bluetoothScanRow").active, true)
            // a new scan on the row
            h.tapName(this, "bluetoothScanRow")
            compare(calls("bluez", "Adapter1.StartDiscovery").length, 2)
            compare(chip("bluetoothScanRow").active, false)
            // a tap pairs: the scan stops first, as stock cancels discovery
            h.tap(this, rowsNamed("bluetoothFound")[0])
            h.settle(this)
            compare(calls("bluez", "Device1.Pair"), [["/dev/bike"]])
            compare(calls("bluez", "Adapter1.StopDiscovery").length, 2)
            // it is paired now: gone from this list, in the Devices of the Bluetooth page
            compare(titles("bluetoothFound"), ["Desk speaker"])
            h.back(this)
            compare(titles("bluetoothDevice"), ["Pocket phone", "Test buds", "Gym bike"])
            compare(rowsNamed("bluetoothDevice")[2].summary, "Connected")
        }

        function test_09_pairing_failure_page() {
            Backend.btPairFails = true
            open(["connectivityItem", "bluetoothItem", "bluetoothPairItem"])
            h.tap(this, rowsNamed("bluetoothFound")[1])
            h.settle(this)
            compare(h.current().objectName, "bluetoothPairErrorPage")
            compare(title(), "Couldn't connect with Desk speaker")
            compare(shownRows(h.current()),
                    ["text:Make sure device is turned on, in range and searching for a Bluetooth connection.", "row:Try again", "row:Cancel"])
            h.shot(this, "bluetooth-09-pair-error")
            // Try again pairs again (and fails again here)
            h.tapName(this, "bluetoothPairRetry")
            h.settle(this)
            compare(calls("bluez", "Device1.Pair"), [["/dev/speaker"], ["/dev/speaker"]])
            compare(h.current().objectName, "bluetoothPairErrorPage")
            // Cancel: back to the scan page, the device is still listed and not paired
            h.tapName(this, "bluetoothPairCancel")
            h.settle(this)
            compare(h.current().objectName, "bluetoothScanPage")
            compare(Backend.btDiscovering, false)
            Backend.btPairFails = false
            // leaving a running scan stops it
            h.tapName(this, "bluetoothScanRow")
            compare(Backend.btDiscovering, true)
            h.back(this)
            compare(Backend.btDiscovering, false)
        }

        function test_10_no_scan_while_bluetooth_is_off() {
            Backend.btPowered = false
            open(["connectivityItem", "bluetoothItem"])
            // the row is greyed: a tap does nothing
            compare(chip("bluetoothPairItem").active, false)
            h.tap(this, chip("bluetoothPairItem"))
            h.settle(this)
            compare(h.current().objectName, "bluetoothPage")
            compare(calls("bluez", "Adapter1.StartDiscovery").length, 0)
            // Bluetooth off under a running scan ends it
            Backend.btPowered = true
            h.tapName(this, "bluetoothPairItem")
            h.settle(this)
            compare(calls("bluez", "Adapter1.StartDiscovery").length, 1)
            compare(Backend.btDiscovering, true)
            Backend.btPowered = false
            compare(Backend.btDiscovering, false)
            compare(calls("bluez", "Adapter1.StopDiscovery").length, 1)
            compare(chip("bluetoothScanRow").active, false)
            h.tap(this, chip("bluetoothScanRow"))
            compare(calls("bluez", "Adapter1.StartDiscovery").length, 1)
        }

        // ---- Share heart rate (settings-a-10)

        function test_11_share_heart_rate() {
            open(["connectivityItem", "shareHeartRateItem"])
            compare(h.current().objectName, "shareHeartRatePage")
            compare(title(), "Share heart rate")
            compare(shownRows(h.current()),
                    ["row:Share heart rate", "text:Using this feature will impact battery life.",
                     "text:Connect to compatible exercise machines and apps to see real-time heart rate on display."])
            var sw = chip("shareHeartRateSwitch")
            compare(sw.checked, false)
            compare(has(kShareHr), false)
            h.shot(this, "heartrate-11-page")
            h.tap(this, sw)
            compare(conf(kShareHr), true)
            compare(chip("shareHeartRateSwitch").checked, true)
            // Bluetooth off: it can be switched off but not on
            Backend.btPowered = false
            compare(chip("shareHeartRateSwitch").summary, "Requires Bluetooth to be enabled.")
            compare(chip("shareHeartRateSwitch").active, true)
            h.tap(this, chip("shareHeartRateSwitch"))
            compare(conf(kShareHr), false)
            compare(chip("shareHeartRateSwitch").active, false)
        }

        // ---- Mobile (settings-a-09)

        function test_12_mobile_page() {
            open(["connectivityItem", "mobileItem"])
            compare(h.current().objectName, "mobilePage")
            compare(title(), "Mobile")
            compare(shownRows(h.current()), ["row:Mobile", "row:Data roaming"])
            compare(chip("mobileModeItem").summary, "Automatic")
            h.shot(this, "mobile-12-page")
            h.tapName(this, "mobileModeItem")
            h.settle(this)
            compare(choices(), ["On", "Automatic", "Off"])
            h.back(this)
            // Off asks with stock's words
            pick("mobileModeItem", 2)
            compare(dialogText(), ["Turn off cellular?", "You won't be able to use apps that require a network connection"])
            accept()
            h.settle(this)
            compare(conf(kMobile), false)
            // (Always was off: dconf has nothing to write)
            verify(conf(kMobileAlways) !== true, "not always on")
            compare(chip("mobileModeItem").summary, "Off")
            // On
            pick("mobileModeItem", 0)
            compare(dialogText()[0], "Turn on cellular?")
            verify(dialogText()[1].indexOf("Make calls and send messages through your watch's mobile network.") === 0, dialogText()[1])
            accept()
            h.settle(this)
            compare(conf(kMobile), true)
            compare(conf(kMobileAlways), true)
            compare(chip("mobileModeItem").summary, "On")
            // Automatic, and the X keeps the old choice
            pick("mobileModeItem", 1)
            compare(dialogText()[0], "Turn cellular to automatic?")
            reject()
            compare(conf(kMobileAlways), true)
            h.back(this)
            h.settle(this)
            pick("mobileModeItem", 1)
            accept()
            h.settle(this)
            compare(conf(kMobile), true)
            compare(conf(kMobileAlways), false)
            h.back(this)
            // the Connectivity row says it
            compare(chip("mobileItem").summary, "Automatic")
        }

        function test_13_mobile_in_airplane_mode_and_roaming() {
            open(["connectivityItem", "mobileItem"])
            Backend.offline = true
            pick("mobileModeItem", 0)
            compare(dialogText(), ["Mobile", "Mobile cannot be turned on in airplane mode"])
            verify(!h.shown(h.find(h.app, "dialogNo")), "only the check")
            accept()
            h.back(this)
            compare(conf(kMobileAlways), undefined)
            // Data roaming asks when it goes on, not when it goes off
            h.tapName(this, "dataRoamingSwitch")
            compare(dialogText(), ["Attention", "Allow data usage when roaming? Roaming charges may apply."])
            reject()
            compare(has(kRoaming), false)
            h.tapName(this, "dataRoamingSwitch")
            accept()
            compare(conf(kRoaming), true)
            compare(chip("dataRoamingSwitch").checked, true)
            h.tapName(this, "dataRoamingSwitch")
            verify(!dialog().shown, "no question when turning it off")
            compare(conf(kRoaming), false)
        }

        // ---- Wi-Fi network rows (connectivity-system-ux-08, -09, -13, -12)

        function test_14_signal_icons() {
            Backend.wifiServices = [
                net({ name: "A0", strength: 0, security: ["none"] }),
                net({ name: "A1", strength: 19, security: ["none"] }),
                net({ name: "A2", strength: 20, security: ["none"] }),
                net({ name: "A3", strength: 45, security: ["none"] }),
                net({ name: "A4", strength: 79, security: ["psk"] }),
                net({ name: "A5", strength: 80, security: ["psk"] }),
                net({ name: "A6", strength: 100, security: ["psk"] }),
                net({ name: "A7", strength: 60, security: ["psk"] }),
                net({ name: "A8", strength: 59, security: ["psk"] })]
            open(["connectivityItem", "wifiItem", "wifiAdd"])
            var want = { "A0": "eos-wifi-0", "A1": "eos-wifi-0", "A2": "eos-wifi-1", "A3": "eos-wifi-2",
                         "A4": "eos-wifi-secure-3", "A5": "eos-wifi-secure-4", "A6": "eos-wifi-secure-4",
                         "A7": "eos-wifi-secure-3", "A8": "eos-wifi-secure-2" }
            var rows = h.findAll(h.current(), function (o) { return o.hasOwnProperty("control") && want[o.title] !== undefined && h.shown(o) })
            compare(rows.length, 9)
            for (var i = 0; i < rows.length; i++)
                verify(endsWith(rows[i].iconName, want[rows[i].title]),
                       rows[i].title + ": " + rows[i].iconName + " is not " + want[rows[i].title])
            // the levels and the lock, as drawn
            h.bringIntoView(this, rows[3])
            h.shot(this, "wifi-14-levels-open")
            h.bringIntoView(this, rows[6])
            h.shot(this, "wifi-14-levels-secure")
        }

        function test_15_current_network_row_has_level_icon() {
            Backend.wifiServices = [net({ name: "Home", connected: true, favorite: true, strength: 85, security: ["psk"] })]
            open(["connectivityItem", "wifiItem"])
            verify(endsWith(chip("wifiCurrent").iconName, "eos-wifi-secure-4"), chip("wifiCurrent").iconName)
            compare(chip("wifiCurrent").summary, "Connected")
        }

        function test_16_no_internet() {
            Backend.wifiServices = [net({ name: "Home", connected: true, favorite: true, state: "ready", strength: 70 }),
                                    net({ name: "Cafe", favorite: true, strength: 50 }),
                                    net({ name: "Library", favorite: false, strength: 50 })]
            // connman says "ready" and the policy has not found it without internet: Connected
            open(["connectivityItem", "wifiItem", "wifiAdd"])
            var add = h.current()
            function summaryOf(name) {
                var rows = h.findAll(add, function (o) { return o.hasOwnProperty("control") && o.title === name && h.shown(o) })
                return rows.length ? rows[0].summary : null
            }
            compare(summaryOf("Home"), "Connected")
            compare(summaryOf("Cafe"), "Saved")
            compare(summaryOf("Library"), "")
            // the policy writes its state file 20 s after the connect: the page looks once then
            var states = h.findAll(add, function (o) { return o.objectName === "wifiInternetState" })
            verify(states.length >= 3, "a state per row")
            compare(states[0].waitMs, 21000)
            for (var i = 0; i < states.length; i++)
                states[i].waitMs = 300
            Backend.files = { "/run/eos-wifi-policy/no-internet": true }
            tryVerify(function () { return summaryOf("Home") === "No internet" }, 3000)
            compare(conf(kNoNet), "[\"Home\"]")
            h.shot(this, "wifi-16-no-internet")
            // it comes online: Connected again, forgotten
            Backend.wifiServices[0].state = "online"
            Backend.files = {}
            tryVerify(function () { return summaryOf("Home") === "Connected" }, 3000)
            compare(conf(kNoNet), "[]")
        }

        function test_17_no_internet_remembered_for_saved_network() {
            Backend.confSet(kNoNet, "[\"Cafe\",\"Library\"]")
            Backend.wifiServices = [net({ name: "Home", connected: true, favorite: true, state: "online" }),
                                    net({ name: "Cafe", favorite: true }),
                                    net({ name: "Library", favorite: false }),
                                    net({ name: "Kiosk", favorite: true, error: "invalid-key" })]
            open(["connectivityItem", "wifiItem", "wifiAdd"])
            var add = h.current()
            function summaryOf(name) {
                var rows = h.findAll(add, function (o) { return o.hasOwnProperty("control") && o.title === name && h.shown(o) })
                return rows.length ? rows[0].summary : null
            }
            // a saved network last seen without internet; one that is not saved shows nothing
            compare(summaryOf("Home"), "Connected")
            compare(summaryOf("Cafe"), "No internet")
            compare(summaryOf("Library"), "")
            compare(summaryOf("Kiosk"), "Wrong password")
        }

        function test_18_unsupported_security() {
            Backend.wifiServices = [net({ name: "OldWep", security: ["wep"] }),
                                    net({ name: "SavedWep", security: ["wep"], favorite: true }),
                                    net({ name: "Cafe", security: ["psk"] })]
            open(["connectivityItem", "wifiItem", "wifiAdd"])
            function rowOf(name) {
                return h.findAll(h.current(), function (o) { return o.hasOwnProperty("control") && o.title === name && h.shown(o) })[0]
            }
            h.tap(this, rowOf("OldWep"))
            verify(dialog().shown, "the dialog")
            compare(dialogText(), ["", "Access Point has unsupported security"])
            verify(!h.shown(h.find(h.app, "dialogNo")), "one tick only")
            compare(calls("connman", "requestConnect"), [])
            compare(h.current().objectName, "wifiAddPage")
            accept()
            h.settle(this)
            // a saved one just connects, a PSK one asks for its password
            h.tap(this, rowOf("SavedWep"))
            compare(calls("connman", "requestConnect"), [["SavedWep"]])
            h.tap(this, rowOf("Cafe"))
            h.settle(this)
            verify(cfg() !== null, "the password page")
        }

        function test_19_add_hidden_network() {
            Backend.wifiServices = [net({ name: "Home", connected: true, favorite: true }), net({ name: "Cafe" })]
            open(["connectivityItem", "wifiItem", "wifiAdd"])
            // the last row, with the add icon
            var rows = shownRows(h.current())
            compare(rows[rows.length - 1], "row:Add hidden network")
            compare(chip("wifiAddHidden").iconName, "ios-add")
            h.shot(this, "wifi-19-add")
            h.tapName(this, "wifiAddHidden")
            h.settle(this)
            compare(h.current().objectName, "wifiHiddenPage")
            compare(title(), "Add hidden network")
            compare(shownRows(h.current()), ["field:Network name", "row:Security", "field:password", "row:Connect"])
            compare(chip("wifiHiddenSecurity").summary, "WPA/WPA2/WPA3")
            compare(chip("wifiHiddenConnect").active, false)
            var name = chip("wifiHiddenName")
            var pw = chip("wifiHiddenPassword")
            name.text = "Back Office"
            compare(chip("wifiHiddenConnect").active, false)
            pw.text = "short"
            compare(chip("wifiHiddenConnect").active, false)
            pw.text = "correct horse"
            compare(chip("wifiHiddenConnect").active, true)
            h.shot(this, "wifi-19-hidden-form")
            h.tapName(this, "wifiHiddenConnect")
            compare(calls("connman", "ConnectService"), [["Back Office", "psk", "correct horse"]])
            h.settle(this)
            compare(h.current().objectName, "wifiAddPage")
        }

        function test_20_hidden_network_open_and_errors() {
            open(["connectivityItem", "wifiItem", "wifiAdd", "wifiAddHidden"])
            chip("wifiHiddenName").text = "Cafe Open"
            // None: no password field
            pick("wifiHiddenSecurity", 1)
            compare(chip("wifiHiddenSecurity").summary, "None")
            compare(shownRows(h.current()), ["field:Network name", "row:Security", "row:Connect"])
            compare(chip("wifiHiddenConnect").active, true)
            Backend.hiddenError = "net.connman.Error.InvalidKey"
            h.tapName(this, "wifiHiddenConnect")
            compare(calls("connman", "ConnectService"), [["Cafe Open", "none", ""]])
            compare(dialogText()[0], "Wrong password")
            accept()
            Backend.hiddenError = "net.connman.Error.Failed"
            h.tapName(this, "wifiHiddenConnect")
            compare(dialogText()[0], "Wi-Fi connection failure")
            accept()
            // the page stays after a failure
            compare(h.current().objectName, "wifiHiddenPage")
        }

        // ---- Enter on watch (connectivity-system-ux-10)

        function keyboards() {
            var root = h.Window.contentItem
            return h.findAll(root, function (o) { return o.hasOwnProperty("placeholderText") && o.hasOwnProperty("actionKey") })
        }
        function openConfigurePage(fields) {
            Backend.wifiServices = [net({ name: "Cafe", security: ["psk"], strength: 60 })]
            open(["connectivityItem", "wifiItem", "wifiAdd"])
            h.tap(this, h.findAll(h.current(), function (o) { return o.title === "Cafe" && o.hasOwnProperty("control") && h.shown(o) })[0])
            h.settle(this)
            verify(cfg() !== null, "the configure page")
        }
        // the dialog (the layer) and its configure page
        function cfg() { return h.find(h.current(), "wifiConnectPage") }
        function agent() { return h.current().agent }

        function test_21_enter_on_watch_opens_the_keyboard_at_once() {
            openConfigurePage()
            var page = cfg()
            compare(shownRows(page), ["row:Network password required", "row:Enter on watch"])
            h.tapName(this, "wifiEnterOnWatch")
            compare(calls("connman", "requestConnect"), [["Cafe"]])
            // connman asks for the passphrase: a plain WPA network
            agent().userInputRequested("/svc/cafe", { "Passphrase": { "Type": "psk", "Requirement": "mandatory" },
                                                            "WPS": { "Type": "wpspin", "Requirement": "alternate" } })
            tryVerify(function () { return keyboards().length === 1 }, 3000)
            var kb = keyboards()[0]
            compare(kb.placeholderText, "password")
            compare(kb.echoMode, TextInput.Password)
            compare(kb.actionKey, "done")
            // no labelled field and no Connect row behind it
            compare(shownRows(page), [])
            h.shot(this, "wifi-21-keyboard")
            // Done connects
            kb.accepted("correct horse")
            compare(calls("connman", "sendUserReply"), [[{ "Passphrase": "correct horse" }]])
            tryVerify(function () { return keyboards().length === 0 }, 3000)
        }

        function test_22_closing_the_keyboard_returns_to_the_configure_page() {
            openConfigurePage()
            var page = cfg()
            h.tapName(this, "wifiEnterOnWatch")
            agent().userInputRequested("/svc/cafe", { "Passphrase": { "Type": "psk", "Requirement": "mandatory" } })
            tryVerify(function () { return keyboards().length === 1 }, 3000)
            keyboards()[0].dismiss()
            tryVerify(function () { return keyboards().length === 0 }, 3000)
            // the request is cancelled (an empty reply), nothing was sent
            compare(calls("connman", "sendUserReply"), [[{}]])
            compare(shownRows(page), ["row:Network password required", "row:Enter on watch"])
            // and it can be asked again
            h.tapName(this, "wifiEnterOnWatch")
            agent().userInputRequested("/svc/cafe", { "Passphrase": { "Type": "psk", "Requirement": "mandatory" } })
            tryVerify(function () { return keyboards().length === 1 }, 3000)
            keyboards()[0].dismiss()
            tryVerify(function () { return keyboards().length === 0 }, 3000)
        }

        function test_23_identity_networks_keep_the_form() {
            openConfigurePage()
            var page = cfg()
            h.tapName(this, "wifiEnterOnWatch")
            agent().userInputRequested("/svc/cafe", { "Identity": { "Type": "string", "Requirement": "mandatory" },
                                                            "Passphrase": { "Type": "psk", "Requirement": "mandatory" } })
            wait(300)
            compare(keyboards().length, 0)
            verify(h.shown(h.find(page, "wifiConnect")), "the Connect row")
        }

        // ---- Developer option (connectivity-system-ux-07)

        function test_24_vibrate_on_connectivity_change() {
            Backend.confSet("/org/asteroidos/settings/developer-options", true)
            // the list grows by the new row: let it lay out before scrolling to it
            h.settle(this)
            open(["developerItem"])
            compare(h.current().objectName, "developerPage")
            compare(shownRows(h.current()),
                    ["row:Use developer options", "row:Stay awake when charging", "row:Vibrate on connectivity change", "row:Restart to bootloader"])
            var sw = chip("connectivityVibrateSwitch")
            compare(sw.checked, false)
            h.tap(this, sw)
            compare(conf(kBtSnoop), true)
            compare(chip("connectivityVibrateSwitch").checked, true)
            h.tap(this, chip("connectivityVibrateSwitch"))
            compare(conf(kBtSnoop), false)
        }
    }
}
