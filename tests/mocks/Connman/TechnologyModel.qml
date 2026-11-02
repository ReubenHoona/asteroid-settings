// Test double for the Settings tests (see tests/tst_settings.qml)
// connman's TechnologyModel: one row per NetworkService of Backend.wifiServices
import QtQuick
import SettingsTest
ListModel {
    id: model
    property string name
    function requestScan() { Backend.record("connman", "requestScan", [name]) }
    function fill() {
        clear()
        for (var i = 0; i < Backend.wifiServices.length; i++)
            append({ "modelData": Backend.wifiServices[i] })
    }
    Component.onCompleted: fill()
    property Connections _watch: Connections {
        target: Backend
        function onWifiServicesChanged() { model.fill() }
    }
}
