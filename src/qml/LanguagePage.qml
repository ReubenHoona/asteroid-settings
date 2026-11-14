/*
 * Copyright (C) 2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 * Copyright (C) 2015 - Florent Revest <revestflo@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.settings

// System > Language as stock CP3A's standalone list (LocaleOnDevicePreference
// :145-148, LocaleSettingsFragment:95-99): one radio row per language, the
// language in itself as the title ("English", "Deutsch") and the country in
// that language under it ("United Kingdom"); the current one marked. A tap on
// another one switches to it and the page stays (the apps redraw in place).
Item {
    property int depth
    id: root
    objectName: "languagePage"
    property var pop

    LanguageModel { id: langSettings }

    // sentence case: "français" -> "Français"
    function sentence(s) {
        return s.length > 0 ? s.charAt(0).toLocaleUpperCase() + s.slice(1) : s
    }
    // QLocale(code): the native language and territory names; the model's own
    // name when Qt does not know the code. Qt names a dialect ("British
    // English", "español de España"), stock the language: the shortest of
    // the names of the code, of the language's world locale and of its
    // default one, with a trailing " de <territory>" cut
    function nativeLanguage(i) {
        var code = String(langSettings.locale(i))
        var base = code.split(/[_@.]/)[0]
        var own = Qt.locale(code)
        if (own.name === "C")
            return langSettings.languageName(i)
        var best = ""
        var cands = [own, Qt.locale(base + "_001"), Qt.locale(base)]
        for (var k = 0; k < cands.length; k++) {
            var n = cands[k].nativeLanguageName
            if (cands[k].name !== "C" && n !== "" && (best === "" || n.length < best.length))
                best = n
        }
        var suffix = " de " + root.nativeCountry(i)
        if (suffix.length > 4 && best.length > suffix.length && best.slice(-suffix.length) === suffix)
            best = best.slice(0, -suffix.length)
        return sentence(best)
    }
    function nativeCountry(i) {
        var l = Qt.locale(langSettings.locale(i))
        return l.name !== "C" ? (l.nativeTerritoryName !== undefined ? l.nativeTerritoryName : l.nativeCountryName) : ""
    }

    ChoiceList {
        anchors.fill: parent
        title: qsTrId("id-language-page")
        model: langSettings
        textOf: function (i) { return root.nativeLanguage(i) }
        summaryOf: function (i) { return root.nativeCountry(i) }
        currentIndex: langSettings.currentIndex
        onChosen: (index) => {
            if (index === langSettings.currentIndex)
                root.pop()
            else
                langSettings.setSystemLocale(langSettings.locale(index), LanguageModel.UpdateWithoutReboot)
        }
    }
}
