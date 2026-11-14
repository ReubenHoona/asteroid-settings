/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick

// The watch's own apps and services as the Apps & notifications pages list
// them (settings-b-04, settings-b-05).
// - notifying: the watch apps that post notifications of their own (the
//   per-app switch of Notifications > App notifications); id is what the
//   launcher's notification manager matches in
//   /org/asteroidos/notifications/disabled-apps (the desktop id of an app, a
//   lipstick category for a system one); core: listed under "Core system
//   apps" (stock's system-category filter).
// - services: the background services of the image, listed as "System apps"
//   in App info (stock's System apps) when their package is installed;
//   process: what Force stop looks for.
QtObject {
    readonly property var notifying: [
        //% "Alarm clock"
        { "id": "asteroid-alarmclock", "name": qsTrId("id-app-alarm-clock"), "core": false },
        //% "Timer"
        { "id": "asteroid-timer", "name": qsTrId("id-app-timer"), "core": false },
        { "id": "asteroid-assistant", "name": qsTrId("id-assistant-page"), "core": false },
        { "id": "eos-update", "name": qsTrId("id-system-updates"), "core": true },
        { "id": "battery", "name": qsTrId("id-battery-page"), "core": true },
        { "id": "bluetooth", "name": qsTrId("id-bluetooth-page"), "core": true }
    ]
    readonly property var services: [
        //% "Phone sync"
        { "id": "asteroid-btsyncd", "name": qsTrId("id-app-phone-sync"), "process": "asteroid-btsyncd" },
        //% "Sensor logger"
        { "id": "asteroid-sensorlogd", "name": qsTrId("id-app-sensor-logger"), "process": "asteroid-sensorlogd" },
        { "id": "eos-update", "name": qsTrId("id-system-updates"), "process": "eos-update" },
        //% "Weather service"
        { "id": "eos-weather", "name": qsTrId("id-app-weather-service"), "process": "eos-weather" }
    ]
}
