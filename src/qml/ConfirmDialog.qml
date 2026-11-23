/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * The stock CP3A Settings confirmation (ConfirmationDialog over the
 * Wear Material 3 AlertDialog of org.asteroid.controls): the title in
 * titleLarge (Settings ConfirmationDialogKt$$ExternalSyntheticLambda0.java:42),
 * the text in bodyMedium (:59), centred, then the dismiss (X) and confirm
 * (check) icon buttons side by side; the AlertDialog draws the stock
 * geometry (39 / 20 px padding, the 120 px rounded-square dismiss, the
 * 126 x 108 px confirm pill turned -45 degrees, 24 px above the buttons).
 * tell() has only the confirm action: one edge button with the check, or,
 * with no title, the stock info popup (DialogUtils.showPopup: the message
 * alone in titleMedium and one round check, the AlertDialog "info" style,
 * qml-asteroid e586acf).
 * A swipe to the right is the dismiss (stock onDismissRequest).
 *
 *   confirm.ask(qsTrId("id-power-off"), qsTrId("id-are-you-sure"), powerOff)
 *   confirm.tell("", qsTrId("id-about-legal-text"))
 */
AlertDialog {
    id: dialog

    property string message: ""
    /* only the check: an explanation (About Wi-Fi; no title: the info popup) */
    property bool infoOnly: false
    property var _accept: null
    property var _reject: null

    text: message
    titleRole: "titleLarge"
    buttons: !infoOnly ? "confirmDismiss" : title === "" ? "info" : "edge"
    z: 1100

    function ask(title, message, onAccept, onReject) {
        dialog.title = title || ""
        dialog.message = message || ""
        _accept = onAccept || null
        _reject = onReject || null
        infoOnly = false
        open()
    }
    function tell(title, message, onAccept) {
        ask(title, message, onAccept)
        infoOnly = true
    }
    function accept() {
        var f = _accept
        _accept = null
        _reject = null
        close()
        if (f)
            f()
    }
    function reject() {
        var f = _reject
        _accept = null
        _reject = null
        close()
        if (f)
            f()
    }

    closeOnAction: false
    onConfirmed: accept()
    onDismissed: reject()

    // the names the tests and the screen shots look for
    Component.onCompleted: {
        dialog.titleLabel.objectName = "dialogTitle"
        dialog.textLabel.objectName = "dialogMessage"
        dialog.dismissButton.objectName = "dialogNo"
        _nameConfirm()
    }
    // the confirm action: the check button, the edge button in tell(), or
    // the round check of the info popup
    onButtonsChanged: _nameConfirm()
    function _nameConfirm() {
        dialog.confirmButton.objectName = buttons === "confirmDismiss" ? "dialogYes" : ""
        dialog.edgeButton.objectName = buttons === "edge" ? "dialogYes" : ""
        if (dialog.infoButton)
            dialog.infoButton.objectName = buttons === "info" ? "dialogYes" : ""
    }
}
