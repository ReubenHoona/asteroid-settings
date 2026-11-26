/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import Nemo.Mce

// Settings > Battery as stock CP3A (PixelWatchNavRouteCollector$init$2:39-47,
// BatteryStatusItemKt:80-81,202,270): the charge in large letters, start
// aligned, a progress bar of it, "Charge remaining" under it (the charger
// words of the older Wear OS are gone, and there is no time left), then the
// rows Battery Saver (its own page, with
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

    // BatteryStatusItem as the Wear OS 6 emulator draws it (S20; NEWLOOK-61
    // N61-44), aligned to the start 14 dp in (x 48; CP3A
    // BatteryStatusItemKt.java:141-142,202, D60-39), the first row under the
    // title (its top at y 123):
    // - the digits in white #FFFFFF, 24 sp (48 px, numeralExtraSmall), their
    //   cap top 5 dp under the top (y 133), the % sign in 20 sp (40 px,
    //   labelLarge) on their baseline; the emulator's Google Sans Flex
    //   digits are 36 px tall, Noto Sans' 34 px;
    // - a flat bar 8 dp (16 px) tall at y 184-199, x 48-335, fully round:
    //   the charge in #FFFFFF from the start on a #3C4043 track, no gap, no
    //   stop dot (91 %: white to x 310);
    // - "Charge remaining" in labelSmall (13 sp = 26 px) onSurface #E8E7EE,
    //   its cap top at y 220, the next row at y 268.
    // CP3A drew numeralSmall (30 sp) digits with a titleLarge (18 sp) sign,
    // the M3 LinearProgressIndicator (8 px, a 4 dp gap and a stop dot,
    // tertiary on surfaceContainer) and the label, all onSurfaceVariant
    // (:202-270).
    Item {
        id: header
        objectName: "batteryHeader"
        width: parent.width
        // 11 dp under the label's baseline (the next row 8 px further)
        height: Math.round(remaining.y + remaining.baselineOffset + Theme.dp(11))
        visible: batteryLevel.valid
        // under the header's top: the digits' cap top, the bar, the label's cap top
        readonly property real digitsCapTop: Theme.dp(5)
        readonly property real barTop: Theme.dp(30.5)
        readonly property real labelCapTop: Theme.dp(48.5)
        // the start inset, as the rows' content padding (14 dp)
        readonly property real inset: Theme.dp(14)
        // packed with the page's rows (SettingsChip)
        EdgeEffect { id: headerEdge; item: header; packed: true }
        opacity: headerEdge.alpha
        transform: [
            Scale {
                origin.x: header.width / 2
                origin.y: headerEdge.originY
                xScale: headerEdge.scale
                yScale: headerEdge.scale
            },
            Translate { y: headerEdge.translateY }
        ]
        Row {
            x: header.inset
            width: header.width - 2 * header.inset
            // the cap top of a flat-topped digit where it belongs (read
            // again when the font changes: the role sets its weight later)
            y: digitsMetrics.font.pixelSize > 0
               ? Math.round(header.digitsCapTop - digits.baselineOffset - digitsMetrics.tightBoundingRect("7").y) : 0
            Label {
                id: digits
                objectName: "batteryPercent"
                role: "numeralExtraSmall"
                color: Theme.color.onBackground
                text: batteryLevel.valid ? String(batteryLevel.percent) : ""
                clip: false
                FontMetrics { id: digitsMetrics; font: digits.font }
            }
            Label {
                id: sign
                objectName: "batteryPercentSign"
                role: "labelLarge"
                color: Theme.color.onBackground
                text: "%"
                y: digits.baselineOffset - baselineOffset
                clip: false
            }
        }
        // the charge: a round white bar from the start over the round track
        Rectangle {
            id: bar
            objectName: "batteryBar"
            readonly property real progress: batteryLevel.valid ? Math.max(0, Math.min(1, batteryLevel.percent / 100)) : 0
            readonly property color fillColor: "#FFFFFF"
            x: header.inset
            y: header.barTop
            width: header.width - 2 * header.inset
            height: Theme.dp(8)
            radius: height / 2
            color: "#3C4043"
            Rectangle {
                objectName: "batteryBarFill"
                anchors.left: parent.left
                height: parent.height
                // round ends: a level above 0 is at least a dot
                width: bar.progress > 0 ? Math.max(parent.height, Math.round(parent.width * bar.progress)) : 0
                radius: height / 2
                color: bar.fillColor
            }
        }
        Label {
            id: remaining
            objectName: "batteryRemaining"
            x: header.inset
            width: header.width - 2 * header.inset
            y: remainingMetrics.font.pixelSize > 0
               ? Math.round(header.labelCapTop - baselineOffset - remainingMetrics.tightBoundingRect("H").y) : 0
            role: "labelSmall"
            color: Theme.color.onSurface
            // TextAlign.Start: the natural alignment (left, right in
            // a right-to-left language)
            //% "Charge remaining"
            text: qsTrId("id-battery-charge-remaining")
            clip: false
            FontMetrics { id: remainingMetrics; font: remaining.font }
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
