/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A choice as Wear OS settings offer it: a list of 96 px rows (the round
 * screen's ListRow, scaled and faded at the edges, scrolled by the crown),
 * the title scrolling with them, a tick on the current choice. A tap on a
 * row chooses it (chosen); a row that opens more choices shows "›".
 * It replaces the picker with a tick button below it that these pages had.
 *
 *   ChoiceList {
 *       anchors.fill: parent
 *       title: qsTrId("id-language-page")
 *       model: languages            // count and the texts:
 *       textOf: function (i) { return languages.languageName(i) }
 *       currentIndex: languages.currentIndex
 *       onChosen: (index) => ...
 *   }
 */
ListView {
    id: list

    property string title: ""
    /* text of row i (default: the model's "text" role) */
    property var textOf: function (i) { return "" }
    /* row i leads to more choices (a "›" instead of a tick) */
    property var opensMore: function (i) { return false }
    signal chosen(int index)

    property real rowHeight: Dims.h(25)

    clip: false
    boundsBehavior: Flickable.StopAtBounds
    highlightFollowsCurrentItem: false
    // the first and the last rows can come to the middle of the circle
    topMargin: 0
    bottomMargin: Dims.h(20)

    // the current choice in the middle when the page opens
    function showCurrent() {
        if (currentIndex >= 0)
            positionViewAtIndex(currentIndex, ListView.Center)
    }
    property bool _shown: false
    onCountChanged: if (!_shown && count > 0 && currentIndex >= 0) { _shown = true; Qt.callLater(showCurrent) }

    header: Item {
        width: list.width
        height: Dims.h(28)
        PageHeader {
            text: list.title
        }
    }

    delegate: ListRow {
        id: row
        required property int index
        width: list.width
        height: list.rowHeight
        text: list.textOf(index)
        actionComponent: list.opensMore(index) ? moreMark : (index === list.currentIndex ? tick : null)
        onClicked: list.chosen(index)
    }

    Component {
        id: tick
        Icon {
            name: "ios-checkmark"
            width: height
            color: "#ffffff"
        }
    }
    Component {
        id: moreMark
        Icon {
            name: "ios-arrow-forward"
            width: height
            opacity: 0.7
        }
    }
}
