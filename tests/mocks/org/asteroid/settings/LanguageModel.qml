// Test double for the Settings tests (see tests/tst_settings.qml)
import QtQuick
import SettingsTest
ListModel {
    id: model
    enum LocaleUpdateMode { UpdateAndReboot, UpdateWithoutReboot }
    readonly property int currentIndex: Backend.languageIndex
    ListElement { name: "Deutsch"; code: "de_DE" }
    ListElement { name: "English (United Kingdom)"; code: "en_GB" }
    ListElement { name: "Español"; code: "es_ES" }
    ListElement { name: "Français"; code: "fr_FR" }
    function languageName(i) { return get(i).name }
    function locale(i) { return get(i).code }
    function setSystemLocale(code, mode) {
        for (var i = 0; i < count; i++)
            if (get(i).code === code)
                Backend.languageIndex = i
        Backend.record("locale1", "SetLocale", [code, mode])
    }
}
