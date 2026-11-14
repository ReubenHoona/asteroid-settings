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

// Settings > Date & time > Set time: the Wear Material 3 TimePicker (stock
// route TIME_PICKER, ClockworkNavRouteCollector$init$27:43-58). Its type is
// automatic: 24 hours, or hours, minutes and AM/PM by the time format of the
// watch (use-12h-format, as DateFormat.is24HourFormat; TimePickerKt.java:445).
Item {
    id: root
    objectName: "timePage"
    property int depth
    property var pop

    // stock's picker is a dialog over the screen: no time text above its heading
    Component.onCompleted: app.showTime = false
    Component.onDestruction: app.showTime = true

    DateTimeSettings { id: dtSettings }

    // the time shown at first: now
    readonly property date start: new Date()

    TimePicker {
        id: picker
        objectName: "timePicker"
        anchors.fill: parent
        type: "auto"
        hour: root.start.getHours()
        minute: root.start.getMinutes()
        onConfirmed: (hour, minute, second) => {
            dtSettings.setTime(hour, minute)
            root.pop()
        }
    }
}
