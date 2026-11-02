// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
import SettingsTest
QtObject {
    id: tw
    property bool enabled: Backend.tilt
    readonly property bool available: Backend.tiltAvailable
    onEnabledChanged: if (enabled !== Backend.tilt) {
        Backend.tilt = enabled
        Backend.record("mce", "wrist_sensor_enabled", [enabled])
    }
    property Connections _sync: Connections {
        target: Backend
        function onTiltChanged() { if (tw.enabled !== Backend.tilt) tw.enabled = Backend.tilt }
    }
}
