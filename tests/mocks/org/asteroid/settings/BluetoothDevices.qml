/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import SettingsTest

// The test double of the C++ BluetoothDevices (src/bluetoothdevices.cpp, which
// has its own unit test against a fake BlueZ): the devices of
// Backend.btDevices, the paired ones or the ones the scan found, with the
// calls recorded as BlueZ would get them.
ListModel {
    id: model
    property string filter: "paired"
    readonly property bool available: Backend.btAvailable
    readonly property bool powered: Backend.btPowered
    readonly property bool discovering: Backend.btDiscovering
    property int revision: 0
    property bool _started: false

    signal pairFailed(string path, string name)
    signal connectFailed(string path, string name)
    signal paired(string path)

    function fill() {
        clear()
        var all = Backend.btDevices
        for (var i = 0; i < all.length; i++) {
            var d = all[i]
            var want = filter === "paired" ? d.paired : (!d.paired && d.seen)
            if (!want)
                continue
            append({ "path": d.path, "name": d.name, "address": "", "paired": d.paired, "connected": d.connected,
                     "connecting": !!d.connecting, "pairing": !!d.pairing, "icon": d.icon || "", "rssi": d.rssi || -60 })
        }
        revision++
    }
    onFilterChanged: fill()
    Component.onCompleted: fill()
    property Connections _watch: Connections {
        target: Backend
        function onBtDevicesChanged() { model.fill() }
    }

    function device(path) {
        var all = Backend.btDevices
        for (var i = 0; i < all.length; i++)
            if (all[i].path === path)
                return { "path": path, "name": all[i].name, "paired": all[i].paired, "connected": all[i].connected,
                         "connecting": !!all[i].connecting, "pairing": !!all[i].pairing, "icon": all[i].icon || "" }
        return ({})
    }
    function startDiscovery() {
        if (!Backend.btPowered)
            return
        _started = true
        Backend.record("bluez", "Adapter1.StartDiscovery", [])
        Backend.btDiscovering = true
        // everything near is heard at once
        var all = Backend.btDevices.slice()
        for (var i = 0; i < all.length; i++)
            if (!all[i].paired && all[i].near)
                all[i].seen = true
        Backend.btDevices = all
    }
    function stopDiscovery() {
        if (!_started)
            return
        _started = false
        Backend.record("bluez", "Adapter1.StopDiscovery", [])
        Backend.btDiscovering = false
    }
    function pair(path) {
        stopDiscovery()
        Backend.record("bluez", "Device1.Pair", [path])
        var d = device(path)
        if (Backend.btPairFails) {
            model.pairFailed(path, d.name)
            return
        }
        Backend.btSet(path, { "paired": true, "connected": true })
        model.paired(path)
    }
    function connectDevice(path) {
        Backend.record("bluez", "Device1.Connect", [path])
        Backend.btSet(path, { "connected": true })
    }
    function disconnectDevice(path) {
        Backend.record("bluez", "Device1.Disconnect", [path])
        Backend.btSet(path, { "connected": false })
    }
    function forget(path) {
        Backend.record("bluez", "Adapter1.RemoveDevice", [path])
        var all = Backend.btDevices
        var out = []
        for (var i = 0; i < all.length; i++)
            if (all[i].path !== path)
                out.push(all[i])
        Backend.btDevices = out
    }
    Component.onDestruction: stopDiscovery()
}
