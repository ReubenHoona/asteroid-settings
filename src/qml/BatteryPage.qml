/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import Nemo.Mce

// Settings > Battery as stock CP3A (PixelWatchNavRouteCollector$init$2:39-47,
// BatteryStatusItemKt:80-81,202,270): the charge in large letters, "Charge
// remaining" under it (the charger words of the older Wear OS are gone, and
// there is no time left), then the rows Battery Saver (its own page, with
// "Will turn on at 15%" while the automatic saver is on and the saver is
// off), Battery percentage (a switch, with its caption), and, once the
// charger driver can limit charging, Battery health assistance and Charging
// preferences (settings-b-14).
SettingsPage {
    id: page
    objectName: "batteryPage"
    title: qsTrId("id-battery-page")

    MceBatteryLevel { id: batteryLevel }

    ConfigurationValue {
        id: autoSaver
        key: "/org/asteroidos/modes/battery-saver-auto-on"
        defaultValue: true
    }
    ConfigurationValue {
        id: autoOnLevel
        key: "/org/asteroidos/modes/battery-saver-auto-on-level"
        defaultValue: 15
    }
    ConfigurationValue {
        id: showPercent
        key: "/org/asteroidos/quickpanel/show-battery-percent"
        defaultValue: true
    }
    // the charger driver can limit or slow charging (set by the layer once
    // charging-battery confirms it): shows the two stock rows below
    ConfigurationValue {
        id: chargeControl
        key: "/org/asteroidos/battery/charge-control"
        defaultValue: false
    }
    ConfigurationValue {
        id: healthAssist
        key: "/org/asteroidos/battery/health-assistance"
        defaultValue: true
    }

    // the level at which the automatic saver turns on (stock overlay
    // config_automaticBatterySaverModeEntryPercentage 15)
    readonly property int onLevel: Number(autoOnLevel.value)

    // BatteryStatusItem: numeralSmall digits (30 sp = 60 px, weight 550) with
    // the % sign in titleLarge (18 sp = 36 px), both onSurfaceVariant, and
    // "Charge remaining" in labelSmall (13 sp = 26 px) under them
    Item {
        id: header
        objectName: "batteryHeader"
        width: parent.width
        height: headerColumn.height + Theme.dp(6)
        visible: batteryLevel.valid
        EdgeEffect { id: headerEdge; item: header }
        opacity: headerEdge.alpha
        transform: Scale {
            origin.x: header.width / 2
            origin.y: header.height / 2
            xScale: headerEdge.scale
            yScale: headerEdge.scale
        }
        Column {
            id: headerColumn
            width: parent.width
            Item {
                width: parent.width
                height: digits.height
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Label {
                        id: digits
                        objectName: "batteryPercent"
                        role: "numeralSmall"
                        color: Theme.color.onSurfaceVariant
                        text: batteryLevel.valid ? String(batteryLevel.percent) : ""
                        clip: false
                    }
                    Label {
                        id: sign
                        objectName: "batteryPercentSign"
                        role: "titleLarge"
                        color: Theme.color.onSurfaceVariant
                        text: "%"
                        y: digits.baselineOffset - baselineOffset
                        clip: false
                    }
                }
            }
            Label {
                objectName: "batteryRemaining"
                width: parent.width
                role: "labelSmall"
                color: Theme.color.onSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
                //% "Charge remaining"
                text: qsTrId("id-battery-charge-remaining")
                clip: false
            }
        }
    }

    SettingsChip {
        objectName: "batterySaverItem"
        //% "Battery Saver"
        title: qsTrId("id-battery-saver-page")
        summary: autoSaver.value && !modeState.batterySaver
                 //% "Will turn on at %1%"
                 ? qsTrId("id-battery-saver-will-turn-on").arg(page.onLevel) : ""
        onClicked: layerStack.push(batterySaverLayer)
    }
    SettingsChip {
        objectName: "batteryPercentSwitch"
        //% "Battery percentage"
        title: qsTrId("id-battery-percentage")
        control: "toggle"
        checked: showPercent.value
        onClicked: showPercent.value = !showPercent.value
    }
    SettingsText {
        objectName: "batteryPercentCaption"
        //% "Show battery percentage in quick settings"
        text: qsTrId("id-battery-percentage-caption")
    }
    SettingsChip {
        objectName: "batteryHealthSwitch"
        visible: chargeControl.value
        //% "Battery health assistance"
        title: qsTrId("id-battery-health")
        control: "toggle"
        checked: healthAssist.value
        onClicked: healthAssist.value = !healthAssist.value
    }
    SettingsText {
        objectName: "batteryHealthCaption"
        visible: chargeControl.value
        //% "Helps to manage your battery's long term health by adjusting charging performance and capacity."
        text: qsTrId("id-battery-health-caption")
    }
    SettingsChip {
        objectName: "chargingPrefsItem"
        visible: chargeControl.value
        //% "Charging preferences"
        title: qsTrId("id-charging-preferences")
        onClicked: layerStack.push(chargingLayer)
    }
}
