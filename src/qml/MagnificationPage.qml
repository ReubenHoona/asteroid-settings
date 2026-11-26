/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Accessibility > Magnification as stock CP3A's magnification
// screen (MagnificationSettingsFragment, xml/perfs_magnification.xml; the
// Accessibility row opens it when persist.a11y_magnification_settings_
// screen_enabled is set, with On or Off under it): the switch Magnification
// (no dialog when turning on), the caption "Triple tap to zoom. Drag 1
// finger to move around the screen", the switch Vibrate on edge, the header
// Magnification size over a slider of seven steps with separators (1.5,
// 1.7, 2, 2.2, 2.5, 2.7 and 3 x; min 0, max 7, the value the step + 1) and
// the size centred under it ("%1$.1fx"). The first change of the switch
// turns Vibrate on edge on while that was never set (stock writes
// accessibility_display_magnification_edge_haptic_enabled 1 when it is
// empty). The keys are the launcher's (CR-34, a11y/Magnifier.qml):
// a11y/magnification b false, a11y/magnification-scale d 2.0,
// a11y/magnification-edge-haptic b false.
SettingsPage {
    id: page
    objectName: "magnificationPage"
    //% "Magnification"
    title: qsTrId("id-magnification")

    ConfigurationValue {
        id: magnification
        key: "/org/asteroidos/a11y/magnification"
        defaultValue: false
    }
    ConfigurationValue {
        id: scale
        key: "/org/asteroidos/a11y/magnification-scale"
        defaultValue: 2.0
    }
    ConfigurationValue {
        id: edge
        key: "/org/asteroidos/a11y/magnification-edge-haptic"
        defaultValue: false
    }
    // the same key with no default: undefined while it was never set
    ConfigurationValue {
        id: edgeSet
        key: "/org/asteroidos/a11y/magnification-edge-haptic"
    }

    // stock magnification_size_values, the launcher's A11y.SCALES
    readonly property var scales: [1.5, 1.7, 2.0, 2.2, 2.5, 2.7, 3.0]
    // the nearest step of the stored size (the launcher's validScale)
    readonly property int step: {
        var n = Number(scale.value)
        if (!(n > 0))
            return 2
        var best = 0
        for (var i = 1; i < scales.length; i++)
            if (Math.abs(scales[i] - n) < Math.abs(scales[best] - n))
                best = i
        return best
    }
    //% "%1x"
    readonly property string sizeText: qsTrId("id-magnification-size-value").arg(scales[step].toFixed(1))

    function isOn(v) { return v === true || v === "true" }

    SettingsChip {
        objectName: "magnificationSwitch"
        title: qsTrId("id-magnification")
        control: "toggle"
        checked: page.isOn(magnification.value)
        onClicked: {
            if (edgeSet.value === undefined || edgeSet.value === null || edgeSet.value === "")
                edge.value = true
            magnification.value = !checked
        }
    }
    SettingsText {
        objectName: "magnificationCaption"
        //% "Triple tap to zoom. Drag 1 finger to move around the screen"
        text: qsTrId("id-magnification-explain")
    }
    SettingsChip {
        objectName: "edgeHapticSwitch"
        //% "Vibrate on edge"
        title: qsTrId("id-magnification-edge-haptic")
        control: "toggle"
        checked: page.isOn(edge.value)
        onClicked: edge.value = !checked
    }
    SettingsCategory {
        objectName: "magnificationSizeCategory"
        //% "Magnification size"
        text: qsTrId("id-magnification-size")
    }
    SettingsSlider {
        objectName: "magnificationSlider"
        segmented: true
        from: 0
        to: page.scales.length
        lowest: 1
        stepSize: 1
        value: page.step + 1
        valueDescription: page.sizeText
        //% "Increase magnification size"
        increaseDescription: qsTrId("id-magnification-size-increase")
        //% "Decrease magnification size"
        decreaseDescription: qsTrId("id-magnification-size-decrease")
        onMoved: (newValue) => scale.value = page.scales[Math.max(1, Math.min(page.scales.length, Math.round(newValue))) - 1]
    }
    // settings_data_preference_centered: one line, centred, Body4
    Label {
        objectName: "magnificationSizeValue"
        width: parent.width
        topPadding: Theme.dp(8)
        bottomPadding: Theme.dp(8)
        role: "bodyMedium"
        color: Theme.color.onSurface
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: page.sizeText
    }
}
