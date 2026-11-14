/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Battery > Charging preferences as stock CP3A
// (ChargingPreference:33-36, AdaptiveChargingPreference:112-116): the switch
// Adaptive charging (the Pixel setting, off by default) and its caption. The
// row that opens this page shows only once the charger driver can slow or
// limit charging (/org/asteroidos/battery/charge-control).
SettingsPage {
    id: page
    objectName: "chargingPage"
    //% "Charging preferences"
    title: qsTrId("id-charging-preferences")

    ConfigurationValue {
        id: adaptive
        key: "/org/asteroidos/battery/adaptive-charging"
        defaultValue: false
    }

    SettingsChip {
        objectName: "adaptiveChargingSwitch"
        //% "Adaptive charging"
        title: qsTrId("id-adaptive-charging")
        control: "toggle"
        checked: adaptive.value
        onClicked: adaptive.value = !adaptive.value
    }
    SettingsText {
        objectName: "adaptiveChargingCaption"
        //% "Extend battery lifespan by charging steadily during larger charging periods. Activated based on your usage cycle."
        text: qsTrId("id-adaptive-charging-caption")
    }
}
