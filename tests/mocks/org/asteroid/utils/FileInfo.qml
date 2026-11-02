// Test double for the Settings tests (see tests/tst_settings.qml)
pragma Singleton
import QtQuick
QtObject {
    function exists(fileName) { return false }
}
