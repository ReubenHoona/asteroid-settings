// Test double for the Settings tests (see tests/tst_settings.qml)
pragma Singleton
import QtQuick
import SettingsTest
QtObject {
    // the paths that exist (Backend.files)
    function exists(fileName) { return Backend.files[fileName] === true }
}
