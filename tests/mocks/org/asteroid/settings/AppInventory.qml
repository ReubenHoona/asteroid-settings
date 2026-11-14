/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import SettingsTest

// The test double of the C++ AppInventory (src/appinventory.cpp): the apps,
// packages, running processes and sizes of Backend.inv, every force stop,
// clear and size request recorded in Backend.calls (target "apps").
QtObject {
    id: inv

    property string statusFile: ""
    signal sizesReady(string key, double appBytes, double dataBytes, double cacheBytes)

    function launcherApps() { return Backend.inv.apps }
    function packageOf(id) { return Backend.inv.owners[id] || "" }
    function version(pkg) { return Backend.inv.packages[pkg] || "" }
    function isRunning(process) { return process !== "" && Backend.inv.running[process] === true }
    function forceStop(process) {
        Backend.record("apps", "forceStop", [process])
        if (!isRunning(process))
            return 0
        var r = Backend.inv.running
        r[process] = false
        return 1
    }
    property var queue: []
    function computeSizes(key, names, pkg) {
        Backend.record("apps", "computeSizes", [key, names, pkg])
        var q = queue.slice()
        q.push(key)
        queue = q
        answer.interval = Math.max(1, Backend.inv.sizeDelay)
        answer.start()
    }
    function sizeOf(key) {
        return Backend.inv.sizes[key] || { "app": 0, "data": 0, "cache": 0 }
    }
    property Timer answer: Timer {
        onTriggered: {
            var q = inv.queue
            inv.queue = []
            for (var i = 0; i < q.length; i++) {
                var s = inv.sizeOf(q[i])
                inv.sizesReady(q[i], s.app, s.data, s.cache)
            }
        }
    }
    function _forget(names, field) {
        for (var key in Backend.inv.sizes)
            if (names.indexOf(key) >= 0)
                Backend.inv.sizes[key][field] = 0
    }
    function clearData(names) {
        Backend.record("apps", "clearData", [names])
        _forget(names, "data")
        return true
    }
    function clearCache(names) {
        Backend.record("apps", "clearCache", [names])
        _forget(names, "cache")
        return true
    }
}
