/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Location (settings-b-08, stock LocationSettingsFragment): the
// Use location switch with "From phone & watch" (default on: def_location_mode
// 3), and while it is off the footer "Location access is off for apps and
// services. Your device location may still be sent to emergency responders
// when you call or text an emergency number." App location permissions,
// Advanced and Open on phone to learn more are PermissionController /
// Wear-app concepts and stay out.
// The key is read by asteroid-map and the first-run time zone step before
// they start a position source; off, no fix is ever tried (no idle cost
// either way: positioning only runs on demand).
SettingsPage {
    id: page
    objectName: "locationPage"
    title: qsTrId("id-location-page")

    ConfigurationValue {
        id: enabled
        key: "/org/asteroidos/settings/location-enabled"
        defaultValue: true
    }
    readonly property bool on: enabled.value !== false && enabled.value !== "false"

    SettingsChip {
        objectName: "useLocationSwitch"
        //% "Use location"
        title: qsTrId("id-use-location")
        //% "From phone & watch"
        summary: qsTrId("id-use-location-summary")
        control: "toggle"
        checked: page.on
        onClicked: enabled.value = !page.on
    }
    SettingsText {
        objectName: "locationFooter"
        visible: !page.on
        //% "Location access is off for apps and services. Your device location may still be sent to emergency responders when you call or text an emergency number."
        text: qsTrId("id-location-footer-off")
    }
}
