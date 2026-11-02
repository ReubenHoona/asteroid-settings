// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
import SettingsTest
QtObject {
    id: tp
    property bool enabled: Backend.tap
    onEnabledChanged: if (enabled !== Backend.tap) {
        Backend.tap = enabled
        Backend.record("mce", "actions_gesture4", [enabled ? "unblank" : ""])
    }
    property Connections _sync: Connections {
        target: Backend
        function onTapChanged() { if (tp.enabled !== Backend.tap) tp.enabled = Backend.tap }
    }
}
