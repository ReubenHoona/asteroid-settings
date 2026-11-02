// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
import SettingsTest
QtObject {
    property string path
    property string name
    property bool connected: false
    property bool favorite: false
    property bool autoConnect: true
    property int strength: 60
    property var ipv4: ({ "Address": "192.0.2.10" })
    signal connectRequestFailed(string error)
    function requestConnect() { Backend.record("connman", "requestConnect", [name]) }
    function requestDisconnect() { Backend.record("connman", "requestDisconnect", [name]) }
    function remove() { Backend.record("connman", "remove", [name]) }
}
