// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
import SettingsTest
QtObject {
    enum UpdateFrequency { Day, Minute, Second }
    property bool enabled: true
    property int updateFrequency: 1
    readonly property var time: Backend.now
}
