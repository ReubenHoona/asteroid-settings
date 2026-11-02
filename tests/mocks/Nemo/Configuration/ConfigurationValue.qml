// Test double for the Settings tests (see tests/tst_settings.qml)
// Nemo.Configuration's ConfigurationValue on Backend.conf
import QtQuick
import SettingsTest

QtObject {
    id: cv
    property string key
    property var defaultValue
    property var value
    property bool _sync: false
    function _load() {
        _sync = true
        value = Backend.confHas(key) ? Backend.confGet(key) : defaultValue
        _sync = false
    }
    onKeyChanged: _load()
    onDefaultValueChanged: if (!Backend.confHas(key)) _load()
    onValueChanged: if (!_sync && key !== "") Backend.confSet(key, value)
    Component.onCompleted: _load()
    property Connections _watch: Connections {
        target: Backend
        function onConfWritten(k) { if (k === cv.key) cv._load() }
    }
}
