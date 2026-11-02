/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A list setting's choices on a page of their own, as the stock settings
 * open a ListPreference (app.choose(title, options, current, apply)): a tap
 * applies the choice (apply(index)) and goes back; apply returning false
 * keeps the page, for a choice that asks first (it pops the page itself).
 */
Item {
    id: page

    property int depth
    property var pop
    property string title: ""
    property var options: []
    property var summaries: []
    property int currentIndex: -1
    property var apply: null

    ChoiceList {
        id: list
        anchors.fill: parent
        title: page.title
        model: page.options.length
        textOf: function (i) { return page.options[i] }
        summaryOf: function (i) { return page.summaries[i] || "" }
        currentIndex: page.currentIndex
        onChosen: (index) => {
            if (page.apply && page.apply(index) === false)
                return
            page.currentIndex = index
            page.pop()
        }
    }
}
