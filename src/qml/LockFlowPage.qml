/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.DBus
import "lock.js" as Lock

/*
 * Settings > Security > Screen lock: the set-up flow (FP-S2, CR-06). One page
 * for the three choices of the radio list; it talks to the launcher's lock
 * object, org.asteroidos.launcher.Lock on the session bus, and holds no
 * credential itself (the launcher's root helper keeps the hash):
 *
 *   verify   the credential in force, asked first for every change and for
 *            None (stock ChooseLockGeneric asks the saved one): Verify(secret)
 *   enter    the new PIN (4 digits) or pattern (4 to 9 dots)
 *   confirm  the same again; a mismatch says so and starts the entry over
 *   save     SetPin(old, pin) / SetPattern(old, dots) / Clear(old)
 *
 * The answers are the launcher's result codes: 0 ok, 1 wrong, 2 throttled,
 * 3 no credential set, 4 invalid or not saved. `old` is "" when no credential
 * is in force. The pads are copies of the launcher keyguard's (PinPad.qml,
 * PatternPad.qml, lock.js); the PIN pad only collects digits, this page asks.
 * After too many wrong tries the launcher makes the user wait: the pad is
 * dimmed and the wait counts down (one query a second, only while it lasts
 * and the app is in front; no timer otherwise).
 *
 *   layerStack.push(lockFlowLayer, { "kind": "pin", "oldKind": "pattern",
 *                                    "finished": function (kind) { ... } })
 */
Item {
    id: page
    objectName: "lockFlowPage"

    property int depth
    property var pop
    property string title: ""
    // the clock of the app is off over this page (the pad is drawn full screen, as stock's)
    readonly property bool hideTime: true

    // what is being set: "pin", "pattern" or "none"
    property string kind: "pin"
    // the credential kind in force when the flow started: "none", "pin" or "pattern"
    property string oldKind: "none"
    // called with the new kind once the launcher took it
    property var finished: null

    // "verify", "enter" or "confirm"
    property string step: "verify"
    property string oldSecret: ""
    property string firstEntry: ""
    // a line that replaces the prompt (a mistake) until the next try starts
    property string message: ""
    // true from a question to the launcher until its answer
    property bool busy: false
    // ms of the wait after too many tries (0 = none)
    property real waitMs: 0
    readonly property bool waiting: waitMs > 0
    // the pad that is up: the old credential's kind while it is asked, else the new one's
    readonly property string padKind: step === "verify" ? oldKind : kind
    readonly property alias pinPad: pin
    readonly property alias patternPad: pattern
    readonly property alias promptLabel: prompt
    readonly property real promptHeight: Math.round(height * 0.18)

    //% "Enter your PIN"
    readonly property string enterPinText: qsTrId("id-lock-enter-pin")
    //% "Enter your pattern"
    readonly property string enterPatternText: qsTrId("id-lock-enter-pattern")
    //% "Choose a PIN"
    readonly property string choosePinText: qsTrId("id-lock-choose-pin")
    //% "Draw an unlock pattern"
    readonly property string drawPatternText: qsTrId("id-lock-draw-new-pattern")
    //% "Confirm your PIN"
    readonly property string confirmPinText: qsTrId("id-lock-confirm-pin")
    //% "Draw pattern again to confirm"
    readonly property string confirmPatternText: qsTrId("id-lock-confirm-pattern")
    //% "Wrong PIN"
    readonly property string wrongPinText: qsTrId("id-lock-wrong-pin")
    //% "Wrong pattern"
    readonly property string wrongPatternText: qsTrId("id-lock-wrong-pattern")
    //% "PINs don't match"
    readonly property string pinsDifferText: qsTrId("id-lock-pins-differ")
    //% "Patterns don't match"
    readonly property string patternsDifferText: qsTrId("id-lock-patterns-differ")
    //% "Connect at least 4 dots"
    readonly property string tooShortText: qsTrId("id-lock-too-short")
    //% "Failed to set PIN"
    readonly property string failedPinText: qsTrId("id-lock-failed-pin")
    //% "Failed to set lock pattern."
    readonly property string failedPatternText: qsTrId("id-lock-failed-pattern")
    //% "Failed to turn off screen lock"
    readonly property string failedNoneText: qsTrId("id-lock-failed-none")
    //% "Screen lock is not available"
    readonly property string unavailableText: qsTrId("id-lock-unavailable")
    //% "Try again in %1 sec"
    readonly property string secondsText: qsTrId("id-lock-try-seconds")
    //% "Try again in %1 min %2 sec"
    readonly property string minutesText: qsTrId("id-lock-try-minutes")
    //% "Try again in %1 hr %2 min"
    readonly property string hoursText: qsTrId("id-lock-try-hours")
    //% "Try again in 24 hr"
    readonly property string dayText: qsTrId("id-lock-try-day")

    function two(n) { return (n < 10 ? "0" : "") + n }
    readonly property var waitParts: Lock.waitParts(waitMs)
    readonly property string countdownText: waitParts.kind === "day" ? dayText
        : waitParts.kind === "hours" ? hoursText.arg(waitParts.a).arg(two(waitParts.b))
        : waitParts.kind === "minutes" ? minutesText.arg(waitParts.a).arg(two(waitParts.b))
        : secondsText.arg(waitParts.a)

    readonly property string stepText: {
        if (step === "verify")
            return padKind === "pattern" ? enterPatternText : enterPinText
        if (step === "confirm")
            return padKind === "pattern" ? confirmPatternText : confirmPinText
        return padKind === "pattern" ? drawPatternText : choosePinText
    }
    // what the prompt says: the wait, else a mistake, else the step's question
    readonly property string promptText: waiting ? countdownText : (message !== "" ? message : stepText)
    readonly property bool promptIsError: waiting || message !== ""

    DBusInterface {
        id: lock
        bus: DBus.SessionBus
        service: "org.asteroidos.launcher"
        path: "/org/asteroidos/launcher/lock"
        iface: "org.asteroidos.launcher.Lock"
    }

    function str(s) { return { "type": "s", "value": String(s) } }

    function haptic(name) {
        if (typeof Haptics[name] === "function")
            Haptics[name]()
    }
    function resetPads() {
        pin.reset()
        pattern.reset()
    }
    // a wrong or refused entry: the pad's error and the reject haptic
    function padError() {
        haptic("reject")
        if (padKind === "pattern")
            pattern.showError()
        else
            pin.resetWithError()
    }
    function mistake(text) {
        padError()
        message = text
    }
    function clearMessage() {
        if (message !== "")
            message = ""
    }
    function wrongText() { return padKind === "pattern" ? wrongPatternText : wrongPinText }
    function failedText() {
        return kind === "pattern" ? failedPatternText : (kind === "pin" ? failedPinText : failedNoneText)
    }

    // the wait that remains (the launcher counts it)
    function updateWait() {
        lock.typedCall("Remaining", [], function (r) { page.waitMs = Math.max(0, Number(r)) },
                       function () { page.waitMs = 0 })
    }

    // the launcher did not answer: nothing can be set
    function unreachable(error, text) {
        busy = false
        mistake(unavailableText)
    }

    function finish(newKind) {
        busy = false
        haptic("confirm")
        if (typeof finished === "function")
            finished(newKind)
        if (layerStack.currentLayer === page)
            layerStack.pop(layerStack.currentLayer)
    }

    // a try at a credential from the pad (the 4th digit, the finger lifted)
    function submit(secret) {
        if (busy || waiting)
            return
        if (step === "verify") {
            busy = true
            lock.typedCall("Verify", [str(secret)],
                           function (r) { page.busy = false; page.verified(Number(r), secret) },
                           unreachable)
        } else if (step === "enter") {
            firstEntry = secret
            message = ""
            step = "confirm"
            resetPads()
        } else if (step === "confirm") {
            if (secret !== firstEntry) {
                firstEntry = ""
                step = "enter"
                mistake(kind === "pattern" ? patternsDifferText : pinsDifferText)
            } else {
                save(secret)
            }
        }
    }

    // the answer to Verify of the credential in force
    function verified(r, secret) {
        if (r === 0 || r === 3) {
            // 3: it was removed meanwhile, nothing to confirm
            oldSecret = r === 0 ? secret : ""
            if (r === 3)
                oldKind = "none"
            message = ""
            resetPads()
            if (kind === "none")
                clear()
            else
                step = "enter"
            return
        }
        // 1 wrong, 2 inside a wait, 4 refused: the pad's error; the launcher's wait, if one began
        mistake(wrongText())
        updateWait()
    }

    function save(secret) {
        busy = true
        lock.typedCall(kind === "pin" ? "SetPin" : "SetPattern", [str(oldSecret), str(secret)],
                       function (r) { page.busy = false; page.saved(Number(r), secret) },
                       unreachable)
    }

    function saved(r, secret) {
        if (r === 0) {
            finish(kind)
        } else if (r === 3 && oldSecret !== "") {
            // the credential we confirmed is gone: set the new one with no old one
            oldSecret = ""
            oldKind = "none"
            save(secret)
        } else if (r === 1) {
            // the one in force changed under us: ask for it again
            firstEntry = ""
            oldSecret = ""
            step = oldKind !== "none" ? "verify" : "enter"
            mistake(wrongText())
            updateWait()
        } else if (r === 2) {
            // inside a wait: the confirmation stays, the pad comes back when the wait ends
            padError()
            updateWait()
        } else {
            // 4: invalid or not saved
            firstEntry = ""
            step = "enter"
            mistake(failedText())
        }
    }

    function clear() {
        busy = true
        lock.typedCall("Clear", [str(oldSecret)],
                       function (r) { page.busy = false; page.cleared(Number(r)) },
                       unreachable)
    }

    function cleared(r) {
        if (r === 0 || r === 3) {
            finish("none")
        } else {
            oldSecret = ""
            step = "verify"
            mistake(r === 4 ? failedNoneText : wrongText())
            updateWait()
        }
    }

    Component.onCompleted: {
        if (kind === "none" && oldKind === "none")
            Qt.callLater(function () { page.finish("none") })
        else
            step = oldKind !== "none" ? "verify" : "enter"
        if (oldKind !== "none")
            updateWait()
    }

    // the wait is over: the mistake that came with it goes
    onWaitingChanged: if (!waiting) message = ""

    // one query a second while a wait lasts and the app is in front; the app waking up asks once
    Timer {
        interval: 1000
        repeat: true
        running: page.waiting && page.visible && Qt.application.state === Qt.ApplicationActive
        onTriggered: page.updateWait()
    }
    Connections {
        target: Qt.application
        function onStateChanged() {
            if (page.waiting && Qt.application.state === Qt.ApplicationActive)
                page.updateWait()
        }
    }

    // the question (or the mistake) above the pad
    Label {
        id: prompt
        objectName: "lockPrompt"
        role: "bodySmall"
        x: Math.round((page.width - width) / 2)
        y: Math.round(page.height * 0.055)
        width: Math.round(page.width * 0.52)
        height: page.promptHeight - y - Theme.dp(1)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        fontSizeMode: Text.Fit
        minimumPixelSize: Theme.sp(7)
        text: page.promptText
        color: page.promptIsError ? Theme.color.errorDim : Theme.color.onSurface
    }

    PinPad {
        id: pin
        y: page.promptHeight
        width: page.width
        height: page.height - page.promptHeight
        visible: page.padKind !== "pattern"
        inputEnabled: !page.waiting && !page.busy
        onSubmitted: (secret) => page.submit(secret)
        onEntryChanged: if (entry.length > 0) page.clearMessage()
    }
    PatternPad {
        id: pattern
        y: page.promptHeight
        width: page.width
        height: page.height - page.promptHeight
        visible: page.padKind === "pattern"
        inputEnabled: !page.waiting && !page.busy
        onCompleted: (dots) => page.submit(dots)
        onTooShort: page.mistakeShown(page.tooShortText)
        onDotsChanged: if (dots.length > 0) page.clearMessage()
    }

    // too few dots: the pad shows its own error, no try was made
    function mistakeShown(text) {
        haptic("reject")
        message = text
    }
}
