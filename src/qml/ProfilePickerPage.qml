/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// The Wear Material 3 number picker dialog of Health profile (Height and
// Weight: HeightPickerDialogKt, WeightPickerDialogKt) on its own layer, as
// the Set date page does: the title as the heading, the columns of the
// profile (feet and inches, or one number), Confirm at the edge. columns is
// the list of PickerGroup column descriptions; done(values) gets the option
// picked in each column.
Item {
    id: root
    objectName: "profilePickerPage"
    property int depth
    property var pop

    property string title: ""
    property var columns: []
    property var done: null

    // stock's picker is a dialog over the screen: no time text above it
    Component.onCompleted: app.showTime = false
    Component.onDestruction: app.showTime = true

    NumberPicker {
        id: picker
        objectName: "profilePicker"
        anchors.fill: parent
        title: root.title
        columns: root.columns
        onConfirmed: (values) => {
            if (root.done)
                root.done(values)
            root.pop()
        }
    }
}
