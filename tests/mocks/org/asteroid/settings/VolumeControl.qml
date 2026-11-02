// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
import SettingsTest
QtObject {
    id: vc
    property int volume: Backend.volume
    onVolumeChanged: if (volume !== Backend.volume) {
        Backend.volume = volume
        Backend.record("pulse", "MainVolume2.CurrentStep", [volume])
    }
    property Connections _sync: Connections {
        target: Backend
        function onVolumeChanged() { if (vc.volume !== Backend.volume) vc.volume = Backend.volume }
    }
}
