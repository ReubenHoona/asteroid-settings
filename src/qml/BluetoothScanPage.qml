/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings
import "BtIcons.js" as BtIcons

// Settings > Connectivity > Bluetooth > Pair new device (stock
// BluetoothScanFragment, prefs_bluetooth_scan.xml): the devices found, one
// row each, then the scan row, "Scan for nearby devices", which reads
// "Scanning for nearby devices…" and is greyed while a scan runs. The scan
// starts when the page opens and ends by itself after 12.8 s, the length of
// Android's inquiry (10 x 1.28 s), or when the page is left, covered (the
// pairing page, the error page) or the app goes to the background (stock:
// onPause cancels discovery). A tap on a device pairs it (the launcher's
// Bluetooth agent shows the passkey or consent dialog); a failure opens
// "Couldn't connect with %1" with Try again and Cancel. Discovery is the one
// thing here that uses the radio: it is a single bounded scan, no repeat.
SettingsPage {
    id: page
    objectName: "bluetoothScanPage"
    //% "Pair new device"
    title: qsTrId("id-bluetooth-pair-new")

    // stock: Android's inquiry length, 10 x 1.28 s
    readonly property int scanMs: 12800
    // this page is what the person looks at, with the app in front
    readonly property bool foreground: layerStack.currentLayer === page && Qt.application.state === Qt.ApplicationActive

    function scan() {
        if (!found.powered)
            return
        found.startDiscovery()
        scanTimer.restart()
    }
    function stopScan() {
        scanTimer.stop()
        found.stopDiscovery()
    }
    onForegroundChanged: if (!foreground) stopScan()
    Component.onCompleted: scan()
    Component.onDestruction: stopScan()

    Component { id: errorLayer; BluetoothPairErrorPage { } }

    BluetoothDevices {
        id: found
        filter: "available"
        onPairFailed: (path, name) => {
            if (layerStack.currentLayer === page)
                layerStack.push(errorLayer, { devices: found, devicePath: path, deviceName: name })
        }
        // Bluetooth went off under the page: no scan
        onPoweredChanged: if (!powered) page.stopScan()
    }
    // one shot: the scan ends, the row comes back
    Timer {
        id: scanTimer
        interval: page.scanMs
        onTriggered: found.stopDiscovery()
    }

    Repeater {
        model: found
        delegate: SettingsChip {
            objectName: "bluetoothFound"
            title: model.name
            summary: model.pairing ? qsTrId("id-bluetooth-pairing") : ""
            iconName: BtIcons.deviceIcon(model.icon)
            active: !model.pairing
            onClicked: found.pair(model.path)
        }
    }
    SettingsChip {
        objectName: "bluetoothScanRow"
        title: found.discovering
               //% "Scanning for nearby devices…"
               ? qsTrId("id-bluetooth-scanning")
               //% "Scan for nearby devices"
               : qsTrId("id-bluetooth-scan")
        iconName: "ios-search-outline"
        active: !found.discovering && found.powered
        onClicked: page.scan()
    }
}
