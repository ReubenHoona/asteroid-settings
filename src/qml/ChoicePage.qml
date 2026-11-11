/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * The stock CP3A Settings selection dialog (SelectionDialogKt.java, the
 * list settings such as Screen timeout): a Wear Material 3 Dialog (the
 * org.asteroid.controls Dialog: opaque black, the springs in and out, the
 * screen behind scaled to 0.85, swipe right to dismiss) holding the title,
 * the optional message and one radio row per option, with no buttons
 * (ChoiceList, dialog: true). A tap marks the row at once, applies it and
 * closes the dialog 300 ms later (SelectionDialogKt$SelectionDialog$1$1.java:90,
 * delay(300L)). apply(index) returning false keeps the dialog open (the
 * caller asks first, e.g. "Change screen timeout", and calls pop() once it
 * is done); the mark goes back to the current option meanwhile.
 *
 *   app.choose(title, options, current, apply, summaries, message)
 */
Dialog {
    id: page
    objectName: "choiceDialog"

    property string title: ""
    property string message: ""
    property var options: []
    property var summaries: []
    property int currentIndex: -1
    property var apply: null
    /* the choice made, closing (300 ms) */
    readonly property bool closing: closeTimer.running
    /* stock: the dialog closes 300 ms after a choice */
    readonly property int closeDelay: 300
    readonly property alias list: list

    z: 1000

    function show(title, options, current, apply, summaries, message) {
        closeTimer.stop()
        page.title = title || ""
        page.message = message || ""
        page.options = options || []
        page.summaries = summaries || []
        page.currentIndex = current
        page.apply = apply || null
        list._shown = false
        list.positionViewAtBeginning()
        open()
        Qt.callLater(list.showCurrent)
        return page
    }
    /* close it (the old page API, kept for the callers that ask first) */
    function pop() {
        closeTimer.stop()
        close()
    }

    onDismissRequested: pop()

    ChoiceList {
        id: list
        anchors.fill: parent
        dialog: true
        title: page.title
        message: page.message
        model: page.options.length
        textOf: function (i) { return page.options[i] }
        summaryOf: function (i) { return page.summaries[i] || "" }
        currentIndex: page.currentIndex
        onChosen: (index) => {
            if (page.closing)
                return
            var before = page.currentIndex
            page.currentIndex = index
            if (page.apply && page.apply(index) === false) {
                page.currentIndex = before
                return
            }
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: page.closeDelay
        onTriggered: page.close()
    }
}
