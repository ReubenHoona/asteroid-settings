// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
import SettingsTest
QtObject {
    enum Type { None, USB, DCP, HVDCP, CDP, Wireless, Other }
    readonly property bool valid: true
    readonly property int type: Backend.chargerType
}
