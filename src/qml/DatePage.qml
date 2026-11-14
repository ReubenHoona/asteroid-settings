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

// Settings > Date & time > Set date: the Wear Material 3 DatePicker (stock
// route DATE_PICKER, ClockworkNavRouteCollector$init$27:43-58). The date is
// built in one step from the three columns, so a day the current month does
// not have is not rolled over into the next month first (E17,
// dialogs-pickers-feedback-15: 31 December on 10 November used to store
// 1 December); the picker keeps a day that the picked month lacks from being
// confirmed, and store() clamps all the same.
Item {
    id: root
    objectName: "datePage"
    property int depth
    property var pop

    // stock's picker is a dialog over the screen: no time text above its heading
    Component.onCompleted: app.showTime = false
    Component.onDestruction: app.showTime = true

    DateTimeSettings { id: dtSettings }

    // the date shown at first: today
    readonly property date start: new Date()

    // year, month (1-12) and day as picked; the time of day stays as it is
    function store(year, month, day) {
        var now = new Date()
        var last = new Date(year, month, 0).getDate()
        dtSettings.setDate(new Date(year, month - 1, Math.min(day, last),
                                    now.getHours(), now.getMinutes(), now.getSeconds()))
    }

    DatePicker {
        id: picker
        objectName: "datePicker"
        anchors.fill: parent
        date: root.start
        onConfirmed: (year, month, day) => {
            root.store(year, month, day)
            root.pop()
        }
    }
}
