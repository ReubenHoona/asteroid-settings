// Test double for the Settings tests (see tests/tst_settings.qml)
// org.asteroid.utils DateFormat (ICU patterns) for TimeFormat/TimeText,
// en_GB patterns only
pragma Singleton
import QtQuick

QtObject {
    function clockPattern(use24h, locale) { return use24h ? "HH:mm" : "h:mm" }
    function timePattern(use24h, locale) { return use24h ? "HH:mm" : "h:mm a" }
    function hourPattern(use24h, locale) { return use24h ? "HH" : "h a" }
    function markerFirst(locale) { return false }
    function icuPattern(skeleton, locale) { return skeleton }
    function bestPattern(skeleton, locale) { return skeleton }
    function format(dateTime, skeleton, locale) { return Qt.formatDateTime(dateTime, skeleton === "Hm" ? "HH:mm" : skeleton === "hm" ? "h:mm AP" : skeleton) }
    function formatRange(from, to, skeleton, locale) { return format(from, skeleton, locale) + " – " + format(to, skeleton, locale) }
}
