// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
import SettingsTest
QtObject {
    signal userInputRequested(string servicePath, var fields)
    signal errorReported(string error)
    function sendUserReply(reply) { Backend.record("connman", "sendUserReply", [reply]) }
}
