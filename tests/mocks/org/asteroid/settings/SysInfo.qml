// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
QtObject {
    readonly property int uptime: 93784
    readonly property var loads: [0.42, 0.37, 0.31]
    readonly property real totalRam: 1900000000
    readonly property real freeRam: 820000000
    readonly property int threads: 412
    readonly property int memUnit: 1
    function refresh() { }
}
