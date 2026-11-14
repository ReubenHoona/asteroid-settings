/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration

// Settings > Health profile (settings-b-30, stock HealthPreference ->
// "My profile"): Gender (Female, Male, Non-binary), Height ("175 cm" or
// "5 ft 9 in") and Weight ("75 kg" or "165 lbs"), each with its value as the
// second line. Stock's defaults when nothing is set: 175 cm / 5 ft 9 in
// (HeightDataSource) and 75 kg / 165 lbs (WeightDataSource); Gender shows no
// second line until it is set. The values are what the Health and Exercise
// apps and asteroid-sensorlogd read (distance, energy, heart rate zones):
//   /org/asteroidos/health/profile/gender     s  "female", "male", "other"
//   /org/asteroidos/health/profile/height-cm  i
//   /org/asteroidos/health/profile/weight-kg  d
// Units follow the region (imperial for the US only, as the Android
// default): a metric height is a cm picker from 30 to 272 (stock MIN_CM,
// MAX_CM), an imperial one feet 1-8 and inches 0-11 (12 to 107 inches); a
// metric weight 1-907 kg, an imperial one 1-2000 lbs (WeightUnit).
SettingsPage {
    id: page
    objectName: "healthProfilePage"
    //% "My profile"
    title: qsTrId("id-my-profile")

    ConfigurationValue {
        id: gender
        key: "/org/asteroidos/health/profile/gender"
        defaultValue: ""
    }
    ConfigurationValue {
        id: heightCm
        key: "/org/asteroidos/health/profile/height-cm"
        defaultValue: 0
    }
    ConfigurationValue {
        id: weightKg
        key: "/org/asteroidos/health/profile/weight-kg"
        defaultValue: 0
    }

    Component { id: pickerLayer; ProfilePickerPage { } }

    property bool imperial: Qt.locale().measurementSystem === Locale.ImperialUSSystem

    // ---- gender: stock's order Female, Male, Non-binary
    readonly property var genders: ["female", "male", "other"]
    readonly property var genderNames: [
        //% "Female"
        qsTrId("id-gender-female"),
        //% "Male"
        qsTrId("id-gender-male"),
        //% "Non-binary"
        qsTrId("id-gender-non-binary")]
    readonly property int genderIndex: {
        var g = String(gender.value)
        if (g === "non_binary" || g === "non-binary")
            return 2
        return genders.indexOf(g)
    }

    // ---- height, kept in centimetres
    readonly property int minCm: 30
    readonly property int maxCm: 272
    readonly property int defaultCm: 175
    readonly property int cm: {
        var v = Math.round(Number(heightCm.value))
        return v > 0 ? Math.max(minCm, Math.min(maxCm, v)) : defaultCm
    }
    // total inches, 12..107 (stock Height.toUnits)
    readonly property int inches: Math.max(12, Math.min(107, Math.round(cm / 2.54)))
    readonly property string heightText: imperial
        //% "%1 ft %2 in"
        ? qsTrId("id-height-feet-inches").arg(Math.floor(inches / 12)).arg(inches % 12)
        //% "%1 cm"
        : qsTrId("id-height-cm").arg(cm)

    // ---- weight, kept in kilograms
    readonly property int minKg: 1
    readonly property int maxKg: 907
    readonly property int minLbs: 1
    readonly property int maxLbs: 2000
    readonly property int defaultKg: 75
    readonly property int defaultLbs: 165
    // the weight in the shown unit
    readonly property int weight: {
        var kg = Number(weightKg.value)
        if (!(kg > 0))
            return imperial ? defaultLbs : defaultKg
        return imperial ? Math.max(minLbs, Math.min(maxLbs, Math.round(kg * 2.2046244201837775)))
                        : Math.max(minKg, Math.min(maxKg, Math.round(kg)))
    }
    readonly property string weightText: imperial
        //% "%1 lbs"
        ? qsTrId("id-weight-lbs").arg(weight)
        //% "%1 kg"
        : qsTrId("id-weight-kg").arg(weight)

    // ---- what the pickers store
    function setHeightCm(v) { heightCm.value = Math.max(minCm, Math.min(maxCm, Math.round(v))) }
    function setHeightInches(total) { setHeightCm(Math.max(12, Math.min(107, total)) * 2.54) }
    function setWeight(v) {
        // a weight in pounds is kept in kilograms (one decimal)
        weightKg.value = imperial ? Math.round(v * 0.453592 * 10) / 10 : v
    }

    SettingsChip {
        objectName: "genderItem"
        //% "Gender"
        title: qsTrId("id-gender")
        summary: page.genderIndex >= 0 ? page.genderNames[page.genderIndex] : ""
        onClicked: app.choose(qsTrId("id-gender"), page.genderNames, page.genderIndex,
                              function (i) { gender.value = page.genders[i] })
    }
    SettingsChip {
        objectName: "heightItem"
        //% "Height"
        title: qsTrId("id-height")
        summary: page.heightText
        onClicked: {
            var columns
            if (page.imperial)
                columns = [{ "label": qsTrId("id-height"), "count": 8, "repeat": false,
                             "text": function (o) {
                                 //% "%1 ft"
                                 return qsTrId("id-height-ft").arg(o + 1) },
                             "initial": function () { return Math.floor(page.inches / 12) - 1 } },
                           { "label": qsTrId("id-height"), "count": 12, "repeat": false,
                             "text": function (o) {
                                 //% "%1 in"
                                 return qsTrId("id-height-in").arg(o) },
                             "initial": function () { return page.inches % 12 } }]
            else
                columns = [{ "label": qsTrId("id-height"), "count": page.maxCm - page.minCm + 1, "repeat": false,
                             "text": function (o) { return qsTrId("id-height-cm").arg(o + page.minCm) },
                             "initial": function () { return page.cm - page.minCm } }]
            layerStack.push(pickerLayer, {
                "title": qsTrId("id-height"), "columns": columns,
                "done": function (values) {
                    if (page.imperial)
                        page.setHeightInches((values[0] + 1) * 12 + values[1])
                    else
                        page.setHeightCm(values[0] + page.minCm)
                }
            })
        }
    }
    SettingsChip {
        objectName: "weightItem"
        //% "Weight"
        title: qsTrId("id-weight")
        summary: page.weightText
        onClicked: {
            var low = page.imperial ? page.minLbs : page.minKg
            var count = (page.imperial ? page.maxLbs : page.maxKg) - low + 1
            layerStack.push(pickerLayer, {
                "title": qsTrId("id-weight"),
                "columns": [{ "label": qsTrId("id-weight"), "count": count, "repeat": false,
                              "text": function (o) {
                                  return page.imperial ? qsTrId("id-weight-lbs").arg(o + low)
                                                       : qsTrId("id-weight-kg").arg(o + low)
                              },
                              "initial": function () { return page.weight - low } }],
                "done": function (values) { page.setWeight(values[0] + low) }
            })
        }
    }
}
