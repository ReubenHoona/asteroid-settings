/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import SettingsTest

// Test double of Connman's NetworkManager (offline mode = Airplane mode)
// on Backend.offline; a change is recorded as connman would get it.
QtObject {
    id: nm
    property bool offlineMode: Backend.offline
    onOfflineModeChanged: if (offlineMode !== Backend.offline) {
        Backend.offline = offlineMode
        Backend.record("connman", "OfflineMode", [offlineMode])
    }
    property Connections _sync: Connections {
        target: Backend
        function onOfflineChanged() { if (nm.offlineMode !== Backend.offline) nm.offlineMode = Backend.offline }
    }
}
