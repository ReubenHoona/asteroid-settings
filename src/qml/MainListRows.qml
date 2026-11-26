/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Nemo.Mce
import "PageReady.js" as PageReady

/*
 * The rows of the Settings main list below its first screen, in stock order
 * after Gestures (main.qml has the list, its first rows and the order). Made
 * in the background once the first frame is on screen, in main.qml's
 * context (the rows push its pages), and moved into the list's column in
 * this order. The Battery row's level comes with them: the Nemo.Mce plugin
 * and the system bus are not needed before the first frame.
 */
QtObject {
    readonly property MceBatteryLevel level: MceBatteryLevel { id: batteryLevel }

    property list<Item> rows: [
        SettingsChip {
            objectName: "buttonsItem"
            //% "Buttons"
            title: qsTrId("id-buttons-page")
            iconName: app.iconDir + "eos-settings-buttons"
            onClicked: layerStack.push(buttonsLayer)
        },
        SettingsChip {
            objectName: "appsItem"
            //% "Apps & notifications"
            title: qsTrId("id-apps-page")
            iconName: "ios-apps-outline"
            onClicked: layerStack.push(appsLayer)
        },
        SettingsChip {
            objectName: "modesItem"
            //% "Modes"
            title: qsTrId("id-modes-page")
            iconName: app.iconDir + "eos-settings-modes"
            onClicked: layerStack.push(modesLayer)
        },
        SettingsChip {
            objectName: "soundItem"
            visible: DeviceSpecs.hasSpeaker
            title: qsTrId("id-sound-page")
            iconName: "ms-volume_up"
            onClicked: layerStack.push(soundLayer)
        },
        SettingsChip {
            objectName: "vibrationItem"
            //% "Vibration"
            title: qsTrId("id-vibration-page")
            iconName: "ms-watch_vibration-fill"
            onClicked: layerStack.push(vibrationLayer)
        },
        SettingsChip {
            objectName: "batteryItem"
            //% "Battery"
            title: qsTrId("id-battery-page")
            //% "%1%"
            summary: batteryLevel.valid ? qsTrId("id-battery-percent").arg(batteryLevel.percent) : ""
            iconName: app.iconDir + "eos-settings-battery"
            onClicked: layerStack.push(batteryLayer)
        },
        SettingsChip {
            objectName: "generalItem"
            //% "General"
            title: qsTrId("id-general-page")
            iconName: "ios-watch"
            onClicked: layerStack.push(generalLayer)
        },
        SettingsChip {
            objectName: "healthProfileItem"
            visible: PageReady.healthProfile
            //% "Health profile"
            title: qsTrId("id-health-profile-page")
            iconName: "ios-heart-outline"
            onClicked: layerStack.push(healthProfileLayer)
        },
        SettingsChip {
            objectName: "locationItem"
            visible: PageReady.location
            //% "Location"
            title: qsTrId("id-location-page")
            iconName: app.iconDir + "eos-settings-location"
            onClicked: layerStack.push(locationLayer)
        },
        SettingsChip {
            objectName: "safetyItem"
            visible: PageReady.safety
            //% "Safety & Emergency"
            title: qsTrId("id-safety-page")
            iconName: "ios-medkit-outline"
            onClicked: layerStack.push(safetyLayer)
        },
        SettingsChip {
            objectName: "accessibilityItem"
            visible: PageReady.accessibility
            //% "Accessibility"
            title: qsTrId("id-accessibility-page")
            iconName: app.iconDir + "eos-settings-accessibility"
            onClicked: layerStack.push(accessibilityLayer)
        },
        SettingsChip {
            objectName: "securityItem"
            visible: PageReady.security
            //% "Security"
            title: qsTrId("id-security-page")
            iconName: app.iconDir + "eos-settings-security"
            onClicked: layerStack.push(securityLayer)
        },
        SettingsChip {
            objectName: "systemItem"
            //% "System"
            title: qsTrId("id-system-page")
            iconName: "ms-info"
            onClicked: layerStack.push(systemLayer)
        },
        SettingsChip {
            objectName: "developerItem"
            visible: developerOptions.value
            //% "Developer options"
            title: qsTrId("id-developer-page")
            iconName: "ios-code"
            onClicked: layerStack.push(developerLayer)
        }
    ]
}
