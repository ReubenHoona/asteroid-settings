/*
 * Copyright (C) 2023 - Timo Könnecke <github.com/eLtMosen>
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
import org.asteroid.settings
import Nemo.Configuration
import Nemo.Mce

// Display > Nightstand, the watch face the launcher shows on the charger,
// as a stock settings list: the switch, its brightness (slider), how long
// it waits (a list), its always-on screen, and its own watch face.
SettingsPage {
    id: page
    objectName: "nightstandPage"
    title: qsTrId("id-nightstand-page")

    ConfigurationValue {
        id: nightstandBrightness
        key: "/desktop/asteroid/nightstand/brightness"
        defaultValue: 30
    }
    ConfigurationValue {
        id: nightstandDelay
        key: "/desktop/asteroid/nightstand/delay"
        defaultValue: 5
    }
    ConfigurationValue {
        id: nightstandEnabled
        key: "/desktop/asteroid/nightstand/enabled"
        defaultValue: true
    }
    ConfigurationValue {
        id: nightstandUseCustomWatchface
        key: "/desktop/asteroid/nightstand/use-custom-watchface"
        defaultValue: false
    }
    ConfigurationValue {
        id: nightstandAlwaysOnDisplay
        key: "/desktop/asteroid/nightstand/always-on-display"
        defaultValue: true
    }
    DisplaySettings { id: displaySettings }
    MceChargerType { id: mceChargerType }

    readonly property var delays: [0, 5, 10, 15, 20, 25, 30]
    function delayLabel(s) {
        return s === 0
            //% "Immediately"
            ? qsTrId("id-immediately")
            //% "After %1 seconds"
            : qsTrId("id-after-seconds").arg(s)
    }

    SettingsChip {
        objectName: "nightstandSwitch"
        title: qsTrId("id-nightstand-page")
        control: "toggle"
        checked: nightstandEnabled.value
        onClicked: nightstandEnabled.value = !nightstandEnabled.value
    }
    SettingsText {
        //% "A watch face for the night while the watch charges"
        text: qsTrId("id-nightstand-explain")
    }
    SettingsCategory {
        text: qsTrId("id-nightstand-brightness")
        opacity: nightstandEnabled.value ? 1.0 : 0.38
    }
    SettingsSlider {
        objectName: "nightstandBrightness"
        active: nightstandEnabled.value
        from: 0
        to: 100
        stepSize: 10
        value: nightstandBrightness.value
        onMoved: (newValue) => nightstandBrightness.value = newValue
    }
    SettingsChip {
        objectName: "nightstandDelay"
        active: nightstandEnabled.value
        title: qsTrId("id-nightstand-delay")
        summary: page.delayLabel(Number(nightstandDelay.value))
        onClicked: {
            var labels = []
            for (var i = 0; i < page.delays.length; i++)
                labels.push(page.delayLabel(page.delays[i]))
            app.choose(qsTrId("id-nightstand-delay"), labels, page.delays.indexOf(Number(nightstandDelay.value)),
                       function (i) { nightstandDelay.value = page.delays[i] })
        }
    }
    SettingsChip {
        objectName: "nightstandAod"
        active: nightstandEnabled.value
        title: qsTrId("id-always-on-screen")
        control: "toggle"
        checked: nightstandAlwaysOnDisplay.value
        onClicked: {
            var on = !nightstandAlwaysOnDisplay.value
            nightstandAlwaysOnDisplay.value = on
            // only alter displaySettings if Nightstand mode is
            // active and we're currently on a charger
            if (nightstandEnabled.value && mceChargerType.type != MceChargerType.None)
                displaySettings.lowPowerModeEnabled = on
        }
    }
    SettingsChip {
        objectName: "nightstandCustom"
        active: nightstandEnabled.value
        title: qsTrId("id-nightstand-custom-watchface")
        control: "toggle"
        checked: nightstandUseCustomWatchface.value
        onClicked: nightstandUseCustomWatchface.value = !nightstandUseCustomWatchface.value
    }
    SettingsChip {
        objectName: "nightstandWatchface"
        active: nightstandEnabled.value && nightstandUseCustomWatchface.value
        title: qsTrId("id-nightstand-watchface")
        onClicked: layerStack.push(nightstandWatchfaceLayer)
    }
}
