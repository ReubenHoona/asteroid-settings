/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A choice as the stock Wear OS settings offer it (WearListPreference): the
 * title as the first row, scrolling with the list, then one radio chip per
 * choice, the current one marked; a tap on a chip chooses it (chosen). A
 * row that opens more choices (a region of time zones) has no mark. The
 * chips shrink and fade at the edges of the round screen; the crown
 * scrolls the list.
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
    objectName: "choiceList"

    property string title: ""
    /* text of row i */
    property var textOf: function (i) { return "" }
    /* second line of row i ("" for none) */
    property var summaryOf: function (i) { return "" }
    /* row i leads to more choices (no radio mark) */
    property var opensMore: function (i) { return false }
    signal chosen(int index)

    /* the pitch of the rows: a stock chip (52 dp, 104 px) and the gap under
       it; a chip with a longer text grows */
    property real rowHeight: Dims.h(30)

    clip: false
    boundsBehavior: Flickable.StopAtBounds
    highlightFollowsCurrentItem: false
    // the last rows can come to the middle of the circle
    topMargin: 0
    bottomMargin: Math.round(height * 0.3)

    // the list opens at its title; when the current choice would be below
    // the screen, it comes to the middle instead
    function showCurrent() {
        if (currentIndex < 0)
            return
        var header = headerItem ? headerItem.height : 0
        if (header + currentIndex * rowHeight > height * 0.7)
            positionViewAtIndex(currentIndex, ListView.Center)
    }
    property bool _shown: false
    onCountChanged: if (!_shown && count > 0 && currentIndex >= 0) { _shown = true; Qt.callLater(showCurrent) }

    header: Item {
        width: list.width
        height: titleLabel.y + titleLabel.height + Dims.h(3)
        Label {
            id: titleLabel
            objectName: "choiceTitle"
            y: Math.round(list.height * 0.168)
            x: Math.round(list.width * 0.075)
            width: list.width - 2 * x
            text: list.title
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            clip: false
            font.pixelSize: Dims.l(7.8)
            font.styleName: "SemiCondensed Medium"
            EdgeEffect { id: titleEdge; item: titleLabel }
            opacity: titleEdge.alpha
        }
    }

    delegate: Item {
        id: row
        required property int index
        readonly property bool current: index === list.currentIndex
        readonly property bool more: list.opensMore(index)
        // what the row shows at its end: the radio mark, or nothing on a
        // row that opens more choices
        readonly property var actionComponent: more ? moreMark : (current ? tick : null)
        width: list.width
        height: Math.max(list.rowHeight, chip.height + Dims.h(3))

        SettingsChip {
            id: chip
            x: Math.round(list.width * 0.052)
            width: list.width - 2 * x
            minHeight: list.rowHeight - Dims.h(3)
            title: list.textOf(row.index)
            summary: list.summaryOf(row.index)
            control: row.more ? "none" : "radio"
            checked: row.current
            onClicked: list.chosen(row.index)
        }
    }

    // markers of the row's state, for whoever looks at actionComponent
    Component { id: tick; Item {} }
    Component { id: moreMark; Item {} }
}
