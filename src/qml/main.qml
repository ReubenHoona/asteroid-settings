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
    // the clock at the top, except over the screen lock flow (stock draws its pad full screen)
    showTime: !(layerStack.layers.length > 0 && layerStack.currentLayer && layerStack.currentLayer.hideTime === true)

    // the list icons drawn for Settings (src/icons, installed in
    // /usr/share/asteroid-settings/icons), named for Icon, which looks in
    // /usr/share/icons/asteroid
    readonly property string iconDir: "../../asteroid-settings/icons/"
    // Display, Sound, Vibration and System take the Wear OS 6 emulator's
    // glyphs (S16, S17, S17-b; NEWLOOK-61 N61-45), Material Symbols of the
    // icon set: the half-filled brightness star, the speaker with two
    // arcs, the round watch with solid bands and an arc at each side (the
    // emulator's has two), the 'i' in a ring (CP3A: a sun, a bell, an
    // upright watch, a gear)
    // no swipe hints at the edges: Wear OS has none
    rightIndicVisible: false
    leftIndicVisible: false
    topIndicVisible: false
    bottomIndicVisible: false

    /*
     * The pages, each made from its file at its first push (D60-46). An
     * inline Component { XxxPage { } } for every page here made Qt load all
     * the page types, their imports and plugins before the first frame;
     * stock composes a route only when it is navigated to (CP3A Compose
     * NavHost, ComposeRouteNavHostKt). A PageType is what LayerStack.push()
     * takes as the page's Component (status, createObject), under the same
     * ids, so the pages and the deep links push them as before.
     */
    component PageType: QtObject {
        // the page's file, without ".qml"
        required property string page
        // set on the page as it is made, unless push() sets them
        property var initial: ({})
        // the page's type once loaded: null before the first push
        property Component loaded: null
        // push() takes a ready Component: the type loads in createObject()
        readonly property int status: Component.Ready
        function createObject(into, params) {
            if (!loaded)
                loaded = app.pageType(page)
            var p = params || {}
            for (var k in initial) {
                if (!p.hasOwnProperty(k))
                    p[k] = initial[k]
            }
            return loaded.createObject(into, p)
        }
    }
    // the type of <page>.qml, made in this file's context as the inline
    // Components were: the pages see its ids (layerStack, confirm, app ...)
    function pageType(page) {
        var c = Qt.createComponent(page + ".qml")
        if (c.status !== Component.Ready)
            console.warn("Settings: " + page + ": " + c.errorString())
        return c
    }

    PageType { id: connectivityLayer;          page: "ConnectivityPage" }
    PageType { id: bluetoothLayer;             page: "BluetoothPage" }
    PageType { id: wifiLayer;                  page: "WiFiPage" }
    PageType { id: displayLayer;               page: "DisplayPage" }
    PageType { id: brightnessLayer;            page: "BrightnessPage" }
    PageType { id: colorThemeLayer;            page: "ColorThemePage" }
    PageType { id: extraDimLayer;              page: "ExtraDimPage" }
    PageType { id: watchfaceLayer;             page: "WatchfacePage" }
    PageType { id: gesturesLayer;              page: "GesturesPage" }
    PageType { id: appsLayer;                  page: "AppsPage" }
    PageType { id: dndLayer;                   page: "DndPage" }
    PageType { id: bedtimeLayer;               page: "BedtimePage" }
    PageType { id: theaterLayer;               page: "TheaterPage" }
    PageType { id: dndCustomizeLayer;          page: "ModeCustomizePage"; initial: ({ "mode": "do-not-disturb" }) }
    PageType { id: bedtimeCustomizeLayer;      page: "ModeCustomizePage"; initial: ({ "mode": "bedtime" }) }
    PageType { id: theaterCustomizeLayer;      page: "ModeCustomizePage"; initial: ({ "mode": "theater" }) }
    PageType { id: assistantLayer;             page: "AssistantPage" }
    PageType { id: tileActionsLayer;           page: "TileActionsPage" }
    PageType { id: soundLayer;                 page: "SoundPage" }
    PageType { id: vibrationLayer;             page: "VibrationPage" }
    PageType { id: batteryLayer;               page: "BatteryPage" }
    PageType { id: batterySaverLayer;          page: "BatterySaverPage" }
    PageType { id: chargingLayer;              page: "ChargingPage" }
    PageType { id: generalLayer;               page: "GeneralPage" }
    PageType { id: whatsNewLayer;              page: "WhatsNewPage" }
    PageType { id: systemLayer;                page: "SystemPage" }
    PageType { id: dateTimeLayer;              page: "DateTimePage" }
    PageType { id: timeLayer;                  page: "TimePage" }
    PageType { id: dateLayer;                  page: "DatePage" }
    PageType { id: languageLayer;              page: "LanguagePage" }
    PageType { id: updatesLayer;               page: "UpdatesPage" }
    PageType { id: aboutLayer;                 page: "AboutPage" }
    PageType { id: licensesLayer;              page: "LicensesPage" }
    PageType { id: inputMethodsLayer;          page: "InputMethodsPage" }
    PageType { id: manageKeyboardsLayer;       page: "ManageKeyboardsPage" }
    PageType { id: versionsLayer;              page: "VersionsPage" }
    PageType { id: developerLayer;             page: "DeveloperPage" }
    PageType { id: buttonsLayer;               page: "ButtonsPage" }
    PageType { id: modesLayer;                 page: "ModesPage" }
    PageType { id: locationLayer;              page: "LocationPage" }
    PageType { id: accessibilityLayer;         page: "AccessibilityPage" }
    PageType { id: securityLayer;              page: "SecurityPage" }
    PageType { id: lockFlowLayer;              page: "LockFlowPage" }
    PageType { id: displaySizeLayer;           page: "DisplaySizePage" }
    PageType { id: wristOrientationLayer;      page: "WristOrientationPage" }
    PageType { id: touchLockLayer;             page: "TouchLockPage" }
    PageType { id: healthProfileLayer;         page: "HealthProfilePage" }
    PageType { id: safetyLayer;                page: "SafetyPage" }
    PageType { id: notificationsLayer;         page: "NotificationsPage" }
    PageType { id: appNotificationsLayer;      page: "AppNotificationsPage" }
    PageType { id: appInfoLayer;               page: "AppInfoPage" }
    PageType { id: appStorageLayer;            page: "AppStoragePage" }
    PageType { id: audioAdjustLayer;           page: "AudioAdjustPage" }
    PageType { id: magnificationLayer;         page: "MagnificationPage" }
    PageType { id: colorCorrectionLayer;       page: "ColorCorrectionPage" }
    PageType { id: vibrationWatchLayer;        page: "VibrationWatchPage" }

    // Developer options appear at the end of the list once Build number
    // (About > Versions) was tapped seven times, as on Wear OS
    ConfigurationValue {
        id: developerOptions
        key: "/org/asteroidos/settings/developer-options"
        defaultValue: false
    }

    // the languages (LanguageModel reads a file for each): made when a page
    // first asks for them (System's Language row, the Language list), then
    // shared, so the row follows a language chosen on the list. Kept in a
    // plain object, so that asking from a binding makes no dependency.
    Component { id: languagesComponent; LanguageModel { } }
    readonly property var _languages: ({ model: null })
    function languageModel() {
        if (!_languages.model)
            _languages.model = languagesComponent.createObject(app)
        return _languages.model
    }

    // the modes (Bedtime, Theater, Battery saver, Extra dim, Do Not
    // Disturb): which setting a mode holds, and its summary
    ModeState { id: modeState }

    // when System updates last started a check (a page opened within the
    // minute does not start another), ms since 1970
    property double updateCheckedAt: 0

    LayerStack {
        id: layerStack
        firstPage: firstPageComponent
    }

    // Settings ends, back to what is under it (the face): after Change watch
    // face and Touch lock, which the launcher carries on. A property so that
    // the tests can swap it.
    property var closeApp: function () { Qt.quit() }
    // the wall clock (ms) Set date and Set time start from and keep the time
    // of day of (the tests set the mocks' time)
    property var clock: function () { return Date.now() }

    /*
     * The selection dialog, the confirmation, the toast and the reset screen
     * are made after the first frame (D60-46), at once if one is wanted
     * sooner: made with the app, they and their types held up the first
     * frame. main.cpp sets firstFrameDrawn once the first frame is on
     * screen. They wait for the main list's rows below its first screen
     * (mainListMade; Settings start): the list is what is on screen, and it
     * gets them about a third sooner. A Later fills the app at the z its
     * item had; now() gives the item, finishing a creation under way (a
     * Loader set to synchronous completes it) or making it there and then.
     */
    property bool firstFrameDrawn: false
    component Later: Loader {
        anchors.fill: parent
        asynchronous: true
        active: app.firstFrameDrawn && app.mainListMade
        // the item once made (untyped: its type loads with it)
        readonly property var made: item
        function now() {
            asynchronous = false
            active = true
            return item
        }
    }

    // the stock selection dialog of the list settings (SelectionDialogKt):
    // options are the labels, apply(index) applies one; it returns false
    // to keep the dialog open (the caller then calls pop() on what choose()
    // returned, e.g. after a confirmation); message is stock's optional line
    // under the title ("When display will turn off after inactivity")
    Later {
        id: chooser
        z: 1000
        source: "ChoicePage.qml"
        onLoaded: item.behind = layerStack
        readonly property bool shown: made !== null && made.shown
        function show(title, options, current, apply, summaries, message) {
            return now().show(title, options, current, apply, summaries, message)
        }
        function pop() {
            if (made)
                made.pop()
        }
    }
    function choose(title, options, current, apply, summaries, message) {
        return chooser.show(title, options, current, apply, summaries || [], message || "")
    }

    // the stock settings confirmation (X / check), over every page and the
    // selection dialog
    Later {
        id: confirm
        z: 1100
        source: "ConfirmDialog.qml"
        onLoaded: {
            item.objectName = "confirmDialog"
            // the screen under it: the selection dialog when it asks for one
            item.behind = Qt.binding(function () { return chooser.shown ? chooser.made : layerStack })
        }
        function ask(title, message, onAccept, onReject) {
            now().ask(title, message, onAccept, onReject)
        }
        function tell(title, message, onAccept) {
            now().tell(title, message, onAccept)
        }
        function close() {
            if (made)
                made.close()
        }
    }

    // the screen of Disconnect & reset: over everything, no way back
    Later {
        id: resetScreen
        z: 1500
        source: "FactoryResetScreen.qml"
        function start() {
            now().start()
        }
    }

    // the Android toast (org.asteroid.controls Toast: centred, 2 s)
    Later {
        id: toast
        z: 1200
        sourceComponent: Component {
            Toast {
                objectName: "toast"
                Component.onCompleted: label.objectName = "toastText"
            }
        }
        function show(message, isLong, icon) {
            now().show(message, isLong, icon)
        }
    }

    /*
     * The main list (Settings start). Made with the app, it gets the rows of
     * its first screen before the first frame (makeFirstScreen: firstRows,
     * Connectivity, Display, Gestures; a row is at least 104 px, so the
     * fourth starts below the 384 px screen even before the edge effect
     * shrinks the third) and the others in the background once the first
     * frame is on screen (MainListRows.qml). Each
     * holder's rows are moved into the list's column in their order, so the
     * list is the same as before once they are in. Made with the list, the
     * 17 rows (a Button with two labels, a switch and an edge effect each)
     * were most of what Settings did before its first frame, and the Battery
     * row's level loaded Nemo.Mce and connected to the system bus. When a
     * request opens a page at start (openRequested), that page is the first
     * screen and the list under it gets all its rows after the first frame.
     */
    component Rows: QtObject {
        default property list<Item> rows
    }
    Component {
        id: firstRows

        Rows {
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
                iconName: "ms-brightness_medium"
                onClicked: layerStack.push(displayLayer)
            }
            SettingsChip {
                objectName: "gesturesItem"
                //% "Gestures"
                title: qsTrId("id-gestures-page")
                iconName: app.iconDir + "eos-settings-gestures"
                onClicked: layerStack.push(gesturesLayer)
            }
        }
    }

    Component {
        id: firstPageComponent

        SettingsPage {
            id: mainPage
            objectName: "mainPage"
            //% "Settings"
            title: qsTrId("id-settings-title")

            // every row is in the list
            readonly property bool rowsMade: _more !== null
            // the holders, once made (they own their rows)
            property QtObject _first: null
            property QtObject _more: null
            // MainListRows.qml while it loads, and the creation under way
            property Component _moreType: null
            property var _incubator: null

            // a holder's rows into the list, after the ones there
            function _place(holder) {
                var rows = holder.rows
                for (var i = 0; i < rows.length; i++)
                    rows[i].parent = mainPage.column
                return holder
            }
            function _incubate(type, done) {
                var incubator = type.incubateObject(mainPage, {}, Qt.Asynchronous)
                var finished = function () {
                    if (incubator.status === Component.Loading)
                        return
                    _incubator = null
                    if (incubator.status === Component.Ready) {
                        done(incubator.object)
                        makeRowsLater()
                    } else {
                        console.warn("Settings: the main list's rows were not made")
                    }
                }
                _incubator = incubator
                if (incubator.status === Component.Loading)
                    incubator.onStatusChanged = finished
                else
                    finished()
            }
            // the first screen's rows, now (a creation under way is finished)
            function makeFirstRows() {
                if (_first !== null)
                    return
                if (_incubator !== null)
                    _incubator.forceCompletion()
                else
                    _first = _place(firstRows.createObject(mainPage))
            }
            // after the first frame, in the background: the first screen's
            // rows if a request at start left them out, then the others
            function makeRowsLater() {
                if (_incubator !== null || _more !== null)
                    return
                if (_first === null) {
                    _incubate(firstRows, function (holder) { _first = _place(holder) })
                    return
                }
                if (_moreType === null) {
                    _moreType = Qt.createComponent("MainListRows.qml", Component.Asynchronous)
                    if (_moreType.status === Component.Loading) {
                        _moreType.statusChanged.connect(makeRowsLater)
                        return
                    }
                }
                if (_moreType.status === Component.Loading)
                    return
                if (_moreType.status !== Component.Ready) {
                    console.warn("Settings: MainListRows.qml: " + _moreType.errorString())
                    return
                }
                _incubate(_moreType, function (holder) { _more = _place(holder) })
            }
            // the list uncovered before its first rows were made (Back from
            // a page opened at start, at once): they are made there and then
            Connections {
                target: layerStack
                enabled: mainPage._first === null && app._started
                function onLayersChanged() {
                    if (layerStack.layers.length === 0)
                        mainPage.makeFirstRows()
                }
                function onBackProgressChanged() {
                    if (layerStack.layers.length === 1 && layerStack.backProgress > 0)
                        mainPage.makeFirstRows()
                }
            }
        }
    }
    // every row of the main list is made (main.cpp logs when)
    readonly property bool mainListMade: layerStack.firstPageItem ? layerStack.firstPageItem.rowsMade === true : false
    onFirstFrameDrawnChanged: {
        if (!firstFrameDrawn)
            return
        makeFirstScreen()
        if (layerStack.firstPageItem)
            layerStack.firstPageItem.makeRowsLater()
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
    // the app the route app_info shows (CR-17): its desktop id without
    // ".desktop" (a trailing ".desktop" is tolerated), written by the launcher
    // before the request, cleared with it
    ConfigurationValue {
        id: openApp
        key: "/org/asteroidos/settings/ui/open-app"
        defaultValue: ""
    }
    // route -> the pages pushed from the main list, in order
    readonly property var deepLinks: ({
        "main": [],
        "connectivity": [connectivityLayer],
        "wifi": [connectivityLayer, wifiLayer],
        "bluetooth": [connectivityLayer, bluetoothLayer],
        "display": [displayLayer],
        "color_theme": [displayLayer, colorThemeLayer],
        "brightness": [displayLayer, brightnessLayer],
        "display_size": [displayLayer, displaySizeLayer],
        "wrist_orientation": [displayLayer, wristOrientationLayer],
        "touch_lock": [displayLayer, touchLockLayer],
        // no Display row since DECISIONS Q53: the Extra dim quick tile's page
        "extra_dim": [extraDimLayer],
        "gestures": [gesturesLayer],
        "buttons": [buttonsLayer],
        "apps": [appsLayer],
        "notifications": [appsLayer, notificationsLayer],
        "app_notifications": [appsLayer, notificationsLayer, appNotificationsLayer],
        "app_info": [appsLayer, appInfoLayer],
        "app_storage": [appsLayer, appStorageLayer],
        "assistant": [appsLayer, assistantLayer],
        "tile_actions": [appsLayer, assistantLayer, tileActionsLayer],
        "health_profile": [healthProfileLayer],
        "location": [locationLayer],
        "safety": [safetyLayer],
        "accessibility": [accessibilityLayer],
        "audio_adjustment": [accessibilityLayer, audioAdjustLayer],
        "magnification": [accessibilityLayer, magnificationLayer],
        "color_correction": [accessibilityLayer, colorCorrectionLayer],
        "vibration_watch": [accessibilityLayer, vibrationWatchLayer],
        "security": [securityLayer],
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
        "battery_saver": [batteryLayer, batterySaverLayer],
        "general": [generalLayer],
        "whats_new": [generalLayer, whatsNewLayer],
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
    // appId: for app_info, the app whose page opens over the list. The
    // pages are there at once, at rest: a request is not a navigation, its
    // page is the screen (stock's start destination), so the push motion
    // over the list is skipped. true: a page was opened.
    function openPage(page, appId) {
        chooser.pop()
        confirm.close()
        backToMainMenu()
        var route = routeOf(page)
        for (var i = 0; i < route.length; i++) {
            if (page === "app_info" && appId && i === route.length - 1)
                layerStack.push(route[i], { "appId": String(appId) })
            else
                layerStack.push(route[i])
        }
        if (route.length > 0 && typeof layerStack._finishPush === "function")
            layerStack._finishPush()
        return route.length > 0
    }
    // true: a page was opened. Not before makeFirstScreen(): a request waiting
    // at start is opened there.
    function openRequested() {
        if (!_started)
            return false
        var request = String(openRequest.value || "")
        if (request === "")
            return false
        var appId = String(openApp.value || "").replace(/\.desktop$/, "")
        openRequest.value = ""
        if (String(openApp.value || "") !== "")
            openApp.value = ""
        var at = request.lastIndexOf("@")
        var age = Date.now() - Number(request.substring(at + 1))
        if (at < 0 || !(age > -5000 && age < 60000))
            return false
        return app.openPage(request.substring(0, at), appId)
    }
    // The first screen, made once the app has its size and before the first
    // frame: the page of a request waiting at start, with the app (stock's
    // start destination; the list gets its rows after the first frame), or
    // else the main list's first rows. The size: main.cpp's view gives it
    // when the window is shown, the tests' Loader as it makes the app; made
    // at 0 x 0, every item of the screen would be laid out twice. Not before
    // the app is complete (a size given while it is being made comes before
    // the stack has its list).
    property bool _complete: false
    property bool _started: false
    function makeFirstScreen() {
        if (_started || !_complete || width <= 0 || height <= 0)
            return
        _started = true
        if (!openRequested())
            layerStack.firstPageItem.makeFirstRows()
    }
    onWidthChanged: makeFirstScreen()
    onHeightChanged: makeFirstScreen()
    Component.onCompleted: {
        _complete = true
        makeFirstScreen()
    }
}
