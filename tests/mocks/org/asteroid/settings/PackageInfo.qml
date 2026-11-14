/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick

// The test double of the C++ PackageInfo (src/packageinfo.cpp).
QtObject {
    property string statusFile: ""
    function version(name) { return name === "asteroid-launcher" ? "2.0+git0+0a1b2c3-r0" : "" }
    function installedSize(name) { return name === "asteroid-launcher" ? 20000000 : 0 }
}
