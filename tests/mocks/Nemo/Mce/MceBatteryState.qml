// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
import SettingsTest
QtObject {
    enum State { Unknown, Charging, Discharging, NotCharging, Full }
    readonly property bool valid: true
    readonly property int value: Backend.batteryState
}
