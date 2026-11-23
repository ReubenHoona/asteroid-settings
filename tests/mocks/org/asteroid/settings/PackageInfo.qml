/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import SettingsTest

// The test double of the C++ PackageInfo (src/packageinfo.cpp).
QtObject {
    id: mock
    property string statusFile: ""
    property string infoDir: ""
    function version(name) { return name === "asteroid-launcher" ? "2.0+git0+0a1b2c3-r0" : "" }
    function installedSize(name) { return name === "asteroid-launcher" ? 20000000 : 0 }
    // what the C++ reads from <infoDir>/*.control: a few parts of the image
    // 59 rootfs as they are there, sorted; none while the test key is set
    function licenses() {
        if (Backend.confGet("/test/package-info/no-licenses"))
            return []
        return [
            { "name": "asteroid-settings", "license": "GPL-3.0-only", "packages": ["asteroid-settings"] },
            { "name": "eos-kernel-boot", "license": "GPL-2.0-only", "packages": ["eos-kernel-boot"] },
            { "name": "glibc", "license": "GPL-2.0-only & LGPL-2.1-or-later", "packages": ["ldconfig", "libc6"] },
            { "name": "kmod", "license": "kmod: GPL-2.0-or-later & LGPL-2.1-or-later\nlibkmod2: LGPL-2.1-or-later",
              "packages": ["kmod", "libkmod2"] },
            { "name": "qml-asteroid", "license": "LGPL-2.1-only", "packages": ["qml-asteroid"] },
            { "name": "qtbase", "license": "(The-Qt-Company-Commercial | (GPL-3.0-only & Qt-GPL-exception-1.0) & (LGPL-3.0-only | GPL-2.0-only | GPL-3.0-only) & GFDL-1.3-no-invariants-only) & Apache-2.0 & BSD-3-Clause & BSL-1.0 & LGPL-2.1-or-later & HPND & MIT",
              "packages": ["qtbase", "qtbase-plugins", "qtbase-qmlplugins"] }
        ]
    }
    // as the C++: the parts come back later, from a worker thread there
    signal licensesRead(var parts)
    function readLicenses() { _reply.start() }
    property Timer _reply: Timer {
        interval: 1
        onTriggered: mock.licensesRead(mock.licenses())
    }
}
