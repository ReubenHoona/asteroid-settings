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
import "LanguageNames.js" as LanguageNames

// System > Language as stock CP3A's standalone list (LocaleOnDevicePreference
// :145-148, LocaleSettingsFragment:95-99): one radio row per language, the
// language in itself as the title ("English", "Deutsch") and the country in
// that language under it ("United Kingdom"); the current one marked. A tap on
// another one switches to it and the page stays (the apps redraw in place).
// The names are LanguageNames', which System's Language row shows too.
Item {
    property int depth
    id: root
    objectName: "languagePage"
    property var pop

    // the app's list of languages, shared with System's Language row, which
    // then follows what is chosen here (main.qml languageModel)
    readonly property var langSettings: app.languageModel()

    // row i: the language in itself, the country in that language
    function nativeLanguage(i) { return LanguageNames.nativeLanguage(langSettings, i) }
    function nativeCountry(i) { return LanguageNames.nativeCountry(langSettings, i) }

    ChoiceList {
        anchors.fill: parent
        title: qsTrId("id-language-page")
        model: root.langSettings
        textOf: function (i) { return root.nativeLanguage(i) }
        summaryOf: function (i) { return root.nativeCountry(i) }
        currentIndex: root.langSettings.currentIndex
        onChosen: (index) => {
            if (index === root.langSettings.currentIndex)
                root.pop()
            else
                root.langSettings.setSystemLocale(root.langSettings.locale(index), LanguageModel.UpdateWithoutReboot)
        }
    }
}
