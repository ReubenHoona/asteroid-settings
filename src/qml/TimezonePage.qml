/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *               2023 - Arseniy Movshev <dodoradio@outlook.com>
 *               2023 - Ed Beroset <beroset@ieee.org>
 *               2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 *               2015 - Florent Revest <revestflo@gmail.com>
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
import Nemo.DBus

Item {
    property int depth
    id: root
    property var pop
    property string selectedTz: ""
    property var timezoneList: []
    property int regionLevel: 0
    property string regionPath: ""
    // the row of the current time zone (or of the region it is in)
    property int currentRow: -1

    DateTimeSettings { id: dtSettings }

    onTimezoneListChanged: {
        // ---- top level: replace dynamic dedup with curated continent allowlist
        if (regionLevel === 0) {
            var allowlist = ["Africa", "America", "Antarctica", "Arctic", "Asia", "Atlantic", "Australia", "Europe", "Indian", "Pacific"]
            var currentRegion = root.selectedTz.split("/")[0]
            var selectIdx = 5 // ---- default to Atlantic as visual center
            for (var a = 0; a < allowlist.length; a++) {
                timezoneModel.append({"visualName": allowlist[a], "name": allowlist[a], "fullPath": "", "bottomLevel": false});
                if (allowlist[a] === currentRegion)
                    selectIdx = a
            }
            // ---- Zulu: flat single-component entry, no city subpage needed
            timezoneModel.append({"visualName": "Zulu", "name": "Zulu", "fullPath": "Zulu", "bottomLevel": true});
            if (root.selectedTz === "Zulu")
                selectIdx = allowlist.length
            root.currentRow = allowlist.indexOf(currentRegion) >= 0 || root.selectedTz === "Zulu" ? selectIdx : -1;
            return;
        }
        // ---- city level and below: existing dynamic loop unchanged
        var processedRegionList = [];
        var i = 0;
        var selectIdx = 0;
        timezoneList.forEach(function(region) {
            if(region.includes(regionPath)) {
                var tzAsList = region.split("/")
                if (tzAsList.length > (regionLevel + 1)) {
                    if (processedRegionList.indexOf(tzAsList[regionLevel]) < 0) {
                        processedRegionList.push(tzAsList[regionLevel]);
                        timezoneModel.append({"visualName": tzAsList[regionLevel].replace(/_/g, " "), "name": tzAsList[regionLevel],"fullPath": region, "bottomLevel": false});
                        if(selectedTz.includes(root.regionPath + tzAsList[regionLevel])) {
                            selectIdx = i;
                        }
                        i++;
                    }
                } else {
                    timezoneModel.append({"visualName": tzAsList[regionLevel].replace(/_/g, " "), "name": tzAsList[regionLevel], "fullPath": region, "bottomLevel": true});
                    if(selectedTz.includes(root.regionPath + tzAsList[regionLevel])) {
                        selectIdx = i;
                    }
                    i++;
                }
            }
        });
        root.currentRow = root.selectedTz.indexOf(root.regionPath) === 0 ? selectIdx : -1;
    }

    ListModel {
        id: timezoneModel
        Component.onCompleted: {
            if (!root.selectedTz) {
                root.selectedTz = dtSettings.currentTimezone()
            };
            if (root.timezoneList.length < 1) {
                timedateDbus.call("ListTimezones", undefined, function(m) {
                    timezoneModel.clear();
                    root.timezoneList = m;
                });
            };
        }
    }

    // Wear OS: the regions, then their zones, as lists; the current one
    // ticked ("›" on a region); a tap on a zone sets it and goes back to
    // the settings
    ChoiceList {
        anchors.fill: parent
        title: qsTrId("id-timezone-page")
        model: timezoneModel
        textOf: function (i) { return timezoneModel.get(i).visualName }
        opensMore: function (i) { return !timezoneModel.get(i).bottomLevel }
        currentIndex: root.currentRow
        onChosen: (index) => {
            var row = timezoneModel.get(index)
            if (!row.bottomLevel) {
                layerStack.push(timezoneLayer, {"regionLevel": root.regionLevel + 1, "regionPath": root.regionPath + row.name + "/",
                                                "selectedTz": root.selectedTz, "timezoneList": root.timezoneList})
                return
            }
            if (row.fullPath !== root.selectedTz) {
                timedateDbus.typedCall("SetTimezone", [
                        { "type": "s", "value": row.fullPath },
                        { "type": "b", "value": false }
                    ],
                    function(result) { console.log('call completed with:', result) },
                    function(error, message) { console.log('call failed', error, 'message:', message) });
                root.selectedTz = row.fullPath
            }
            app.backToMainMenu()
        }
    }

    DBusInterface {
        id: timedateDbus
        bus: DBus.SystemBus
        service: "org.freedesktop.timedate1"
        path: "/org/freedesktop/timedate1"
        iface: "org.freedesktop.timedate1"
    }
}
