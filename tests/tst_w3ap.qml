/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * W3-settings-apps-privacy, on the mocks of tests/mocks (Backend records
 * every dconf write and every app action): the main list entries, Apps &
 * notifications (rows, Notifications, App notifications and the per-app
 * switch, App info, the per-app page, App info details, App storage),
 * Location, Security, Accessibility with Audio adjustment, Health profile,
 * Assistant, Safety & Emergency, the deep links and the removal of the quick
 * settings editor.
 * FP-S2: the screen lock set-up flows of Security against the launcher's Lock
 * object (CR-06), modelled by Backend.lockCall.
 * FP-S4: the Accessibility rows of the launcher's a11y keys (CR-34): each
 * writes its key with the type and range of the contract.
 */

import QtQuick
import QtTest
import SettingsTest
import org.asteroid.controls
import "../src/qml/AppFormat.js" as AppFormat
import "../src/qml/lock.js" as Lock

SettingsHarness {
    id: h
    shots: "/tmp/w3ap-shots"

    TestCase {
        name: "SettingsAppsPrivacy"
        when: windowShown

        readonly property string kShowNow: "/org/asteroidos/notifications/show-immediately"
        readonly property string kDisabled: "/org/asteroidos/notifications/disabled-apps"
        readonly property string kBlocked: "/org/asteroidos/notifications/blocked-packages"
        readonly property string kKnown: "/org/asteroidos/notifications/known-apps"
        readonly property string kHidden: "/org/asteroidos/launcher/hidden-apps"
        readonly property string kLocation: "/org/asteroidos/settings/location-enabled"
        readonly property string kReduce: "/org/asteroidos/a11y/reduce-motion"
        readonly property string kAudioSupported: "/org/asteroidos/a11y/audio-adjust-supported"
        readonly property string kMag: "/org/asteroidos/a11y/magnification"
        readonly property string kMagScale: "/org/asteroidos/a11y/magnification-scale"
        readonly property string kMagEdge: "/org/asteroidos/a11y/magnification-edge-haptic"
        readonly property string kCc: "/org/asteroidos/a11y/color-correction"
        readonly property string kCcMode: "/org/asteroidos/a11y/color-correction-mode"
        readonly property string kVw: "/org/asteroidos/a11y/vibration-watch"
        readonly property string kVwType: "/org/asteroidos/a11y/vibration-watch-type"
        readonly property string kVwSpeed: "/org/asteroidos/a11y/vibration-watch-speed"
        readonly property string kPowerEnds: "/org/asteroidos/a11y/power-button-ends-call"
        readonly property string kSr: "/org/asteroidos/a11y/screen-reader"
        readonly property string kSrShortcut: "/org/asteroidos/a11y/screen-reader-button-shortcut"
        readonly property string kSrSupported: "/org/asteroidos/a11y/screen-reader-supported"
        readonly property string kUiOpen: "/org/asteroidos/settings/ui/open"
        readonly property string kUiOpenApp: "/org/asteroidos/settings/ui/open-app"
        readonly property string kMono: "/org/asteroidos/a11y/mono-audio"
        readonly property string kBalance: "/org/asteroidos/a11y/audio-balance"
        readonly property string kGender: "/org/asteroidos/health/profile/gender"
        readonly property string kHeight: "/org/asteroidos/health/profile/height-cm"
        readonly property string kWeight: "/org/asteroidos/health/profile/weight-kg"
        readonly property string kAssistant: "/org/asteroidos/assistant/enabled"
        readonly property string kHold: "/org/asteroidos/assistant/press-and-hold"
        readonly property string kSpeak: "/org/asteroidos/assistant/speak"
        readonly property string kRecognition: "/org/asteroidos/voice/recognition"
        readonly property string kSos: "/org/asteroidos/safety/sos-enabled"
        readonly property string kSosStart: "/org/asteroidos/safety/sos-start"
        readonly property string kSosNumber: "/org/asteroidos/safety/sos-number"
        readonly property string kSosSound: "/org/asteroidos/safety/sos-countdown-sound"

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
        function toast() { return h.find(h.app, "toast") }
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
                else if (c.hasOwnProperty("stepSize"))
                    out.push("slider:" + c.objectName)
                else if (c.hasOwnProperty("control") && c.hasOwnProperty("summary"))
                    out.push("row:" + c.title)
                else if (c.text !== undefined)
                    out.push("text:" + c.text)
            }
            return out
        }
        // the titles of the app rows of a list page
        function titles(objectName) {
            var rows = h.findAll(h.current(), function (o) { return o.objectName === objectName })
            var out = []
            for (var i = 0; i < rows.length; i++)
                out.push(rows[i].title)
            return out
        }
        function summaries(objectName) {
            var rows = h.findAll(h.current(), function (o) { return o.objectName === objectName })
            var out = []
            for (var i = 0; i < rows.length; i++)
                out.push(rows[i].summary)
            return out
        }
        function choices() {
            var list = h.find(h.current(), "choiceList")
            var out = []
            for (var i = 0; i < list.model; i++)
                out.push(list.textOf(i))
            return out
        }
        function choiceNotes() {
            var list = h.find(h.current(), "choiceList")
            var out = []
            for (var i = 0; i < list.model; i++)
                out.push(list.summaryOf(i))
            return out
        }
        function pick(item, index) {
            h.tap(this, chip(item))
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), index))
            h.settle(this)
        }
        function openApp(name) {
            var rows = h.findAll(h.current(), function (o) { return o.title === name && o.hasOwnProperty("control") })
            verify(rows.length > 0, "no row " + name)
            h.tap(this, rows[0])
            h.settle(this)
        }

        // ---- the main list (settings-b-07, -08, -10, -30, -09)

        function test_01_main_list_entries() {
            var col = h.find(h.current(), "settingsColumn")
            var out = []
            for (var i = 0; i < col.children.length; i++)
                if (col.children[i].visible && col.children[i].hasOwnProperty("control"))
                    out.push(col.children[i].title)
            // Health profile after General, then Location, Safety & Emergency,
            // Accessibility, Security, then System (stock Pixel Watch order)
            var from = out.indexOf("General")
            compare(out.slice(from, from + 7),
                    ["General", "Health profile", "Location", "Safety & Emergency", "Accessibility", "Security", "System"])
        }

        // ---- Apps & notifications (settings-b-02)

        function test_02_apps_rows() {
            open(["appsItem"])
            compare(h.current().objectName, "appsPage")
            compare(title(), "Apps & notifications")
            // stock order, no icons; Assistant last
            compare(shownRows(h.current()), ["row:Notifications", "row:App info", "row:App storage", "row:Assistant"])
            var names = ["notificationsItem", "appInfoItem", "appStorageItem", "assistantItem"]
            for (var i = 0; i < names.length; i++)
                compare(chip(names[i]).iconName, "", names[i] + " has no icon")
            verify(chip("dndItem") === null)
            h.shot(this, "apps-02-page")
        }

        // ---- Notifications (heads-up-alerts-06)

        function test_03_notifications_page() {
            open(["appsItem", "notificationsItem"])
            compare(h.current().objectName, "notificationsPage")
            compare(title(), "Notifications")
            compare(shownRows(h.current()), ["row:App notifications", "row:Show new notifications"])
            // default: On wrist raise (Q6)
            compare(chip("showNewItem").summary, "On wrist raise")
            verify(!has(kShowNow) || conf(kShowNow) === false)
            h.tap(this, chip("showNewItem"))
            h.settle(this)
            compare(h.chooser().title, "Show new notifications")
            compare(choices(), ["On wrist raise", "Immediately"])
            compare(choiceNotes(), ["(recommended)", "(reduces battery life)"])
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 1))
            h.settle(this)
            compare(conf(kShowNow), true)
            compare(chip("showNewItem").summary, "Immediately")
            pick("showNewItem", 0)
            compare(conf(kShowNow), false)
            compare(chip("showNewItem").summary, "On wrist raise")
            h.shot(this, "notifications-03-page")
        }

        function test_04_app_notifications_list() {
            Backend.confSet(kKnown, ["com.example.chat|Chat", "com.example.mail|Mail", "com.example.chat|Chat again"])
            open(["appsItem", "notificationsItem", "appNotificationsItem"])
            compare(h.current().objectName, "appNotificationsPage")
            compare(title(), "App notifications")
            compare(shownRows(h.current())[0], "row:Show apps")
            compare(chip("showAppsItem").summary, "All apps")
            // watch apps, then the phone apps by name, a package once
            compare(titles("appNotificationItem"),
                    ["Alarm clock", "Timer", "Stopwatch", "Exercise", "Assistant", "System updates", "Battery", "Bluetooth",
                     "Chat", "Mail"])
            // no row has a second line
            compare(summaries("appNotificationItem").filter(function (s) { return s !== "" }).length, 0)
            // the filter: Core system apps, Notifications off
            h.tap(this, chip("showAppsItem"))
            h.settle(this)
            compare(choices(), ["All apps", "Notifications off", "Core system apps"])
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 2))
            h.settle(this)
            compare(chip("showAppsItem").summary, "Core system apps")
            compare(titles("appNotificationItem"), ["System updates", "Battery", "Bluetooth"])
            pick("showAppsItem", 1)
            compare(titles("appNotificationItem"), [])
            pick("showAppsItem", 0)
            compare(titles("appNotificationItem").length, 10)
            h.shot(this, "notifications-04-apps")
        }

        function test_05_app_notification_switch() {
            Backend.confSet(kKnown, ["com.example.chat|Chat"])
            open(["appsItem", "notificationsItem", "appNotificationsItem"])
            // a watch app: the key of the launcher's notification manager
            openApp("Alarm clock")
            compare(h.current().objectName, "appNotificationPage")
            compare(title(), "Notifications")
            compare(shownRows(h.current()), ["category:Alarm clock", "row:On", "category:Live updates", "row:On",
                                             "text:Display ongoing, time-sensitive notifications on the watch face"])
            var sw = chip("appNotificationSwitch")
            verify(sw.checked)
            h.tap(this, sw)
            compare(conf(kDisabled), ["asteroid-alarmclock"])
            compare(sw.title, "Off")
            verify(!sw.checked)
            h.back(this)
            // the filter finds it
            pick("showAppsItem", 1)
            compare(titles("appNotificationItem"), ["Alarm clock"])
            openApp("Alarm clock")
            h.tap(this, chip("appNotificationSwitch"))
            compare(conf(kDisabled), [])
            compare(chip("appNotificationSwitch").title, "On")
            h.back(this)
            // a phone app: the package, for btsyncd to mute
            pick("showAppsItem", 0)
            openApp("Chat")
            compare(shownRows(h.current()), ["category:Chat", "row:On"])
            h.tap(this, chip("appNotificationSwitch"))
            compare(conf(kBlocked), ["com.example.chat"])
            compare(conf(kDisabled), [])
            h.back(this)
            pick("showAppsItem", 1)
            compare(titles("appNotificationItem"), ["Chat"])
        }

        // ---- App info (settings-b-05)

        function test_06_app_info_list() {
            open(["appsItem", "appInfoItem"])
            compare(h.current().objectName, "appInfoPage")
            compare(title(), "App info")
            compare(chip("showAppsItem").summary, "Installed apps")
            compare(titles("appItem"), ["Alarm clock", "Assistant", "Settings", "Weather"])
            h.tap(this, chip("showAppsItem"))
            h.settle(this)
            compare(choices(), ["Installed apps", "System apps"])
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 1))
            h.settle(this)
            compare(chip("showAppsItem").summary, "System apps")
            // the services whose package is installed (no eos-weather here)
            compare(titles("appItem"), ["Phone sync", "Sensor logger", "System updates"])
            h.shot(this, "appinfo-06-list")
        }

        function test_07_app_page_disable_enable() {
            open(["appsItem", "appInfoItem"])
            openApp("Weather")
            compare(h.current().objectName, "appDetailPage")
            compare(title(), "Weather")
            compare(shownRows(h.current()), ["row:Disable", "row:Force stop", "row:App info"])
            verify(chip("disableItem").active)
            h.tap(this, chip("disableItem"))
            h.settle(this)
            compare(dialogText(), ["Disable?", "Other apps may be affected."])
            reject()
            h.settle(this)
            verify(!has(kHidden) || conf(kHidden).length === 0)
            h.tap(this, chip("disableItem"))
            h.settle(this)
            accept()
            h.settle(this)
            compare(conf(kHidden), ["asteroid-weather"])
            compare(chip("disableItem").title, "Enable")
            h.tap(this, chip("disableItem"))
            h.settle(this)
            compare(dialogText()[0], "Enable?")
            accept()
            h.settle(this)
            compare(conf(kHidden), [])
            compare(chip("disableItem").title, "Disable")
            h.shot(this, "appinfo-07-page")
        }

        function test_08_settings_cannot_be_disabled_assistant_cannot_stop() {
            open(["appsItem", "appInfoItem"])
            openApp("Settings")
            // stock cannot_disable_package: greyed
            verify(!chip("disableItem").active)
            verify(chip("forceStopItem").active)
            h.back(this)
            openApp("Assistant")
            // its entry runs no program of its own: nothing to stop
            verify(chip("disableItem").active)
            verify(!chip("forceStopItem").active)
            h.back(this)
            // a service has no Disable row
            pick("showAppsItem", 1)
            openApp("Phone sync")
            compare(shownRows(h.current()), ["row:Force stop", "row:App info"])
            verify(chip("forceStopItem").active)
        }

        function test_09_force_stop() {
            open(["appsItem", "appInfoItem"])
            openApp("Weather")
            verify(chip("forceStopItem").active)
            h.tap(this, chip("forceStopItem"))
            h.settle(this)
            compare(dialogText(), ["Force stop?", "App may not function properly."])
            reject()
            h.settle(this)
            compare(calls("apps", "forceStop").length, 0)
            h.tap(this, chip("forceStopItem"))
            h.settle(this)
            accept()
            compare(calls("apps", "forceStop"), [["asteroid-weather"]])
            // greyed once it is stopped
            tryVerify(function () { return !chip("forceStopItem").active }, 3000)
        }

        function test_10_app_data_page() {
            Backend.inv.sizeDelay = 250
            open(["appsItem", "appInfoItem"])
            openApp("Weather")
            h.tapName(this, "appDataItem")
            compare(h.current().objectName, "appDataPage")
            compare(title(), "App info")
            compare(shownRows(h.current()),
                    ["row:Version", "row:Storage", "row:Data", "row:Cache", "row:Clear data", "row:Clear cache"])
            compare(chip("versionInfo").summary, "1.2-r0")
            // Computing... first
            compare(chip("storageInfo").summary, "Computing…")
            compare(chip("dataInfo").summary, "Computing…")
            compare(chip("cacheInfo").summary, "Computing…")
            tryCompare(chip("storageInfo"), "summary", "900 kB", 3000)
            compare(chip("dataInfo").summary, "1.5 MB")
            compare(chip("cacheInfo").summary, "4.2 MB")
            verify(!chip("versionInfo").clickable)
            // the names the app keeps files under: its entry, its program, its package
            var req = calls("apps", "computeSizes")[0]
            compare(req[0], "asteroid-weather")
            compare(req[1], ["asteroid-weather"])
            compare(req[2], "asteroid-weather")
            h.shot(this, "appinfo-10-data")
            // Clear cache: no question, a toast
            h.tap(this, chip("clearCacheItem"))
            compare(calls("apps", "clearCache"), [[["asteroid-weather"]]])
            compare(h.find(h.app, "toastText").text, "Cache cleared")
            tryCompare(chip("cacheInfo"), "summary", "0 B", 3000)
            // Clear data: the stock question first
            h.tap(this, chip("clearDataItem"))
            h.settle(this)
            compare(dialogText(), ["Delete app data?",
                    "All this app's data will be permanently deleted. This includes all files, settings, accounts, databases, etc."])
            reject()
            h.settle(this)
            compare(calls("apps", "clearData").length, 0)
            h.tap(this, chip("clearDataItem"))
            h.settle(this)
            accept()
            compare(calls("apps", "clearData"), [[["asteroid-weather"]]])
            compare(h.find(h.app, "toastText").text, "Data cleared")
            tryCompare(chip("dataInfo"), "summary", "0 B", 3000)
        }

        // ---- App storage (settings-b-06)

        function test_11_app_storage() {
            open(["appsItem", "appStorageItem"])
            compare(h.current().objectName, "appStoragePage")
            compare(title(), "Storage")
            var sw = chip("sortSwitch")
            compare(sw.title, "Data size")
            verify(sw.checked)
            // by data size, largest first; one decimal under 10 MB, none from 10
            tryVerify(function () { return titles("storageItem")[0] === "Assistant" }, 3000)
            compare(titles("storageItem"), ["Assistant", "Weather", "Alarm clock", "Settings"])
            compare(summaries("storageItem"), ["25 MB", "1.5 MB", "12 kB", "2.0 kB"])
            h.tap(this, sw)
            compare(conf("/org/asteroidos/settings/app-storage-sort"), "app")
            compare(sw.title, "App size")
            verify(!sw.checked)
            compare(titles("storageItem"), ["Assistant", "Settings", "Weather", "Alarm clock"])
            compare(summaries("storageItem"), ["8.0 MB", "1.5 MB", "900 kB", "400 kB"])
            h.shot(this, "storage-11-page")
            // a row opens the app's page
            openApp("Weather")
            compare(h.current().objectName, "appDetailPage")
        }

        function test_12_storage_computing_first() {
            Backend.inv.sizeDelay = 1500
            open(["appsItem", "appStorageItem"])
            // by name, "Computing..." until every sum is in
            compare(titles("storageItem"), ["Alarm clock", "Assistant", "Settings", "Weather"])
            compare(summaries("storageItem"), ["Computing…", "Computing…", "Computing…", "Computing…"])
            tryVerify(function () { return titles("storageItem")[0] === "Assistant" }, 5000)
            compare(summaries("storageItem"), ["25 MB", "1.5 MB", "12 kB", "2.0 kB"])
        }

        function test_13_format_size() {
            compare(AppFormat.formatSize(0, "."), "0 B")
            compare(AppFormat.formatSize(512, "."), "512 B")
            compare(AppFormat.formatSize(900, "."), "900 B")
            compare(AppFormat.formatSize(950, "."), "0.95 kB")
            compare(AppFormat.formatSize(2000, "."), "2.0 kB")
            compare(AppFormat.formatSize(12000, "."), "12 kB")
            compare(AppFormat.formatSize(1500000, "."), "1.5 MB")
            compare(AppFormat.formatSize(9500000, "."), "9.5 MB")
            compare(AppFormat.formatSize(12000000, "."), "12 MB")
            compare(AppFormat.formatSize(25000000, "."), "25 MB")
            compare(AppFormat.formatSize(3200000000, "."), "3.2 GB")
            compare(AppFormat.formatSize(1500000, ","), "1,5 MB")
            compare(AppFormat.formatSize(undefined, "."), "0 B")
            // the lists
            compare(AppFormat.plus(["a"], "b"), ["a", "b"])
            compare(AppFormat.plus(["a"], "a"), ["a"])
            compare(AppFormat.minus(["a", "b"], "a"), ["b"])
            compare(AppFormat.asList(undefined), [])
            var known = AppFormat.parseKnown(["z.pkg|Zed", "a.pkg|Alpha", "z.pkg|Again", "bare.pkg", "|none"])
            compare(known.map(function (k) { return k.id }), ["a.pkg", "bare.pkg", "z.pkg"])
            compare(known.map(function (k) { return k.name }), ["Alpha", "bare.pkg", "Zed"])
        }

        // ---- Location (settings-b-08)

        function test_14_location() {
            open(["locationItem"])
            compare(h.current().objectName, "locationPage")
            compare(title(), "Location")
            // on by default (def_location_mode 3), "From phone & watch", no footer
            compare(shownRows(h.current()), ["row:Use location"])
            var sw = chip("useLocationSwitch")
            compare(sw.summary, "From phone & watch")
            verify(sw.checked)
            h.tap(this, sw)
            compare(conf(kLocation), false)
            verify(!sw.checked)
            compare(shownRows(h.current()),
                    ["row:Use location",
                     "text:Location access is off for apps and services. Your device location may still be sent to emergency responders when you call or text an emergency number."])
            h.shot(this, "location-14-off")
            h.tap(this, sw)
            compare(conf(kLocation), true)
            compare(shownRows(h.current()), ["row:Use location"])
        }

        // ---- Security (settings-b-07, accessibility-lock-security-09) and the
        // screen lock set-up flows (FP-S2, CR-06): the page talks to the
        // launcher's session bus object org.asteroidos.launcher.Lock, modelled
        // by Backend.lockCall (records every call, answers the result codes)

        readonly property string kLockService: "org.asteroidos.launcher"
        readonly property string kLockIface: "org.asteroidos.launcher.Lock"

        // the arguments of each call made to the Lock object
        function lockCalls(method) {
            var out = []
            for (var i = 0; i < Backend.calls.length; i++) {
                var c = Backend.calls[i]
                if (c.target === kLockService && (method === undefined || c.method === kLockIface + "." + method))
                    out.push(c.args)
            }
            return out
        }
        function lockMethods() {
            var out = []
            for (var i = 0; i < Backend.calls.length; i++)
                if (Backend.calls[i].target === kLockService)
                    out.push(Backend.calls[i].method.substring(kLockIface.length + 1))
            return out
        }
        function flow() { return h.current() }
        function prompt() { return h.find(h.current(), "lockPrompt").text }
        function typeDigits(digits) {
            for (var i = 0; i < digits.length; i++)
                h.tapName(this, "pinKey_" + digits[i])
            wait(50)
        }
        // the dots in order: a finger down on the first and moved over each
        function draw(dots) {
            var pad = h.find(h.current(), "patternPad")
            var c = pad.dotCenter(dots[0])
            pad.touchDown(c.x, c.y)
            for (var i = 1; i < dots.length; i++) {
                c = pad.dotCenter(dots[i])
                pad.touchMove(c.x, c.y)
            }
            pad.touchUp()
            wait(50)
        }
        function openSecurity() {
            open(["securityItem"])
            compare(h.current().objectName, "securityPage")
        }
        // Screen lock row -> the kind in the selection dialog (0 Pattern, 1 PIN, 2 None)
        function chooseLock(index) {
            h.tap(this, chip("screenLockItem"))
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), index))
            h.settle(this)
        }
        function noLockKeys() {
            var keys = ["/org/asteroidos/security/lock-type", "/org/asteroidos/security/lock-request",
                        "/org/asteroidos/security/lock-now"]
            for (var i = 0; i < keys.length; i++) {
                verify(!has(keys[i]), keys[i] + " was written")
                for (var j = 0; j < Backend.calls.length; j++)
                    verify(!(Backend.calls[j].target === "dconf" && Backend.calls[j].method === keys[i]), keys[i])
            }
        }

        function test_15_security_default() {
            openSecurity()
            compare(title(), "Security")
            // no lock: Screen lock "Off", no Lock screen now
            compare(shownRows(h.current()), ["row:Screen lock"])
            compare(chip("screenLockItem").summary, "Off")
            // the state is asked of the launcher's name on the session bus (CR-01, CR-06)
            compare(h.app.showTime, true)
            compare(lockMethods(), ["State"])
            compare(Backend.lockBus, 1)
            compare(Backend.lockSigs["State"], "")
            h.tap(this, chip("screenLockItem"))
            h.settle(this)
            compare(h.chooser().title, "Screen lock")
            compare(choices(), ["Pattern", "PIN", "None"])
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 1))
            h.settle(this)
            // the set-up flow opens over the page; nothing was written to dconf
            compare(h.current().objectName, "lockFlowPage")
            compare(h.current().kind, "pin")
            compare(h.current().step, "enter")
            compare(prompt(), "Choose a PIN")
            // the pad is full screen: no clock over it
            compare(h.app.showTime, false)
            noLockKeys()
            h.shot(this, "security-15-choose-pin")
            h.back(this)
            compare(h.app.showTime, true)
        }

        function test_16_security_with_lock() {
            Backend.lockKind = "pattern"
            Backend.lockSecret = "0145"
            openSecurity()
            compare(shownRows(h.current()), ["row:Screen lock", "row:Lock screen now"])
            compare(chip("screenLockItem").summary, "Pattern")
            // the current one is not asked again
            var depth = h.stack.layers.length
            h.tap(this, chip("screenLockItem"))
            h.settle(this)
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 0))
            h.settle(this)
            compare(h.stack.layers.length, depth)
            compare(h.current().objectName, "securityPage")
            // None asks for the current credential first
            chooseLock(2)
            compare(h.current().objectName, "lockFlowPage")
            compare(h.current().kind, "none")
            compare(h.current().step, "verify")
            compare(prompt(), "Enter your pattern")
            verify(h.find(h.current(), "patternPad").visible)
            verify(!h.find(h.current(), "pinPad").visible)
            compare(lockCalls("Clear").length, 0)
            noLockKeys()
            h.shot(this, "security-16-enter-pattern")
        }

        function test_17_lock_screen_now() {
            Backend.lockKind = "pin"
            Backend.lockSecret = "1234"
            openSecurity()
            compare(chip("screenLockItem").summary, "PIN")
            h.tap(this, chip("lockNowItem"))
            h.settle(this)
            compare(dialogText()[0], "Lock screen now")
            reject()
            h.settle(this)
            compare(lockCalls("Lock").length, 0)
            h.tap(this, chip("lockNowItem"))
            h.settle(this)
            accept()
            // Lock() of the launcher, no dconf key; Settings ends so that the lock shows
            compare(lockCalls("Lock").length, 1)
            compare(Backend.lockSigs["Lock"], "")
            compare(Backend.lockLocked, true)
            noLockKeys()
            tryCompare(h, "closeCount", 1, 2000)
            h.shot(this, "security-17-lock-now")
        }

        // StateChanged(s) of the launcher reaches rcStateChanged (CR-06, rule 5)
        function test_17a_state_changed_signal() {
            openSecurity()
            compare(chip("screenLockItem").summary, "Off")
            Backend.lockSet("pin", "", "4321")
            wait(50)
            compare(chip("screenLockItem").summary, "PIN")
            compare(shownRows(h.current()), ["row:Screen lock", "row:Lock screen now"])
            Backend.lockCall("Clear", ["4321"])
            wait(50)
            compare(chip("screenLockItem").summary, "Off")
            compare(shownRows(h.current()), ["row:Screen lock"])
        }

        function test_17b_launcher_not_there() {
            Backend.lockAvailable = false
            openSecurity()
            // not asked of anything else: the row says nothing and the tap says why
            compare(chip("screenLockItem").summary, "")
            h.tap(this, chip("screenLockItem"))
            h.settle(this)
            verify(!h.chooser().shown)
            compare(toast().visible, true)
            compare(h.find(toast(), "toastText").text, "Screen lock is not available")
            // it came up meanwhile: the next tap works
            Backend.lockAvailable = true
            wait(2300)
            h.tap(this, chip("screenLockItem"))
            h.settle(this)
            compare(chip("screenLockItem").summary, "Off")
        }

        function test_17c_set_pin() {
            openSecurity()
            chooseLock(1)
            compare(prompt(), "Choose a PIN")
            typeDigits("1234")
            compare(flow().step, "confirm")
            compare(prompt(), "Confirm your PIN")
            compare(lockCalls("SetPin").length, 0)
            typeDigits("1234")
            // saved with no old credential, back on the Security page showing PIN
            compare(lockCalls("SetPin"), [["", "1234"]])
            compare(Backend.lockSigs["SetPin"], "ss")
            compare(lockCalls("Verify").length, 0)
            compare(Backend.lockKind, "pin")
            tryVerify(function () { return h.current().objectName === "securityPage" }, 2000)
            compare(chip("screenLockItem").summary, "PIN")
            compare(shownRows(h.current()), ["row:Screen lock", "row:Lock screen now"])
            noLockKeys()
        }

        function test_17d_pin_mismatch() {
            openSecurity()
            chooseLock(1)
            typeDigits("1234")
            typeDigits("1235")
            // says so and starts the entry over; nothing was sent
            compare(prompt(), "PINs don't match")
            compare(flow().step, "enter")
            compare(lockCalls("SetPin").length, 0)
            h.shot(this, "security-17d-mismatch")
            // the next digit takes the message away
            typeDigits("9")
            compare(prompt(), "Choose a PIN")
            h.find(h.current(), "pinPad").reset()
            typeDigits("1234")
            typeDigits("1234")
            compare(lockCalls("SetPin"), [["", "1234"]])
        }

        function test_17e_pin_is_4_digits() {
            // the pad takes 4 digits, a fifth is refused, back removes one
            var r = Lock.pressKey("1234", "5")
            compare(r.entry, "1234")
            compare(r.submit, false)
            compare(Lock.pressKey("123", "4").submit, true)
            compare(Lock.pressKey("1234", "back").entry, "123")
            compare(Lock.pressKey("12", "enter").submit, false)
            // and a PIN the launcher refuses is Failed to set PIN
            openSecurity()
            chooseLock(1)
            Backend.lockForce = { "SetPin": 4 }
            typeDigits("1234")
            typeDigits("1234")
            compare(lockCalls("SetPin").length, 1)
            compare(prompt(), "Failed to set PIN")
            compare(flow().step, "enter")
            compare(Backend.lockKind, "none")
            wait(600)
        }

        function test_17f_set_pattern() {
            openSecurity()
            chooseLock(0)
            compare(flow().kind, "pattern")
            compare(prompt(), "Draw an unlock pattern")
            // 3 dots: not a try
            draw([0, 1, 2])
            compare(prompt(), "Connect at least 4 dots")
            compare(flow().step, "enter")
            compare(lockCalls().length, 1)       // State only
            h.shot(this, "security-17f-too-short")
            draw([0, 1, 4, 5])
            compare(flow().step, "confirm")
            compare(prompt(), "Draw pattern again to confirm")
            // a different second pattern
            draw([0, 1, 4, 7])
            compare(prompt(), "Patterns don't match")
            compare(flow().step, "enter")
            compare(lockCalls("SetPattern").length, 0)
            draw([0, 3, 6, 7, 8])
            draw([0, 3, 6, 7, 8])
            compare(lockCalls("SetPattern"), [["", "03678"]])
            compare(Backend.lockSigs["SetPattern"], "ss")
            compare(Backend.lockKind, "pattern")
            tryVerify(function () { return h.current().objectName === "securityPage" }, 2000)
            compare(chip("screenLockItem").summary, "Pattern")
            noLockKeys()
        }

        function test_17g_change_asks_the_current_credential() {
            Backend.lockKind = "pin"
            Backend.lockSecret = "1234"
            openSecurity()
            chooseLock(0)
            compare(flow().step, "verify")
            compare(prompt(), "Enter your PIN")
            // wrong: the launcher counted it, the step stays
            typeDigits("1111")
            compare(lockCalls("Verify"), [["1111"]])
            compare(Backend.lockSigs["Verify"], "s")
            compare(prompt(), "Wrong PIN")
            compare(flow().step, "verify")
            compare(lockCalls("SetPattern").length, 0)
            h.shot(this, "security-17g-wrong-pin")
            typeDigits("1234")
            compare(flow().step, "enter")
            compare(prompt(), "Draw an unlock pattern")
            verify(h.find(h.current(), "patternPad").visible)
            draw([1, 4, 7, 8])
            draw([1, 4, 7, 8])
            // the old PIN rides along as `old`
            compare(lockCalls("SetPattern"), [["1234", "1478"]])
            compare(Backend.lockKind, "pattern")
            tryVerify(function () { return h.current().objectName === "securityPage" }, 2000)
            compare(chip("screenLockItem").summary, "Pattern")
        }

        function test_17h_none_asks_first_then_clears() {
            Backend.lockKind = "pattern"
            Backend.lockSecret = "0145"
            openSecurity()
            chooseLock(2)
            compare(flow().step, "verify")
            draw([0, 1, 4, 7])
            compare(prompt(), "Wrong pattern")
            compare(lockCalls("Clear").length, 0)
            compare(Backend.lockKind, "pattern")
            draw([0, 1, 4, 5])
            compare(lockCalls("Clear"), [["0145"]])
            compare(Backend.lockSigs["Clear"], "s")
            compare(Backend.lockKind, "none")
            tryVerify(function () { return h.current().objectName === "securityPage" }, 2000)
            compare(chip("screenLockItem").summary, "Off")
            compare(shownRows(h.current()), ["row:Screen lock"])
        }

        // the wait after too many wrong tries: the pad is off, the countdown shows
        function test_17i_throttled() {
            Backend.lockKind = "pin"
            Backend.lockSecret = "1234"
            Backend.lockMaxTries = 2
            Backend.lockWaitMs = 125000
            openSecurity()
            chooseLock(2)
            typeDigits("1111")
            compare(prompt(), "Wrong PIN")
            typeDigits("2222")
            // the second one began the wait (Verify answered 1, Remaining says 125 s)
            tryCompare(flow(), "waiting", true, 2000)
            compare(prompt(), "Try again in 2 min 05 sec")
            compare(h.find(h.current(), "pinPad").inputEnabled, false)
            var n = lockCalls("Verify").length
            typeDigits("1234")
            compare(lockCalls("Verify").length, n)
            h.shot(this, "security-17i-throttled")
            // the wait is over: the pad is back
            Backend.lockRemaining = 0
            flow().updateWait()
            tryCompare(flow(), "waiting", false, 2000)
            compare(h.find(h.current(), "pinPad").inputEnabled, true)
            compare(prompt(), "Enter your PIN")
            typeDigits("1234")
            compare(lockCalls("Clear"), [["1234"]])
        }

        function test_17j_result_codes_of_verify() {
            Backend.lockKind = "pin"
            Backend.lockSecret = "1234"
            openSecurity()
            // 2: the launcher is inside a wait already (a try is not counted)
            chooseLock(0)
            Backend.lockForce = { "Verify": 2 }
            Backend.lockRemaining = 12000
            typeDigits("1234")
            tryCompare(flow(), "waiting", true, 2000)
            compare(prompt(), "Try again in 12 sec")
            compare(flow().step, "verify")
            // 4: refused, treated as wrong
            Backend.lockRemaining = 0
            flow().updateWait()
            tryCompare(flow(), "waiting", false, 2000)
            Backend.lockForce = { "Verify": 4 }
            typeDigits("1234")
            compare(prompt(), "Wrong PIN")
            compare(flow().step, "verify")
            // 3: no credential any more: nothing to confirm, on to the new one
            Backend.lockForce = { "Verify": 3 }
            typeDigits("1234")
            compare(flow().step, "enter")
            compare(flow().oldKind, "none")
            compare(prompt(), "Draw an unlock pattern")
        }

        function test_17k_result_codes_of_save() {
            // a pattern in force, a PIN being set
            Backend.lockKind = "pattern"
            Backend.lockSecret = "0145"
            openSecurity()
            chooseLock(1)
            draw([0, 1, 4, 5])
            compare(flow().step, "enter")
            // 1: the credential in force changed under us: asked for again
            Backend.lockForce = { "SetPin": 1 }
            typeDigits("5678")
            typeDigits("5678")
            compare(lockCalls("SetPin").length, 1)
            compare(flow().step, "verify")
            compare(prompt(), "Wrong pattern")
            Backend.lockForce = {}
            draw([0, 1, 4, 5])
            compare(flow().step, "enter")
            // 3: no credential any more: set again with no old one
            Backend.lockForce = { "SetPin": 3 }
            typeDigits("5678")
            typeDigits("5678")
            var sets = lockCalls("SetPin")
            compare(sets[sets.length - 2], ["0145", "5678"])
            compare(sets[sets.length - 1], ["", "5678"])
            compare(flow().step, "enter")
            compare(prompt(), "Failed to set PIN")
            // 4 on a pattern: Failed to set lock pattern.
            h.home(this)
            Backend.lockForce = {}
            Backend.lockKind = "none"
            openSecurity()
            chooseLock(0)
            Backend.lockForce = { "SetPattern": 4 }
            draw([0, 1, 4, 5])
            draw([0, 1, 4, 5])
            compare(prompt(), "Failed to set lock pattern.")
            compare(flow().step, "enter")
            wait(2300)
        }

        function test_17l_launcher_gone_in_the_flow() {
            openSecurity()
            chooseLock(1)
            typeDigits("1234")
            Backend.lockAvailable = false
            typeDigits("1234")
            compare(prompt(), "Screen lock is not available")
            compare(flow().busy, false)
            noLockKeys()
            wait(600)
        }

        // the three dconf keys of the old design are gone from the sources, and
        // so is the old session name
        function test_17m_old_keys_removed() {
            var files = ["SecurityPage.qml", "LockFlowPage.qml"]
            for (var i = 0; i < files.length; i++) {
                var x = new XMLHttpRequest()
                x.open("GET", Qt.resolvedUrl("../src/qml/" + files[i]), false)
                x.send()
                var text = x.responseText
                verify(text.length > 100, files[i])
                verify(text.indexOf("/org/asteroidos/security/") < 0, files[i] + ": a security dconf key")
                verify(text.indexOf("ConfigurationValue") < 0, files[i] + ": no dconf at all")
                verify(text.indexOf("org.nemomobile.lipstick") < 0, files[i] + ": the old session name")
                verify(text.indexOf("org.asteroidos.launcher") >= 0, files[i] + ": " + (i === 0 ? "the session name" : "iface"))
            }
        }

        // ---- Accessibility (settings-b-10, accessibility-lock-security-20)

        function test_18_accessibility_page() {
            // the gate is true: the audio helper is installed (CR-33)
            Backend.confSet(kAudioSupported, true)
            open(["accessibilityItem"])
            compare(h.current().objectName, "accessibilityPage")
            compare(title(), "Accessibility")
            compare(shownRows(h.current()),
                    ["category:Display", "row:Magnification", "row:Text size", "row:Color correction",
                     "row:Reduce animations", "text:Reduce movement on the screen",
                     "category:General", "row:Audio adjustment", "row:Gestures", "row:Vibration watch",
                     "row:Power button ends call"])
            compare(chip("audioAdjustmentItem").summary, "Mono audio, Audio balance")
            // Reduce animations: off by default, the key the springs read
            var sw = chip("reduceAnimationsSwitch")
            verify(!sw.checked)
            h.tap(this, sw)
            compare(conf(kReduce), true)
            verify(sw.checked)
            h.tap(this, sw)
            compare(conf(kReduce), false)
            h.shot(this, "accessibility-18-page")
        }

        // CR-33: no Audio adjustment row until the audio helper sets the gate
        function test_18b_audio_adjustment_gate() {
            open(["accessibilityItem"])
            compare(shownRows(h.current()),
                    ["category:Display", "row:Magnification", "row:Text size", "row:Color correction",
                     "row:Reduce animations", "text:Reduce movement on the screen",
                     "category:General", "row:Gestures", "row:Vibration watch", "row:Power button ends call"])
            verify(!chip("audioAdjustmentItem").visible)
            Backend.confSet(kAudioSupported, true)
            verify(chip("audioAdjustmentItem").visible)
            Backend.confSet(kAudioSupported, "false")
            verify(!chip("audioAdjustmentItem").visible)
        }

        // CR-34: the screen reader's rows stay hidden while it is not
        // available (the gate a11y/screen-reader-supported)
        function test_18c_screen_reader_gate() {
            open(["accessibilityItem"])
            verify(!chip("screenReaderCategory").visible)
            verify(!chip("screenReaderSwitch").visible)
            verify(!chip("screenReaderShortcutSwitch").visible)
            verify(!chip("screenReaderShortcutCaption").visible)
            Backend.confSet(kSrSupported, true)
            compare(shownRows(h.current()).slice(0, 5),
                    ["category:Screen reader", "row:Use screen reader", "row:Button shortcut",
                     "text:Triple press the side button to turn the screen reader on and off", "category:Display"])
            var sw = chip("screenReaderSwitch")
            verify(!sw.checked)
            h.tap(this, sw)
            compare(conf(kSr), true)
            compare(typeof conf(kSr), "boolean")
            h.tap(this, chip("screenReaderShortcutSwitch"))
            compare(conf(kSrShortcut), true)
            compare(typeof conf(kSrShortcut), "boolean")
            h.tap(this, chip("screenReaderShortcutSwitch"))
            compare(conf(kSrShortcut), false)
            tryVerify(function () { return !h.stack.pushing }, 5000, "the push has settled")
            h.shot(this, "accessibility-18c-screen-reader")
            Backend.confSet(kSrSupported, false)
            verify(!chip("screenReaderSwitch").visible)
            compare(shownRows(h.current())[0], "category:Display")
        }

        // Magnification (CR-34: magnification b, -scale d 1.5..3.0, default
        // 2.0, -edge-haptic b)
        function test_18d_magnification() {
            open(["accessibilityItem"])
            compare(chip("magnificationItem").summary, "Off")
            open(["magnificationItem"])
            compare(h.current().objectName, "magnificationPage")
            compare(title(), "Magnification")
            compare(shownRows(h.current()),
                    ["row:Magnification", "text:Triple tap to zoom. Drag 1 finger to move around the screen",
                     "row:Vibrate on edge", "category:Magnification size", "slider:magnificationSlider", "text:2.0x"])
            tryVerify(function () { return !h.stack.pushing }, 5000, "the push has settled")
            h.shot(this, "accessibility-18d-magnification")
            var sw = chip("magnificationSwitch")
            verify(!sw.checked)
            verify(!chip("edgeHapticSwitch").checked)
            verify(!has(kMagEdge))
            h.tap(this, sw)
            compare(conf(kMag), true)
            compare(typeof conf(kMag), "boolean")
            verify(sw.checked)
            // stock: the first change turns Vibrate on edge on while it was never set
            compare(conf(kMagEdge), true)
            compare(typeof conf(kMagEdge), "boolean")
            verify(chip("edgeHapticSwitch").checked)
            h.tap(this, chip("edgeHapticSwitch"))
            compare(conf(kMagEdge), false)
            h.tap(this, sw)
            compare(conf(kMag), false)
            compare(conf(kMagEdge), false, "once set it stays the user's")
            // the size: seven steps with separators, 2.0x by default
            var s = chip("magnificationSlider")
            compare(s.from, 0)
            compare(s.to, 7)
            compare(s.lowest, 1)
            compare(s.value, 3)
            verify(s.segmented)
            compare(s.valueDescription, "2.0x")
            compare(s.increaseDescription, "Increase magnification size")
            compare(s.decreaseDescription, "Decrease magnification size")
            var scales = [1.5, 1.7, 2.0, 2.2, 2.5, 2.7, 3.0]
            var texts = ["1.5x", "1.7x", "2.0x", "2.2x", "2.5x", "2.7x", "3.0x"]
            for (var i = 1; i <= 7; i++) {
                s.moved(i)
                compare(conf(kMagScale), scales[i - 1], "step " + i)
                compare(typeof conf(kMagScale), "number")
                verify(conf(kMagScale) >= 1.5 && conf(kMagScale) <= 3.0)
                compare(s.value, i)
                compare(chip("magnificationSizeValue").text, texts[i - 1])
            }
            verify(h.scrollToEnd(this), "the page scrolls")
            wait(300)
            h.shot(this, "accessibility-18d-magnification-size")
            // a stored size between steps shows the nearest, nonsense the default
            Backend.confSet(kMagScale, 2.05)
            compare(s.value, 3)
            Backend.confSet(kMagScale, "big")
            compare(s.value, 3)
            h.back(this)
            compare(chip("magnificationItem").summary, "Off")
            Backend.confSet(kMag, true)
            compare(chip("magnificationItem").summary, "On")
        }

        // Color correction (CR-34: color-correction b, -mode s of four)
        function test_18e_color_correction() {
            open(["accessibilityItem", "colorCorrectionItem"])
            compare(h.current().objectName, "colorCorrectionPage")
            compare(title(), "Color correction")
            compare(shownRows(h.current()),
                    ["row:Use color correction", "row:Red-green", "row:Red-green", "row:Blue-yellow", "row:Grayscale"])
            compare(chip("colorCorrection_deuteranomaly").summary, "Green weak, deuteranomaly")
            compare(chip("colorCorrection_protanomaly").summary, "Red weak, protanomaly")
            compare(chip("colorCorrection_tritanomaly").summary, "Tritanomaly")
            compare(chip("colorCorrection_grayscale").summary, "")
            // nothing stored: deuteranomaly (stock's and the launcher's default)
            verify(chip("colorCorrection_deuteranomaly").checked)
            tryVerify(function () { return !h.stack.pushing }, 5000, "the push has settled")
            h.shot(this, "accessibility-18e-color-correction")
            var sw = chip("colorCorrectionSwitch")
            verify(!sw.checked)
            h.tap(this, sw)
            compare(conf(kCc), true)
            compare(typeof conf(kCc), "boolean")
            var modes = ["protanomaly", "tritanomaly", "grayscale", "deuteranomaly"]
            for (var i = 0; i < modes.length; i++) {
                h.tap(this, chip("colorCorrection_" + modes[i]))
                compare(conf(kCcMode), modes[i])
                compare(typeof conf(kCcMode), "string")
                for (var j = 0; j < modes.length; j++)
                    compare(chip("colorCorrection_" + modes[j]).checked, i === j, modes[j])
            }
            // the radios stay enabled with the switch off (no dependency in stock)
            h.tap(this, sw)
            compare(conf(kCc), false)
            verify(chip("colorCorrection_grayscale").active)
            h.tap(this, chip("colorCorrection_grayscale"))
            compare(conf(kCcMode), "grayscale")
            // a mode the launcher does not know reads as deuteranomaly
            Backend.confSet(kCcMode, "sepia")
            verify(chip("colorCorrection_deuteranomaly").checked)
        }

        // Vibration watch (CR-34: vibration-watch b, -type s digits or terse,
        // -speed i 0..4 default 2)
        function test_18f_vibration_watch() {
            open(["accessibilityItem", "vibrationWatchItem"])
            compare(h.current().objectName, "vibrationWatchPage")
            compare(title(), "Vibration watch")
            compare(shownRows(h.current()),
                    ["row:Vibration watch",
                     "text:Get the current time as vibrations. When the screen is on, tap the watch face with 2 fingers to check the time: single tap for the hour, double tap for the minute.",
                     "category:Vibration type", "row:Digits",
                     "text:Vibration watch gives you the current time in decimal format. A long vibration means 10 and a short vibration means 1.",
                     "row:Terse", "text:Vibration watch gives the minutes briefly. Each short vibration means a quarter-hour.",
                     "row:Vibration speed"])
            compare(chip("vibrationSpeedItem").summary, "Medium")
            verify(chip("vibrationTypeDigits").checked)
            // off: the type and the speed grey and still
            verify(!chip("vibrationTypeDigits").active)
            verify(!chip("vibrationTypeTerse").active)
            verify(!chip("vibrationSpeedItem").active)
            h.tap(this, chip("vibrationTypeTerse"))
            verify(!has(kVwType))
            tryVerify(function () { return !h.stack.pushing }, 5000, "the push has settled")
            h.shot(this, "accessibility-18f-vibration-watch-off")
            h.tap(this, chip("vibrationWatchSwitch"))
            compare(conf(kVw), true)
            compare(typeof conf(kVw), "boolean")
            verify(chip("vibrationTypeTerse").active)
            h.tap(this, chip("vibrationTypeTerse"))
            compare(conf(kVwType), "terse")
            compare(typeof conf(kVwType), "string")
            verify(chip("vibrationTypeTerse").checked)
            verify(!chip("vibrationTypeDigits").checked)
            h.tap(this, chip("vibrationTypeDigits"))
            compare(conf(kVwType), "digits")
            // the speed: the stock list, its value 0..4
            h.tap(this, chip("vibrationSpeedItem"))
            h.settle(this)
            compare(choices(), ["Very slow", "Slow", "Medium", "Fast", "Very fast"])
            h.back(this)
            var names = ["Very slow", "Slow", "Medium", "Fast", "Very fast"]
            for (var i = 0; i < 5; i++) {
                pick("vibrationSpeedItem", i)
                compare(conf(kVwSpeed), i)
                verify(typeof conf(kVwSpeed) === "number" && Math.round(conf(kVwSpeed)) === conf(kVwSpeed))
                verify(conf(kVwSpeed) >= 0 && conf(kVwSpeed) <= 4)
                compare(chip("vibrationSpeedItem").summary, names[i])
            }
            tryVerify(function () { return !h.stack.pushing }, 5000, "the push has settled")
            h.shot(this, "accessibility-18f-vibration-watch-on")
            // a speed out of range reads as Medium
            Backend.confSet(kVwSpeed, 9)
            compare(chip("vibrationSpeedItem").summary, "Medium")
        }

        // stock: Vibration watch only while vibration is on (vibrate_on)
        function test_18g_vibration_watch_follows_vibration() {
            open(["accessibilityItem"])
            verify(chip("vibrationWatchItem").visible)
            Backend.confSet("/desktop/asteroid/vibration", false)
            verify(!chip("vibrationWatchItem").visible)
            Backend.confSet("/desktop/asteroid/vibration", true)
            verify(chip("vibrationWatchItem").visible)
        }

        // Power button ends call (CR-34: power-button-ends-call b false)
        function test_18h_power_button_ends_call() {
            open(["accessibilityItem"])
            var sw = chip("powerButtonEndsCallSwitch")
            verify(h.shown(sw))
            verify(!sw.checked)
            h.tap(this, sw)
            compare(conf(kPowerEnds), true)
            compare(typeof conf(kPowerEnds), "boolean")
            verify(sw.checked)
            tryVerify(function () { return !h.stack.pushing }, 5000, "the push has settled")
            h.shot(this, "accessibility-18h-end")
            h.tap(this, sw)
            compare(conf(kPowerEnds), false)
        }

        function test_19_accessibility_links() {
            open(["accessibilityItem", "textSizeItem"])
            compare(h.current().objectName, "displaySizePage")
            h.back(this)
            open(["gesturesItem"])
            compare(h.current().objectName, "gesturesPage")
        }

        function test_20_audio_adjustment() {
            Backend.confSet(kAudioSupported, true)
            open(["accessibilityItem", "audioAdjustmentItem"])
            compare(h.current().objectName, "audioAdjustPage")
            compare(title(), "Audio adjustment")
            compare(shownRows(h.current()),
                    ["row:Mono audio", "text:Combine channels when playing audio", "category:Audio balance",
                     "slider:balanceSlider"])
            var mono = chip("monoSwitch")
            verify(!mono.checked)
            h.tap(this, mono)
            compare(conf(kMono), true)
            verify(mono.checked)
            // nine steps, centred by default
            var slider = chip("balanceSlider")
            compare(slider.from, 0)
            compare(slider.to, 8)
            compare(slider.value, 4)
            compare(slider.valueDescription, "50 percent audio balance")
            var steps = [0, 10, 25, 40, 50, 60, 75, 90, 100]
            for (var i = 0; i < steps.length; i++) {
                slider.moved(i)
                compare(conf(kBalance), steps[i], "step " + i)
                compare(slider.value, i)
            }
            compare(slider.valueDescription, "100 percent audio balance")
            // a stored value between steps shows the nearest
            Backend.confSet(kBalance, 33)
            compare(slider.value, 3)
            compare(h.find(h.current(), "balanceLeft").text, "Left")
            compare(h.find(h.current(), "balanceRight").text, "Right")
            h.shot(this, "audio-20-page")
        }

        // ---- Health profile (settings-b-30)

        function test_21_health_profile_rows() {
            open(["healthProfileItem"])
            compare(h.current().objectName, "healthProfilePage")
            compare(title(), "My profile")
            compare(shownRows(h.current()), ["row:Gender", "row:Height", "row:Weight"])
            // stock's defaults: no gender, 175 cm, 75 kg
            compare(chip("genderItem").summary, "")
            compare(chip("heightItem").summary, "175 cm")
            compare(chip("weightItem").summary, "75 kg")
            Backend.confSet(kHeight, 182)
            Backend.confSet(kWeight, 68.4)
            compare(chip("heightItem").summary, "182 cm")
            compare(chip("weightItem").summary, "68 kg")
            h.shot(this, "profile-21-page")
        }

        function test_22_health_profile_gender() {
            open(["healthProfileItem"])
            h.tap(this, chip("genderItem"))
            h.settle(this)
            compare(h.chooser().title, "Gender")
            compare(choices(), ["Female", "Male", "Non-binary"])
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 1))
            h.settle(this)
            // the values asteroid-sensorlogd reads
            compare(conf(kGender), "male")
            compare(chip("genderItem").summary, "Male")
            pick("genderItem", 0)
            compare(conf(kGender), "female")
            pick("genderItem", 2)
            compare(conf(kGender), "other")
            compare(chip("genderItem").summary, "Non-binary")
        }

        function test_23_health_profile_height_metric() {
            Backend.confSet(kHeight, 182)
            open(["healthProfileItem", "heightItem"])
            compare(h.current().objectName, "profilePickerPage")
            var picker = chip("profilePicker")
            // 30 to 272 cm (stock MIN_CM, MAX_CM), one column
            compare(picker.columns.length, 1)
            compare(picker.columns[0].count, 243)
            compare(picker.columns[0].text(0), "30 cm")
            compare(picker.columns[0].text(242), "272 cm")
            compare(picker.values[0], 152)
            picker.setValue(0, 150, false)
            picker.accepted()
            h.settle(this)
            compare(conf(kHeight), 180)
            compare(h.current().objectName, "healthProfilePage")
            compare(chip("heightItem").summary, "180 cm")
        }

        function test_24_health_profile_height_imperial() {
            open(["healthProfileItem"])
            h.current().imperial = true
            wait(50)
            // 175 cm is 69 inches: 5 ft 9 in
            compare(chip("heightItem").summary, "5 ft 9 in")
            compare(chip("weightItem").summary, "165 lbs")
            h.tap(this, chip("heightItem"))
            h.settle(this)
            var picker = chip("profilePicker")
            compare(picker.columns.length, 2)
            // feet 1-8, inches 0-11
            compare(picker.columns[0].count, 8)
            compare(picker.columns[1].count, 12)
            compare(picker.columns[0].text(0), "1 ft")
            compare(picker.columns[0].text(7), "8 ft")
            compare(picker.columns[1].text(11), "11 in")
            compare(picker.values[0], 4)
            compare(picker.values[1], 9)
            // 6 ft 2 in is 74 inches, 188 cm
            picker.setValue(0, 5, false)
            picker.setValue(1, 2, false)
            picker.accepted()
            h.settle(this)
            compare(conf(kHeight), 188)
            compare(chip("heightItem").summary, "6 ft 2 in")
        }

        function test_25_health_profile_weight() {
            open(["healthProfileItem", "weightItem"])
            var picker = chip("profilePicker")
            // 1 to 907 kg, one column, 75 first
            compare(picker.columns.length, 1)
            compare(picker.columns[0].count, 907)
            compare(picker.columns[0].text(0), "1 kg")
            compare(picker.columns[0].text(906), "907 kg")
            compare(picker.values[0], 74)
            picker.setValue(0, 59, false)
            picker.accepted()
            h.settle(this)
            compare(conf(kWeight), 60)
            compare(chip("weightItem").summary, "60 kg")
            // pounds: 1 to 2000, kept in kilograms
            h.current().imperial = true
            wait(50)
            compare(chip("weightItem").summary, "132 lbs")
            h.tap(this, chip("weightItem"))
            h.settle(this)
            picker = chip("profilePicker")
            compare(picker.columns[0].count, 2000)
            compare(picker.columns[0].text(1999), "2000 lbs")
            picker.setValue(0, 179, false)
            picker.accepted()
            h.settle(this)
            // 180 lbs is 81.6 kg
            compare(conf(kWeight), 81.6)
            compare(chip("weightItem").summary, "180 lbs")
        }

        // ---- Assistant (assistant-voice-22)

        function test_26_assistant_rows() {
            open(["appsItem", "assistantItem"])
            compare(h.current().objectName, "assistantPage")
            compare(title(), "Assistant")
            compare(shownRows(h.current()),
                    ["row:Press & hold", "text:Hold down side button to talk", "category:General",
                     "row:Speech output", "text:Assistant will speak responses, including when Do Not Disturb is on",
                     "row:Voice recognition", "row:Tile actions", "row:About", "row:Turn off Assistant"])
            compare(chip("recognitionItem").summary, "On the watch")
            verify(chip("pressAndHoldSwitch").checked)
            // CR-15: an unset speak reads as on
            verify(!has(kSpeak))
            verify(chip("speechOutputSwitch").checked)
            h.tap(this, chip("pressAndHoldSwitch"))
            compare(conf(kHold), false)
            h.tap(this, chip("pressAndHoldSwitch"))
            compare(conf(kHold), true)
            h.tap(this, chip("speechOutputSwitch"))
            compare(conf(kSpeak), false)
            verify(!chip("speechOutputSwitch").checked)
            h.tap(this, chip("speechOutputSwitch"))
            compare(conf(kSpeak), true)
            pick("recognitionItem", 1)
            compare(conf(kRecognition), "auto")
            h.shot(this, "assistant-26-page")
        }

        function test_27_assistant_turn_off() {
            open(["appsItem", "assistantItem"])
            h.tap(this, chip("turnOffItem"))
            h.settle(this)
            compare(dialogText(), ["Turn off Assistant?",
                    "When turned off, you won't be able to use Assistant to do things like set alarms and timers, message your contacts, and more"])
            reject()
            h.settle(this)
            verify(!has(kAssistant) || conf(kAssistant) === true)
            h.tap(this, chip("turnOffItem"))
            h.settle(this)
            accept()
            compare(conf(kAssistant), false)
            // the others grey, the row offers Turn on
            verify(!chip("pressAndHoldSwitch").active)
            verify(!chip("speechOutputSwitch").active)
            verify(!chip("recognitionItem").active)
            verify(!chip("tileActionsItem").active)
            verify(!chip("pressAndHoldSwitch").checked)
            compare(chip("turnOffItem").title, "Turn on Assistant")
            h.shot(this, "assistant-27-off")
            h.tap(this, chip("turnOffItem"))
            compare(conf(kAssistant), true)
            verify(chip("pressAndHoldSwitch").active)
            compare(chip("turnOffItem").title, "Turn off Assistant")
        }

        function test_28_assistant_about() {
            open(["appsItem", "assistantItem", "aboutItem"])
            compare(h.current().objectName, "assistantAboutPage")
            compare(title(), "About")
            compare(shownRows(h.current())[0], "row:Version")
            verify(!chip("assistantVersion").clickable)
        }

        // ---- Safety & Emergency (settings-b-09, apps-misc-08)

        function test_29_safety_page() {
            open(["safetyItem"])
            compare(h.current().objectName, "safetyPage")
            compare(title(), "Safety & Emergency")
            compare(shownRows(h.current()),
                    ["category:Get help fast", "row:Emergency SOS",
                     "text:You can call for help by quickly pressing the crown 5 times or more",
                     "row:Ways to start SOS", "row:Who to call for help", "row:Countdown alarm"])
            var sos = chip("sosSwitch")
            verify(sos.checked)
            compare(chip("sosStartItem").summary, "Automatically call")
            compare(chip("sosNumberItem").summary, "Local emergency number")
            verify(!chip("sosSoundSwitch").checked)
            compare(chip("sosSoundSwitch").summary, "Play a sound")
            h.shot(this, "safety-29-page")
            // off: the rest is greyed
            h.tap(this, sos)
            compare(conf(kSos), false)
            verify(!chip("sosStartItem").active)
            verify(!chip("sosNumberItem").active)
            verify(!chip("sosSoundSwitch").active)
            h.tap(this, sos)
            verify(chip("sosStartItem").active)
        }

        function test_30_safety_choices() {
            open(["safetyItem"])
            h.tap(this, chip("sosStartItem"))
            h.settle(this)
            compare(h.chooser().title, "Ways to start SOS")
            compare(choices(), ["Automatically call", "Touch & hold to call"])
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 1))
            h.settle(this)
            compare(conf(kSosStart), "hold")
            compare(chip("sosStartItem").summary, "Touch & hold to call")
            h.tap(this, chip("sosSoundSwitch"))
            compare(conf(kSosSound), true)
        }

        function test_31_safety_number() {
            open(["safetyItem", "sosNumberItem"])
            compare(h.current().objectName, "sosNumberPage")
            compare(title(), "Who to call for help")
            var field = chip("sosNumberField")
            compare(chip("sosNumberCaption").text, "Leave empty to call the local emergency number")
            // the local number is the default: nothing to reset
            verify(!h.shown(chip("sosLocalItem")))
            // a dialable number is kept (a made-up one)
            field.text = "0800 1234"
            verify(!has(kSosNumber) || conf(kSosNumber) === "")
            field.text = "+64211234"
            compare(conf(kSosNumber), "+64211234")
            verify(h.shown(chip("sosLocalItem")))
            h.back(this)
            compare(chip("sosNumberItem").summary, "+64211234")
            // back to the local number
            open(["sosNumberItem"])
            compare(chip("sosLocalItem").title, "Use local emergency number")
            h.tap(this, chip("sosLocalItem"))
            compare(conf(kSosNumber), "")
            compare(chip("sosNumberField").text, "")
        }

        // ---- the quick settings editor is gone (quick-settings-24, -25)

        function test_32_no_quick_settings_editor() {
            open(["generalItem"])
            compare(h.current().objectName, "generalPage")
            verify(chip("quickPanelItem") === null)
            var titles = shownRows(h.current())
            verify(titles.indexOf("row:Quick settings") < 0)
        }

        // ---- the deep links (stock route names)

        function test_33_deep_links() {
            var routes = { "notifications": "notificationsPage", "app_notifications": "appNotificationsPage",
                           "app_info": "appInfoPage", "app_storage": "appStoragePage", "assistant": "assistantPage",
                           "health_profile": "healthProfilePage", "location": "locationPage",
                           "safety": "safetyPage", "accessibility": "accessibilityPage",
                           "audio_adjustment": "audioAdjustPage", "security": "securityPage",
                           "magnification": "magnificationPage", "color_correction": "colorCorrectionPage",
                           "vibration_watch": "vibrationWatchPage" }
            for (var r in routes) {
                h.app.openPage(r)
                wait(500)
                compare(h.current().objectName, routes[r], r)
            }
            // the request key the launcher writes
            Backend.confSet("/org/asteroidos/settings/ui/open", "security@" + Date.now())
            wait(500)
            compare(h.current().objectName, "securityPage")
        }

        // ---- app_info with the app the launcher names (CR-17)

        function request(route, age) {
            Backend.confSet(kUiOpen, route + "@" + (Date.now() - (age || 0)))
            wait(500)
            h.settle(this)
        }

        function test_34_app_info_open_app() {
            // the launcher writes the id without ".desktop", then the request
            Backend.confSet(kUiOpenApp, "asteroid-weather")
            request("app_info")
            compare(h.current().objectName, "appDetailPage")
            compare(title(), "Weather")
            // both keys are cleared with the request
            compare(conf(kUiOpen), "")
            compare(conf(kUiOpenApp), "")
            h.back(this)
            compare(h.current().objectName, "appInfoPage")
            h.back(this)
            // a trailing ".desktop" is tolerated
            Backend.confSet(kUiOpenApp, "asteroid-alarmclock.desktop")
            request("app_info")
            compare(h.current().objectName, "appDetailPage")
            compare(title(), "Alarm clock")
            compare(conf(kUiOpenApp), "")
            // a service of the image is found in the other list
            h.back(this)
            h.back(this)
            Backend.confSet(kUiOpenApp, "asteroid-btsyncd")
            request("app_info")
            compare(h.current().objectName, "appDetailPage")
            compare(title(), "Phone sync")
            h.back(this)
            compare(h.current().objectName, "appInfoPage")
            compare(chip("showAppsItem").summary, "System apps")
        }

        function test_35_app_info_without_app() {
            // no app named, or one that is not on the watch: the list
            request("app_info")
            compare(h.current().objectName, "appInfoPage")
            h.back(this)
            h.back(this)
            Backend.confSet(kUiOpenApp, "no-such-app")
            request("app_info")
            compare(h.current().objectName, "appInfoPage")
            compare(conf(kUiOpenApp), "")
            h.back(this)
            h.back(this)
            // a request older than a minute does nothing, and clears the app too
            Backend.confSet(kUiOpenApp, "asteroid-weather")
            request("app_info", 70000)
            compare(h.stack.layers.length, 0)
            compare(conf(kUiOpenApp), "")
            // the app of an earlier request does not leak into another route
            Backend.confSet(kUiOpenApp, "asteroid-weather")
            request("apps")
            compare(h.current().objectName, "appsPage")
            compare(conf(kUiOpenApp), "")
        }
    }
}
