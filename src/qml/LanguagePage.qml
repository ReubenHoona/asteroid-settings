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

Item {
    property int depth
    id: root
    property var pop

    LanguageModel { id: langSettings }

    // Wear OS: the languages as a list, the current one marked; a tap on
    // another one switches to it
    ChoiceList {
        anchors.fill: parent
        title: qsTrId("id-language-page")
        model: langSettings
        textOf: function (i) { return langSettings.languageName(i) }
        currentIndex: langSettings.currentIndex
        onChosen: (index) => {
            if (index === langSettings.currentIndex)
                root.pop()
            else
                langSettings.setSystemLocale(langSettings.locale(index), LanguageModel.UpdateWithoutReboot)
        }
    }
}
