/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

.pragma library

// The icon of a Bluetooth device by its class, as stock's
// BluetoothDevices.classIcon does (headset, audio, phone, input, camera,
// printer; the Bluetooth symbol for the rest). `kind` is BlueZ's Icon
// property (freedesktop icon names derived from the class of device).
function deviceIcon(kind) {
    var k = String(kind || "")
    if (k === "audio-headset" || k === "audio-headphones" || k === "headset" || k === "headphones")
        return "ios-headset-outline"
    if (k === "audio-card" || k === "audio-speaker" || k === "multimedia-player")
        return "ios-musical-notes-outline"
    if (k === "phone")
        return "ios-phone-portrait"
    if (k === "camera-photo" || k === "camera-video")
        return "ios-camera-outline"
    if (k === "printer")
        return "ios-print-outline"
    if (k.indexOf("input-") === 0)
        return "ios-keypad-outline"
    if (k === "watch")
        return "ios-watch"
    return "ios-bluetooth-outline"
}

// Wi-Fi signal level 0-4 from connman's strength 0-100: five equal parts
// (stock: WifiEntry.getLevel() 0-4, AccessPointPreference.java:79-84)
function wifiLevel(strength) {
    var s = Number(strength)
    if (!(s > 0))
        return 0
    return Math.min(4, Math.floor(s / 20))
}

// The Settings icon of a network row: the fan with `level` arcs filled,
// with a small lock when it is secured (AccessPointPreference
// PUBLIC_AP_ICONS / SECURE_AP_ICONS); dir is app.iconDir
function wifiIcon(dir, strength, secured) {
    return dir + (secured ? "eos-wifi-secure-" : "eos-wifi-") + wifiLevel(strength)
}
