// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
import SettingsTest
QtObject {
    function setTime(hour, minute) { Backend.record("timedate1", "SetTime", [hour, minute]) }
    function setDate(date) { Backend.record("timedate1", "SetDate", [date]) }
    function setTimezone(tz) { Backend.timezone = tz; Backend.record("timedate1", "SetTimezone", [tz]) }
    function currentTimezone() { return Backend.timezone }
}
