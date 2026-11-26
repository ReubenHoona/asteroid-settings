/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A list of choices, one radio row each (stock RadioButtonItem rows,
 * SettingsChip control "radio"), under a title and an optional message.
 * Two layouts:
 * - a page (dialog: false; Language, System licenses): the Settings list
 *   padding (5.2 % of the width at each side, 36.46 % of room at the end)
 *   and the title as SettingsPage's: labelMedium (15 sp) in onSurface on a
 *   1.1 em line, its box from 12.5 % of the height down to the first row,
 *   so its cap top is at y 69 and the first row at y 123 (the Wear OS 6
 *   emulator's System licenses list, S35-b; NEWLOOK-61 N61-40);
 * - the selection dialog (dialog: true; ChoicePage, SelectionDialogKt.java):
 *   an M3 AlertDialog with no buttons: padding ceil(5.2 %) of the width at
 *   the sides (20 px), ceil(10 %) of the height at the top (39 px) and
 *   36.46 % at the bottom (140 px) (scrollContentHorizontalPadding,
 *   dialogScrollContentLargeTopPadding, scrollContentBottomPadding); the title
 *   in titleMedium (32 px, weight 550) centred, 12 % of the width (46 px)
 *   from the screen edges, at most 3 lines; the message in bodyMedium (28 px,
 *   weight 450) centred, 4.16 % of the width (16 px) inside the list, 4 dp
 *   (8 px) more above it (SelectionDialogKt$$ExternalSyntheticLambda0.java:42,53,
 *   AlertDialogDefaults).
 * Rows are 4 dp (8 px) apart (ScalingLazyColumnKt.java:166-167).
 */
ListView {
    id: list
    objectName: "choiceList"

    property string title: ""
    /* stock's optional message under the title ("" for none) */
    property string message: ""
    /* the selection dialog layout (else a Settings page) */
    property bool dialog: false
    /* text of row i */
    property var textOf: function (i) { return "" }
    /* second line of row i ("" for none) */
    property var summaryOf: function (i) { return "" }
    /* row i leads to more choices (no radio mark) */
    property var opensMore: function (i) { return false }
    signal chosen(int index)

    /* the side padding of the rows */
    readonly property real sidePadding: dialog ? Math.ceil(width * 0.052) : Math.round(width * 0.052)
    /* the gap between rows: 4 dp */
    readonly property real rowSpacing: Theme.space.xs
    /* the pitch of the rows: a stock row (52 dp, 104 px) and the gap under
       it; a row with a longer text grows */
    readonly property real rowHeight: Theme.size.button + rowSpacing

    clip: false
    boundsBehavior: Flickable.StopAtBounds
    highlightFollowsCurrentItem: false
    topMargin: 0
    // the last rows can come to the middle of the circle
    bottomMargin: Math.round(height * 0.3646)

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
        id: headerBox
        width: list.width
        readonly property real topGap: list.dialog ? Math.ceil(list.height * 0.10) : Math.round(list.height * 0.125)
        // a page's title box reaches the first row (as SettingsPage's)
        height: topGap + titleBox.height + (messageLabel.visible ? messageLabel.height : 0)
                + (list.dialog || messageLabel.visible ? list.rowSpacing : 0)

        Item {
            id: titleBox
            y: headerBox.topGap
            x: list.sidePadding
            width: list.width - 2 * x
            // a page: 7 dp above the title, 12 dp under it, whole pixels
            height: list.dialog ? titleLabel.height
                                : Math.round(titleLabel.height + Theme.dp(7) + Theme.space.l)
            Label {
                id: titleLabel
                objectName: "choiceTitle"
                // a dialog title is 12 % of the width from the screen edge,
                // a list header 12 % inside the list
                x: list.dialog ? Math.round(list.width * 0.12) - list.sidePadding : Math.round(list.width * 0.12)
                y: list.dialog ? 0 : Theme.dp(7)
                width: titleBox.width - 2 * x
                text: list.title
                role: list.dialog ? "titleMedium" : "labelMedium"
                lineHeight: list.dialog ? Theme.type.titleMedium.lineHeight : font.pixelSize * 1.1
                color: list.dialog ? Theme.color.onBackground : Theme.color.onSurface
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                clip: false
            }
            // a page's title rests whole while the list is at its top, as
            // SettingsPage's (restAtTop: #E8E7EE exactly, the emulator's)
            EdgeEffect { id: titleEdge; item: titleBox; restAtTop: !list.dialog }
            opacity: titleEdge.alpha
        }
        Label {
            id: messageLabel
            objectName: "choiceMessage"
            visible: list.message !== ""
            anchors.top: titleBox.bottom
            x: list.sidePadding + Math.round(list.width * 0.0416)
            width: list.width - 2 * x
            topPadding: list.rowSpacing + Theme.dp(4)
            text: list.message
            role: "bodyMedium"
            color: Theme.color.onBackground
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            clip: false
            EdgeEffect { id: messageEdge; item: messageLabel }
            opacity: messageEdge.alpha
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
        height: chip.height + list.rowSpacing

        SettingsChip {
            id: chip
            x: list.sidePadding
            width: list.width - 2 * x
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
