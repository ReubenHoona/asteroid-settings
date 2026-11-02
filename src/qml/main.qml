/*
 * Copyright (C) 2023 - Timo Könnecke <github.com/eLtMosen>
 * Copyright (C) 2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 * Copyright (C) 2015 - Florent Revest <revestflo@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import org.asteroid.settings
import Nemo.Configuration
import Nemo.Mce

/*
 * Settings as the stock Wear OS Settings app of the Pixel Watch 2
 * (ClockworkSettings, prefs_main.xml): the same top level list in the same
 * order, without what this watch cannot do (Google, Health Profile,
 * Location, Safety & Emergency, Accessibility, Security); Developer options
 * at the end once Build number was tapped seven times. Black, as the stock
 * app; the lists are Wear OS chips (SettingsPage, SettingsChip).
 */
Application {
    id: app

    centerColor: "#000000"
    outerColor: "#000000"
    // no swipe hints at the edges: Wear OS has none
    rightIndicVisible: false
    leftIndicVisible: false
    topIndicVisible: false
    bottomIndicVisible: false

    Component { id: connectivityLayer;          ConnectivityPage { } }
    Component { id: bluetoothLayer;             BluetoothPage  { } }
    Component { id: wifiLayer;                  WiFiPage       { } }
    Component { id: displayLayer;               DisplayPage    { } }
    Component { id: brightnessLayer;            BrightnessPage { } }
    Component { id: nightstandLayer;            NightstandPage { } }
    Component { id: nightstandWatchfaceLayer;   NightstandWatchfacePage { } }
    Component { id: styleLayer;                 StylePage      { } }
    Component { id: wallpaperLayer;             WallpaperPage  { } }
    Component { id: watchfaceLayer;             WatchfacePage  { } }
    Component { id: gesturesLayer;              GesturesPage   { } }
    Component { id: appsLayer;                  AppsPage       { } }
    Component { id: dndLayer;                   DndPage        { } }
    Component { id: assistantLayer;             AssistantPage  { } }
    Component { id: soundLayer;                 SoundPage      { } }
    Component { id: vibrationLayer;             VibrationPage  { } }
    Component { id: batteryLayer;               BatteryPage    { } }
    Component { id: generalLayer;               GeneralPage    { } }
    Component { id: quickPanelLayer;            QuickPanelPage { } }
    Component { id: launcherLayer;              LauncherPage   { } }
    Component { id: systemLayer;                SystemPage     { } }
    Component { id: dateTimeLayer;              DateTimePage   { } }
    Component { id: timeLayer;                  TimePage       { } }
    Component { id: dateLayer;                  DatePage       { } }
    Component { id: timezoneLayer;              TimezonePage   { } }
    Component { id: languageLayer;              LanguagePage   { } }
    Component { id: updatesLayer;               UpdatesPage    { } }
    Component { id: aboutLayer;                 AboutPage      { } }
    Component { id: versionsLayer;              VersionsPage   { } }
    Component { id: developerLayer;             DeveloperPage  { } }
    Component { id: choiceLayer;                ChoicePage     { } }

    // Developer options appear at the end of the list once Build number
    // (About > Versions) was tapped seven times, as on Wear OS
    ConfigurationValue {
        id: developerOptions
        key: "/org/asteroidos/settings/developer-options"
        defaultValue: false
    }

    MceBatteryLevel { id: batteryLevel }

    LayerStack {
        id: layerStack
        firstPage: firstPageComponent
    }

    // the stock settings' alert dialog (✕ / ✓), over every page
    ConfirmDialog { id: confirm; objectName: "confirmDialog" }

    // a short line at the bottom, as Android's toast
    Toast { id: toast; objectName: "toast" }

    // a list of choices on a page of its own (WearListPreference): options
    // are the labels, choose(index) applies one; it returns false to keep
    // the page open (it then pops the page itself, e.g. after a dialog)
    function choose(title, options, current, apply, summaries) {
        return layerStack.push(choiceLayer, { "title": title, "options": options, "currentIndex": current,
                                              "apply": apply, "summaries": summaries || [] })
    }

    Component {
        id: firstPageComponent

        SettingsPage {
            objectName: "mainPage"
            //% "Settings"
            title: qsTrId("id-settings-title")

            SettingsChip {
                objectName: "connectivityItem"
                //% "Connectivity"
                title: qsTrId("id-connectivity-page")
                iconName: "ios-swap"
                onClicked: layerStack.push(connectivityLayer)
            }
            SettingsChip {
                objectName: "displayItem"
                title: qsTrId("id-display-page")
                iconName: "ios-sunny-outline"
                onClicked: layerStack.push(displayLayer)
            }
            SettingsChip {
                objectName: "styleItem"
                //% "Watch face & style"
                title: qsTrId("id-style-page")
                iconName: "ios-color-palette-outline"
                onClicked: layerStack.push(styleLayer)
            }
            SettingsChip {
                objectName: "gesturesItem"
                //% "Gestures"
                title: qsTrId("id-gestures-page")
                iconName: "ios-hand-outline"
                onClicked: layerStack.push(gesturesLayer)
            }
            SettingsChip {
                objectName: "appsItem"
                //% "Apps & notifications"
                title: qsTrId("id-apps-page")
                iconName: "ios-apps-outline"
                onClicked: layerStack.push(appsLayer)
            }
            SettingsChip {
                objectName: "soundItem"
                visible: DeviceSpecs.hasSpeaker
                title: qsTrId("id-sound-page")
                iconName: "ios-notifications-outline"
                onClicked: layerStack.push(soundLayer)
            }
            SettingsChip {
                objectName: "vibrationItem"
                //% "Vibration"
                title: qsTrId("id-vibration-page")
                iconName: "ios-watch-vibrating"
                onClicked: layerStack.push(vibrationLayer)
            }
            SettingsChip {
                objectName: "batteryItem"
                //% "Battery"
                title: qsTrId("id-battery-page")
                //% "%1%"
                summary: batteryLevel.valid ? qsTrId("id-battery-percent").arg(batteryLevel.percent) : ""
                iconName: "ios-battery-full"
                onClicked: layerStack.push(batteryLayer)
            }
            SettingsChip {
                objectName: "generalItem"
                //% "General"
                title: qsTrId("id-general-page")
                iconName: "ios-watch"
                onClicked: layerStack.push(generalLayer)
            }
            SettingsChip {
                objectName: "systemItem"
                //% "System"
                title: qsTrId("id-system-page")
                iconName: "ios-information-circle-outline"
                onClicked: layerStack.push(systemLayer)
            }
            SettingsChip {
                objectName: "developerItem"
                visible: developerOptions.value
                //% "Developer options"
                title: qsTrId("id-developer-page")
                iconName: "ios-code"
                onClicked: layerStack.push(developerLayer)
            }
        }
    }

    function backToMainMenu() {
        while (layerStack.layers.length > 0) {
            layerStack.pop(layerStack.currentLayer)
        }
    }

    // A page on request, "<page>@<time in ms>" in this dconf key: the Open
    // button of a system update notification (eos-update's open-settings)
    // asks for "updates" (System > System updates); "battery" opens Battery.
    // The launcher starts or raises this app without arguments, so the
    // request is read at start and whenever it changes; a request older
    // than a minute (the app started later some other way) is ignored, as
    // the Health app's tile request
    ConfigurationValue {
        id: openRequest
        key: "/org/asteroidos/settings/ui/open"
        defaultValue: ""
        onValueChanged: Qt.callLater(app.openRequested)
    }
    function openRequested() {
        var request = String(openRequest.value || "")
        if (request === "")
            return
        openRequest.value = ""
        var at = request.lastIndexOf("@")
        var age = Date.now() - Number(request.substring(at + 1))
        if (at < 0 || !(age > -5000 && age < 60000))
            return
        var page = request.substring(0, at)
        if (page === "updates") {
            backToMainMenu()
            layerStack.push(systemLayer)
            layerStack.push(updatesLayer)
        } else if (page === "battery") {
            backToMainMenu()
            layerStack.push(batteryLayer)
        }
    }
    Component.onCompleted: Qt.callLater(openRequested)
}
