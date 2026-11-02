// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
import SettingsTest
QtObject {
    id: nt
    property string path
    property bool powered: Backend.wifiPowered
    readonly property bool connected: Backend.wifiConnected
    onPoweredChanged: if (powered !== Backend.wifiPowered) {
        Backend.wifiPowered = powered
        Backend.record("connman", "wifi.Powered", [powered])
    }
    property Connections _sync: Connections {
        target: Backend
        function onWifiPoweredChanged() { if (nt.powered !== Backend.wifiPowered) nt.powered = Backend.wifiPowered }
    }
}
