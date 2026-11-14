/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

/*
 * Customize, one page for Do Not Disturb, Bedtime and Theater (stock
 * ClockworkNavRouteCollector$init$51 / $54 and BedtimeCategories.CUSTOMIZE):
 * - the category "What can notify you" (pref_priorityModeCustomizeLabel) with
 *   the switches Starred callers, Repeat callers and Media sounds;
 * - the category "Alarms and Timers" with Sound and Vibrate and the caption
 *   "Individual app settings for sound and vibration still apply" while
 *   either is on, "Alarms will activate silently" when both are off
 *   (AlarmsCategory.java:79);
 * - Bedtime only: the category "Display options" with a row that opens the
 *   selection dialog No color filter / Grayscale / Nightlight (Reduce blue
 *   light) (BedtimeCategories.DISPLAY_CONTROLS, DisplayOptions*Preference).
 * One key each, /org/asteroidos/modes/<mode>/{starred,repeat,media,
 * alarm-sound,alarm-vibrate}, mode being do-not-disturb, bedtime or theater;
 * the defaults are stock's: FocusModeConstants.createZenPolicyFor gives
 * Bedtime starred, repeat, alarm sound and vibration, no media; Theater
 * alarm vibration only (allowAlarms(false, true)); Do Not Disturb keeps all
 * five (ModeState.customizeDefaults). The launcher's quiet policy and
 * btsyncd read the keys (modes-dnd-04); nothing here does more than write.
 * Bedtime's display filter is /org/asteroidos/modes/bedtime/display-filter,
 * none | grayscale | nightlight, default nightlight (stock's
 * config_defaultEnableNightLightForBedtimeMode is true on the Pixel Watch,
 * FocusModeConstants.java:51); the compositor applies it while Bedtime is on.
 */
SettingsPage {
    id: page
    // do-not-disturb, bedtime or theater
    property string mode: "do-not-disturb"
    readonly property bool isBedtime: mode === "bedtime"
    objectName: mode === "do-not-disturb" ? "dndCustomizePage" : mode + "CustomizePage"
    title: mode === "bedtime" ? qsTrId("id-bedtime-mode")
         : mode === "theater" ? qsTrId("id-theater-mode") : qsTrId("id-dnd-page")

    function on(v) { return v === true || v === "true" }
    function keyOf(name) { return modeState.customizeKey(mode, name) }

    ConfigurationValue { id: starred; key: page.keyOf("starred"); defaultValue: modeState.customizeDefault(page.mode, "starred") }
    ConfigurationValue { id: repeat; key: page.keyOf("repeat"); defaultValue: modeState.customizeDefault(page.mode, "repeat") }
    ConfigurationValue { id: media; key: page.keyOf("media"); defaultValue: modeState.customizeDefault(page.mode, "media") }
    // gate (CR-30): nothing reads the media key yet; the row shows once the
    // package that does sets this true
    ConfigurationValue { id: mediaSupported; key: "/org/asteroidos/modes/media-supported"; defaultValue: false }
    ConfigurationValue { id: alarmSound; key: page.keyOf("alarm-sound"); defaultValue: modeState.customizeDefault(page.mode, "alarm-sound") }
    ConfigurationValue { id: alarmVibrate; key: page.keyOf("alarm-vibrate"); defaultValue: modeState.customizeDefault(page.mode, "alarm-vibrate") }
    ConfigurationValue { id: displayFilter; key: "/org/asteroidos/modes/bedtime/display-filter"; defaultValue: "nightlight" }

    readonly property var filterValues: ["none", "grayscale", "nightlight"]
    readonly property var filterLabels: [
        //% "No color filter"
        qsTrId("id-display-default"),
        //% "Grayscale"
        qsTrId("id-display-grayscale"),
        //% "Nightlight"
        qsTrId("id-display-nightlight")
    ]
    readonly property var filterSummaries: [
        "", "",
        //% "Reduce blue light"
        qsTrId("id-display-nightlight-summary")
    ]
    readonly property int filterIndex: Math.max(0, filterValues.indexOf(String(displayFilter.value)))

    SettingsCategory {
        objectName: "notifyCategory"
        //% "What can notify you"
        text: qsTrId("id-what-can-notify")
    }
    SettingsChip {
        objectName: "starredSwitch"
        //% "Starred callers"
        title: qsTrId("id-starred-callers")
        control: "toggle"
        checked: page.on(starred.value)
        onClicked: starred.value = !page.on(starred.value)
    }
    SettingsChip {
        objectName: "repeatSwitch"
        //% "Repeat callers"
        title: qsTrId("id-repeat-callers")
        control: "toggle"
        checked: page.on(repeat.value)
        onClicked: repeat.value = !page.on(repeat.value)
    }
    SettingsChip {
        objectName: "mediaSwitch"
        visible: page.on(mediaSupported.value)
        //% "Media sounds"
        title: qsTrId("id-media-sounds")
        control: "toggle"
        checked: page.on(media.value)
        onClicked: media.value = !page.on(media.value)
    }
    SettingsCategory {
        objectName: "alarmsCategory"
        //% "Alarms and Timers"
        text: qsTrId("id-alarms-and-timers")
    }
    SettingsChip {
        objectName: "alarmSoundSwitch"
        //% "Sound"
        title: qsTrId("id-alarm-sound")
        iconName: "ios-notifications-outline"
        control: "toggle"
        checked: page.on(alarmSound.value)
        onClicked: alarmSound.value = !page.on(alarmSound.value)
    }
    SettingsChip {
        objectName: "alarmVibrateSwitch"
        //% "Vibrate"
        title: qsTrId("id-alarm-vibrate")
        iconName: "ios-watch-vibrating"
        control: "toggle"
        checked: page.on(alarmVibrate.value)
        onClicked: alarmVibrate.value = !page.on(alarmVibrate.value)
    }
    SettingsText {
        objectName: "alarmsCaption"
        text: page.on(alarmSound.value) || page.on(alarmVibrate.value)
              //% "Individual app settings for sound and vibration still apply"
              ? qsTrId("id-alarms-caption-on")
              //% "Alarms will activate silently"
              : qsTrId("id-alarms-caption-off")
    }
    SettingsCategory {
        objectName: "displayCategory"
        visible: page.isBedtime
        //% "Display options"
        text: qsTrId("id-display-options")
    }
    SettingsChip {
        objectName: "displayOptionsItem"
        visible: page.isBedtime
        title: qsTrId("id-display-options")
        summary: page.filterLabels[page.filterIndex]
        onClicked: app.choose(qsTrId("id-display-options"), page.filterLabels, page.filterIndex,
                              function (i) { displayFilter.value = page.filterValues[i] },
                              page.filterSummaries)
    }
}
