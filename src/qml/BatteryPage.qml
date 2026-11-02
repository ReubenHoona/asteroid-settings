/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Mce

// Settings > Battery (stock prefs_battery_saver.xml): the charge in large
// letters (BatteryPercentPreference) and under it what the charger does
// (the stock battery_info_status words), from mce; then Battery saver
// (the launcher's modes engine: always-on screen and tilt-to-wake off; it
// goes off on the charger and comes back when unplugged), unchecked and
// greyed out while plugged in, asking before it turns on, as stock.
SettingsPage {
    id: page
    objectName: "batteryPage"
    title: qsTrId("id-battery-page")

    MceBatteryLevel { id: batteryLevel }
    MceBatteryState { id: batteryState }
    MceChargerType { id: chargerType }

    readonly property bool plugged: chargerType.type != MceChargerType.None

    Label {
        objectName: "batteryPercent"
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: batteryLevel.valid ? qsTrId("id-battery-percent").arg(batteryLevel.percent) : ""
        font.pixelSize: Dims.l(16)
        font.styleName: "SemiCondensed Medium"
        clip: false
    }
    SettingsText {
        objectName: "batteryStatus"
        horizontalAlignment: Text.AlignHCenter
        text: batteryState.value == MceBatteryState.Charging
              //% "Charging"
              ? qsTrId("id-battery-charging")
              : batteryState.value == MceBatteryState.Full
              //% "Charged"
              ? qsTrId("id-battery-charged")
              : page.plugged
              //% "Connected, not charging"
              ? qsTrId("id-battery-not-charging-plugged")
              //% "Not charging"
              : qsTrId("id-battery-discharging")
    }
    SettingsChip {
        objectName: "batterySaverSwitch"
        title: qsTrId("id-battery-saver")
        control: "toggle"
        active: !page.plugged
        checked: modeState.batterySaver && !page.plugged
        onClicked: {
            if (modeState.batterySaver) {
                modeState.batterySaver = false
                return
            }
            app.turnOnBatterySaver()
        }
    }
    SettingsText {
        text: qsTrId("id-saver-explain")
    }
}
