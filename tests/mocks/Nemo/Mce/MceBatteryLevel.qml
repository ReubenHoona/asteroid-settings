// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
import SettingsTest
QtObject {
    readonly property bool valid: true
    readonly property int percent: Backend.batteryPercent
}
