/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import Nemo.Mce

// Settings > Battery > Battery Saver as stock CP3A (BatterySaverViewModel,
// BatterySaverModePreference:106-129, AutomaticBatterySaverEnable/Disable
// Preference): the switch Battery Saver, which toggles at once with no
// question (the TWD9 "Turn on Battery Saver?" strings are gone) and has the
// caption of persist.sys.battery_saver_mode_v1_enabled; "Turn on at 15%"
// (automatic_power_save_mode, on by default because the level is set:
// config_automaticBatterySaverModeEntryPercentage 15 on the Pixel Watch);
// "Turn off when charged" (on by default) with its caption
// (config_automaticBatterySaverModeExitPercentage 25). The launcher's modes
// engine does the work: the saver on at 15 % off the charger, off above 25 %
// on it, from mce's battery signal (no polling). The saver goes off on the
// charger and the switch is greyed while plugged in, as it was.
SettingsPage {
    id: page
    objectName: "batterySaverPage"
    //% "Battery Saver"
    title: qsTrId("id-battery-saver-page")

    MceChargerType { id: chargerType }

    // the keys the launcher's modes engine reads (modes.cpp)
    ConfigurationValue {
        id: autoOn
        key: "/org/asteroidos/modes/battery-saver-auto-on"
        defaultValue: true
    }
    ConfigurationValue {
        id: autoOnLevel
        key: "/org/asteroidos/modes/battery-saver-auto-on-level"
        defaultValue: 15
    }
    ConfigurationValue {
        id: autoOff
        key: "/org/asteroidos/modes/battery-saver-auto-off"
        defaultValue: true
    }
    ConfigurationValue {
        id: autoOffLevel
        key: "/org/asteroidos/modes/battery-saver-auto-off-level"
        defaultValue: 25
    }

    readonly property bool plugged: chargerType.type != MceChargerType.None
    // the stock Pixel Watch levels (config_automaticBatterySaverMode*Percentage
    // 15 and 25) unless the image sets others
    readonly property int onLevel: Number(autoOnLevel.value)
    readonly property int offLevel: Number(autoOffLevel.value)

    SettingsChip {
        objectName: "batterySaverSwitch"
        title: qsTrId("id-battery-saver-page")
        control: "toggle"
        active: !page.plugged
        checked: modeState.batterySaver && !page.plugged
        onClicked: modeState.batterySaver = !modeState.batterySaver
    }
    SettingsText {
        objectName: "batterySaverCaption"
        //% "Limits background activity and turns off always-on-screen. Notifications may be delayed."
        text: qsTrId("id-battery-saver-explain")
    }
    SettingsChip {
        objectName: "autoSaverOnSwitch"
        //% "Turn on at %1%"
        title: qsTrId("id-battery-saver-auto-on").arg(page.onLevel)
        control: "toggle"
        checked: autoOn.value
        onClicked: autoOn.value = !autoOn.value
    }
    SettingsChip {
        objectName: "autoSaverOffSwitch"
        //% "Turn off when charged"
        title: qsTrId("id-battery-saver-auto-off")
        control: "toggle"
        checked: autoOff.value
        onClicked: autoOff.value = !autoOff.value
    }
    SettingsText {
        objectName: "autoSaverOffCaption"
        //% "Battery Saver turns off when your watch charges above %1%"
        text: qsTrId("id-battery-saver-auto-off-caption").arg(page.offLevel)
    }
}
