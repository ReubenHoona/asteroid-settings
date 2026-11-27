/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * The Settings confirmation (ConfirmationDialog over the AlertDialog of
 * org.asteroid.controls) as the Wear OS 6 emulator draws it (System >
 * Restart, S25; NEWLOOK-61 N61-11): black, no card, the title in
 * titleMedium (32 px, cap 23 px; CP3A asked for titleLarge,
 * ConfirmationDialogKt$$ExternalSyntheticLambda0.java:42) and the text in
 * bodyMedium (:59), both onSurface #E8E7EE and centred, their cap tops at
 * y 103 and 164; then two 104 px circles 24 px apart at y 257-360: the
 * dismiss (X) in surfaceContainer #2F3036 at x 76-179 and the confirm
 * (check) in primary #DBE2F9 at x 204-307 (the AlertDialog's
 * "confirmDismiss" geometry, qml-asteroid newlook-61 N61-11; CP3A drew a
 * 120 px rounded square and a 126 x 108 px pill turned -45 degrees).
 * The dialog fades in while its content rises; the screen behind is not
 * scaled (qml-asteroid N61-12).
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
    // the emulator's titleMedium (the AlertDialog's own default)
    titleRole: "titleMedium"
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
