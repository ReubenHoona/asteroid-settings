// Test double for the Settings tests (see tests/tst_settings.qml)
// a made-up identity: no real serial or address in a test
import QtQuick
QtObject {
    readonly property string operatingSystemName: "AsteroidOS"
    readonly property string softwareVersion: "2.0"
    readonly property string wlanMacAddress: "02:00:00:00:00:01"
    readonly property string serial: "TEST-0000"
}
