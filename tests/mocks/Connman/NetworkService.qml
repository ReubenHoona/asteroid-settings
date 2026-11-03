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
    property string state: connected ? "ready" : "idle"
    property string error: ""
    property var security: ["psk"]
    property var ipv4: ({ "Address": "192.0.2.10" })
    property var ipv6: ({ "Address": "2001:db8::10" })
    property var ethernet: ({ "Address": "02:00:00:00:00:01" })
    signal connectRequestFailed(string error)
    function requestConnect() { Backend.record("connman", "requestConnect", [name]) }
    function requestDisconnect() { Backend.record("connman", "requestDisconnect", [name]) }
    function remove() { Backend.record("connman", "remove", [name]) }
}
