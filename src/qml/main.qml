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
import "PageReady.js" as PageReady

/*
 * Settings as the stock CP3A Settings app of the Pixel Watch 2: the paired
 * main list in stock order (PixelWatchMainViewModel.getPreferenceFactories):
 * Connectivity, Display, Gestures, Buttons, Apps & notifications, Modes,
 * (Google), Sound, Vibration, Battery, General, (Health profile), Location,
 * (Safety & Emergency), Accessibility, Security, (Passwords), System,
 * Developer options once Build number was tapped seven times. Google and
 * Passwords are out of reach and left out (DECISIONS Q62); Health profile,
 * Location, Safety & Emergency, Accessibility and Security keep their stock
 * places and show once their pages have rows (PageReady.js). No "Watch face & style": CP3A has none in the paired list
 * (MainViewModel.standardPreferences; DECISIONS Q26 drops the Wallpaper page).
 * Black, as the stock app, with the TimeText at the top of every screen
 * (AppScaffold timeText); the rows are the M3 Settings rows (SettingsPage,
 * SettingsChip), the lists open as selection dialogs (ChoicePage) and the
 * questions as alert dialogs (ConfirmDialog).
 */
Application {
    id: app

    centerColor: "#000000"
    outerColor: "#000000"
    // stock AppScaffold: TimeText on every Settings screen (settings-a-06)
    showTime: true

    // the list icons drawn for Settings (src/icons, installed in
    // /usr/share/asteroid-settings/icons), named for Icon, which looks in
    // /usr/share/icons/asteroid
    readonly property string iconDir: "../../asteroid-settings/icons/"
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
    Component { id: extraDimLayer;              ExtraDimPage   { } }
    Component { id: nightstandLayer;            NightstandPage { } }
    Component { id: nightstandWatchfaceLayer;   NightstandWatchfacePage { } }
    Component { id: watchfaceLayer;             WatchfacePage  { } }
    Component { id: gesturesLayer;              GesturesPage   { } }
    Component { id: appsLayer;                  AppsPage       { } }
    Component { id: dndLayer;                   DndPage        { } }
    Component { id: bedtimeLayer;               BedtimePage    { } }
    Component { id: theaterLayer;               TheaterPage    { } }
    Component { id: dndCustomizeLayer;          ModeCustomizePage { mode: "do-not-disturb" } }
    Component { id: bedtimeCustomizeLayer;      ModeCustomizePage { mode: "bedtime" } }
    Component { id: theaterCustomizeLayer;      ModeCustomizePage { mode: "theater" } }
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
    Component { id: buttonsLayer;               ButtonsPage    { } }
    Component { id: modesLayer;                 ModesPage      { } }
    Component { id: locationLayer;              LocationPage   { } }
    Component { id: accessibilityLayer;         AccessibilityPage { } }
    Component { id: securityLayer;              SecurityPage   { } }
    Component { id: displaySizeLayer;           DisplaySizePage { } }

    // Developer options appear at the end of the list once Build number
    // (About > Versions) was tapped seven times, as on Wear OS
    ConfigurationValue {
        id: developerOptions
        key: "/org/asteroidos/settings/developer-options"
        defaultValue: false
    }

    MceBatteryLevel { id: batteryLevel }
    MceChargerType { id: chargerType }

    // the modes (Bedtime, Theater, Battery saver, Extra dim, Do Not
    // Disturb): which setting a mode holds, and its summary
    ModeState { id: modeState }

    // Battery saver on, asking first as stock (the Battery page and the
    // suggestion at low battery)
    function turnOnBatterySaver() {
        //% "Turn on Battery Saver?"
        confirm.ask(qsTrId("id-saver-confirm-title"),
                    //% "Turns off Always-on screen and Tilt-to-wake to extend battery life"
                    qsTrId("id-saver-explain"),
                    function () { modeState.batterySaver = true })
    }

    LayerStack {
        id: layerStack
        firstPage: firstPageComponent
    }

    // the stock selection dialog of the list settings (SelectionDialogKt):
    // options are the labels, apply(index) applies one; it returns false
    // to keep the dialog open (the caller then calls pop() on what choose()
    // returned, e.g. after a confirmation); message is stock's optional line
    // under the title ("When display will turn off after inactivity")
    ChoicePage { id: chooser; behind: layerStack }
    function choose(title, options, current, apply, summaries, message) {
        return chooser.show(title, options, current, apply, summaries || [], message || "")
    }

    // the stock settings confirmation (X / check), over every page and the
    // selection dialog
    ConfirmDialog {
        id: confirm
        objectName: "confirmDialog"
        // the screen under it: the selection dialog when it asks for one
        behind: chooser.shown ? chooser : layerStack
    }

    // the Android toast (org.asteroid.controls Toast: centred, 2 s)
    Toast {
        id: toast
        objectName: "toast"
        z: 1200
        Component.onCompleted: toast.label.objectName = "toastText"
    }

    Component {
        id: firstPageComponent

        SettingsPage {
            objectName: "mainPage"
            //% "Settings"
            title: qsTrId("id-settings-title")

            // stock: at the top when the battery is low (at most
            // low_power_trigger_level, 15 %), off the charger
            SettingsChip {
                objectName: "batterySaverSuggestion"
                visible: batteryLevel.valid && batteryLevel.percent <= 15 && chargerType.type == MceChargerType.None
                         && !modeState.batterySaver
                //% "Battery saver"
                title: qsTrId("id-battery-saver")
                //% "Suggested"
                summary: qsTrId("id-suggested")
                control: "toggle"
                checked: false
                onClicked: app.turnOnBatterySaver()
            }
            SettingsChip {
                objectName: "connectivityItem"
                //% "Connectivity"
                title: qsTrId("id-connectivity-page")
                iconName: app.iconDir + "eos-settings-connectivity"
                onClicked: layerStack.push(connectivityLayer)
            }
            SettingsChip {
                objectName: "displayItem"
                title: qsTrId("id-display-page")
                iconName: "ios-sunny-outline"
                onClicked: layerStack.push(displayLayer)
            }
            SettingsChip {
                objectName: "gesturesItem"
                //% "Gestures"
                title: qsTrId("id-gestures-page")
                iconName: app.iconDir + "eos-settings-gestures"
                onClicked: layerStack.push(gesturesLayer)
            }
            SettingsChip {
                objectName: "buttonsItem"
                //% "Buttons"
                title: qsTrId("id-buttons-page")
                iconName: app.iconDir + "eos-settings-buttons"
                onClicked: layerStack.push(buttonsLayer)
            }
            SettingsChip {
                objectName: "appsItem"
                //% "Apps & notifications"
                title: qsTrId("id-apps-page")
                iconName: "ios-apps-outline"
                onClicked: layerStack.push(appsLayer)
            }
            SettingsChip {
                objectName: "modesItem"
                //% "Modes"
                title: qsTrId("id-modes-page")
                iconName: app.iconDir + "eos-settings-modes"
                onClicked: layerStack.push(modesLayer)
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
                iconName: app.iconDir + "eos-settings-battery"
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
                objectName: "healthProfileItem"
                visible: PageReady.healthProfile
                //% "Health profile"
                title: qsTrId("id-health-profile-page")
                iconName: "ios-heart-outline"
                // made when tapped: the page comes with its package
                onClicked: layerStack.push(Qt.createComponent("HealthProfilePage.qml"))
            }
            SettingsChip {
                objectName: "locationItem"
                visible: PageReady.location
                //% "Location"
                title: qsTrId("id-location-page")
                iconName: app.iconDir + "eos-settings-location"
                onClicked: layerStack.push(locationLayer)
            }
            SettingsChip {
                objectName: "safetyItem"
                visible: PageReady.safety
                //% "Safety & Emergency"
                title: qsTrId("id-safety-page")
                iconName: "ios-medkit-outline"
                // made when tapped: the page comes with its package
                onClicked: layerStack.push(Qt.createComponent("SafetyPage.qml"))
            }
            SettingsChip {
                objectName: "accessibilityItem"
                visible: PageReady.accessibility
                //% "Accessibility"
                title: qsTrId("id-accessibility-page")
                iconName: app.iconDir + "eos-settings-accessibility"
                onClicked: layerStack.push(accessibilityLayer)
            }
            SettingsChip {
                objectName: "securityItem"
                visible: PageReady.security
                //% "Security"
                title: qsTrId("id-security-page")
                iconName: app.iconDir + "eos-settings-security"
                onClicked: layerStack.push(securityLayer)
            }
            SettingsChip {
                objectName: "systemItem"
                //% "System"
                title: qsTrId("id-system-page")
                iconName: app.iconDir + "eos-settings-system"
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

    // A page on request, "<page>@<time in ms>" in this dconf key, as the
    // stock deep links (ClockworkDeepLinkRouteStore: an intent action to a
    // route; one with no route opens the main list, NoMatch -> MAIN). Quick
    // settings long press, the status tray, complications, notifications and
    // dialogs ask for a page by its stock route name in lower case; the
    // launcher writes the key with Date.now() and starts or raises this app
    // without arguments, so the request is read at start and whenever it
    // changes. A request older than a minute (the app started later some
    // other way) is ignored, as the Health app's tile request. eos-update's
    // open-settings asks for "updates".
    ConfigurationValue {
        id: openRequest
        key: "/org/asteroidos/settings/ui/open"
        defaultValue: ""
        onValueChanged: Qt.callLater(app.openRequested)
    }
    // route -> the pages pushed from the main list, in order
    readonly property var deepLinks: ({
        "main": [],
        "connectivity": [connectivityLayer],
        "wifi": [connectivityLayer, wifiLayer],
        "bluetooth": [connectivityLayer, bluetoothLayer],
        "display": [displayLayer],
        "brightness": [displayLayer, brightnessLayer],
        "gestures": [gesturesLayer],
        "buttons": [buttonsLayer],
        "apps": [appsLayer],
        "modes": [modesLayer],
        "mode_do_not_disturb": [modesLayer, dndLayer],
        "mode_do_not_disturb_customize": [modesLayer, dndLayer, dndCustomizeLayer],
        "mode_bedtime": [modesLayer, bedtimeLayer],
        "mode_bedtime_customize": [modesLayer, bedtimeLayer, bedtimeCustomizeLayer],
        "mode_theater": [modesLayer, theaterLayer],
        "mode_theater_customize": [modesLayer, theaterLayer, theaterCustomizeLayer],
        // short names (modes-dnd-02)
        "dnd": [modesLayer, dndLayer],
        "bedtime": [modesLayer, bedtimeLayer],
        "theater": [modesLayer, theaterLayer],
        "sound": [soundLayer],
        "vibration": [vibrationLayer],
        "battery": [batteryLayer],
        // Battery saver is on the Battery page until it has its own
        "battery_saver": [batteryLayer],
        "general": [generalLayer],
        "system": [systemLayer],
        "date_time": [systemLayer, dateTimeLayer],
        "language": [systemLayer, languageLayer],
        "device_info": [systemLayer, aboutLayer],
        "updates": [systemLayer, updatesLayer],
        "developer_options": [developerLayer]
    })
    // the pages a route opens: none (the main list) for an unknown route,
    // Sound without a speaker, or Developer options while they are off
    function routeOf(page) {
        if (!deepLinks.hasOwnProperty(page))
            return []
        if (page === "sound" && !DeviceSpecs.hasSpeaker)
            return []
        if (page === "developer_options" && !developerOptions.value)
            return []
        return deepLinks[page]
    }
    function openPage(page) {
        chooser.pop()
        confirm.close()
        backToMainMenu()
        var route = routeOf(page)
        for (var i = 0; i < route.length; i++)
            layerStack.push(route[i])
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
        app.openPage(request.substring(0, at))
    }
    Component.onCompleted: Qt.callLater(openRequested)
}
