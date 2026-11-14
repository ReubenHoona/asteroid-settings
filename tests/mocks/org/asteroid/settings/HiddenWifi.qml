/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import SettingsTest

// The test double of the C++ HiddenWifi (src/hiddenwifi.cpp, which has its own
// unit test against a fake connman): records the ConnectService call and
// answers with Backend.hiddenError ("" = connman took it).
QtObject {
    property bool busy: false
    signal finished(bool ok, string error)
    function connectNetwork(ssid, security, passphrase) {
        Backend.record("connman", "ConnectService", [ssid, security, passphrase])
        finished(Backend.hiddenError === "", Backend.hiddenError)
    }
}
