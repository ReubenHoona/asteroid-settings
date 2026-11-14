/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * A screenshot of every page of Settings at 384x384 inside the round mask
 * of the display (with a second one at the end of the long lists), and of
 * the dialogs and a choice list, on the mocks of tests/mocks. The runner
 * (settings-stock/run-tests.sh) moves them to settings-stock/shots/.
 */

import QtQuick
import QtTest
import SettingsTest
import Connman

SettingsHarness {
    id: h

    Component { id: netComponent; NetworkService { } }

    TestCase {
        name: "Screens"
        when: windowShown

        property int n: 0
        function snap(name) {
            n++
            h.shot(this, (n < 10 ? "0" : "") + n + "-" + name)
        }
        // the page at the top and, when it is longer, at its end
        function page(name) {
            snap(name)
            if (h.scrollToEnd(this))
                snap(name + "-end")
        }
        function go(names) {
            for (var i = 0; i < names.length; i++) {
                h.tapName(this, names[i])
                h.settle(this)
            }
        }

        function test_screens() {
            h.start(this)
            Backend.wifiServices = [netComponent.createObject(h, { name: "Home", connected: true, favorite: true }),
                                    netComponent.createObject(h, { name: "Office", favorite: true }),
                                    netComponent.createObject(h, { name: "Cafe", favorite: false }),
                                    netComponent.createObject(h, { name: "Library guest", favorite: false })]
            Backend.confSet("/org/asteroidos/settings/developer-options", true)
            page("settings")
            h.home(this)

            go(["connectivityItem"]); page("connectivity")
            go(["bluetoothItem"]); page("bluetooth")
            h.tapName(this, "bluetoothSwitch"); snap("bluetooth-off-dialog")
            h.tap(this, h.find(h.app, "dialogNo")); h.back(this)
            go(["wifiItem"]); page("wifi")
            go(["wifiAdd"]); page("wifi-add-network"); h.back(this)
            go(["wifiSaved"]); page("wifi-saved-networks"); h.back(this)
            go(["wifiCurrent"]); page("wifi-network"); h.back(this)
            h.tapName(this, "wifiAbout"); snap("wifi-about-dialog")
            h.tap(this, h.find(h.app, "dialogYes"))
            h.home(this)

            go(["displayItem"]); page("display")
            go(["brightnessItem"]); page("display-brightness"); h.back(this)
            go(["timeoutItem"]); page("display-screen-timeout")
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 2)); snap("display-screen-timeout-dialog")
            h.tap(this, h.find(h.app, "dialogNo")); h.back(this)
            Backend.confSet("/org/asteroidos/settings/always-on-display", false)
            h.tapName(this, "aodSwitch"); snap("display-aod-dialog")
            h.tap(this, h.find(h.app, "dialogYes"))
            go(["goToFaceItem"]); page("display-go-to-watch-face"); h.back(this)
            go(["displaySizeItem"]); page("display-size-and-text"); h.back(this)
            go(["wristOrientationItem"]); page("display-wrist-orientation"); h.back(this)
            go(["touchLockItem"]); page("display-touch-lock"); h.back(this)
            // no Display rows for Nightstand and Extra dim (Q34, Q53): by their deep links
            h.home(this)
            Backend.confSet("/org/asteroidos/settings/ui/open", "nightstand@" + Date.now())
            wait(200)
            page("display-nightstand")
            go(["nightstandDelay"]); page("display-nightstand-delay"); h.back(this)
            h.home(this)

            go(["buttonsItem"]); page("buttons")
            h.home(this)
            go(["modesItem"]); page("modes")
            go(["modesDndItem"]); page("modes-dnd")
            go(["dndCustomize"]); page("modes-dnd-customize"); h.back(this); h.back(this)
            go(["modesBedtimeItem"]); page("modes-bedtime")
            go(["bedtimeCustomize"]); page("modes-bedtime-customize"); h.back(this); h.back(this)
            go(["modesTheaterItem"]); page("modes-theater")
            go(["theaterCustomize"]); page("modes-theater-customize"); h.back(this); h.back(this)
            h.home(this)

            go(["gesturesItem"]); page("gestures")
            h.home(this)

            go(["appsItem"]); page("apps")
            Backend.confSet("/org/asteroidos/voice/recognition", "auto")
            go(["assistantItem"]); page("apps-assistant")
            go(["recognitionItem"]); page("apps-assistant-voice-recognition")
            h.home(this)

            go(["soundItem"]); page("sound")
            h.home(this)
            go(["vibrationItem"]); page("vibration")
            h.home(this)
            Backend.batteryState = 1
            Backend.chargerType = 1
            go(["batteryItem"]); page("battery")
            h.home(this)

            go(["generalItem"]); page("general")
            go(["appViewItem"]); page("general-app-view"); h.back(this)
            go(["quickPanelItem"]); page("general-quick-settings"); h.back(this)
            go(["temperatureItem"]); page("general-temperature"); h.back(this)
            h.home(this)

            go(["systemItem"]); page("system")
            go(["updatesItem"]); page("system-updates"); h.back(this)
            h.tapName(this, "powerOffItem"); snap("system-power-off-dialog")
            h.tap(this, h.find(h.app, "dialogNo"))
            go(["dateTimeItem"]); page("system-date-time")
            go(["setDateItem"]); page("system-set-date"); h.back(this)
            go(["setTimeItem"]); page("system-set-time"); h.back(this)
            go(["setZoneItem"]); wait(200); page("system-time-zone")
            h.tap(this, h.listItem(this, h.find(h.current(), "choiceList"), 7)); h.settle(this)
            page("system-time-zone-europe")
            h.back(this); h.back(this); h.back(this)
            go(["languageItem"]); page("system-language"); h.back(this)
            go(["aboutItem"]); page("system-about")
            go(["versionsItem"]); page("system-about-versions")
            h.home(this)

            go(["developerItem"]); page("developer")
            h.home(this)
            verify(n > 40)
        }
    }
}
