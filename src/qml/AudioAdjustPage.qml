/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Accessibility > Audio adjustment (accessibility-lock-security-20,
// stock AudioAdjustment): Mono audio ("Combine channels when playing audio",
// master_mono) and Audio balance, a slider of 9 steps 0, 10, 25, 40, 50, 60,
// 75, 90 and 100 with Left and Right under it. The keys hold the choice
// (mono-audio, and audio-balance as the percent towards the right); the
// audio side (a PulseAudio remap and the channel volumes) reads them.
SettingsPage {
    id: page
    objectName: "audioAdjustPage"
    //% "Audio adjustment"
    title: qsTrId("id-audio-adjustment")

    ConfigurationValue {
        id: mono
        key: "/org/asteroidos/a11y/mono-audio"
        defaultValue: false
    }
    // 0 all left .. 100 all right, 50 centred
    ConfigurationValue {
        id: balance
        key: "/org/asteroidos/a11y/audio-balance"
        defaultValue: 50
    }

    // stock's steps (percent towards the right)
    readonly property var steps: [0, 10, 25, 40, 50, 60, 75, 90, 100]
    readonly property int step: {
        var best = 4
        var v = Number(balance.value)
        for (var i = 0; i < steps.length; i++)
            if (Math.abs(steps[i] - v) < Math.abs(steps[best] - v))
                best = i
        return best
    }

    SettingsChip {
        objectName: "monoSwitch"
        //% "Mono audio"
        title: qsTrId("id-mono-audio")
        control: "toggle"
        checked: mono.value === true || mono.value === "true"
        onClicked: mono.value = !checked
    }
    SettingsText {
        objectName: "monoCaption"
        //% "Combine channels when playing audio"
        text: qsTrId("id-mono-audio-explain")
    }
    SettingsCategory {
        objectName: "balanceCategory"
        //% "Audio balance"
        text: qsTrId("id-audio-balance")
    }
    SettingsSlider {
        objectName: "balanceSlider"
        from: 0
        to: page.steps.length - 1
        stepSize: 1
        value: page.step
        //% "%1 percent audio balance"
        valueDescription: qsTrId("id-audio-balance-percent").arg(page.steps[page.step])
        onMoved: (newValue) => balance.value = page.steps[Math.round(newValue)]
    }
    Item {
        width: parent.width
        height: sideLeft.implicitHeight
        Label {
            id: sideLeft
            objectName: "balanceLeft"
            anchors.left: parent.left
            anchors.leftMargin: Theme.space.xl
            role: "labelSmall"
            color: Theme.color.onSurfaceVariant
            //% "Left"
            text: qsTrId("id-left")
        }
        Label {
            objectName: "balanceRight"
            anchors.right: parent.right
            anchors.rightMargin: Theme.space.xl
            role: "labelSmall"
            color: Theme.color.onSurfaceVariant
            //% "Right"
            text: qsTrId("id-right")
        }
    }
}
