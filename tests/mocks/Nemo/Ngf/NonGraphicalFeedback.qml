// Copyright (C) 2026 eos-mainline contributors
// SPDX-License-Identifier: BSD-3-Clause
// Test double for the Settings tests: Nemo.Ngf's NonGraphicalFeedback (the
// ngfd client). Every play and stop is recorded in Backend.calls as
// ("ngf", "play"|"stop", [event]); a sample plays for Backend.sampleMs, then
// the status goes back to Stopped, as ngfd's would when the sound ends.
import QtQuick
import SettingsTest

QtObject {
    id: fb
    enum EventStatus { Stopped, Failed, Playing, Paused }
    property string event
    property int status: NonGraphicalFeedback.Stopped
    readonly property bool connected: true
    function play() {
        Backend.record("ngf", "play", [event])
        status = NonGraphicalFeedback.Playing
        end.interval = Backend.sampleMs
        end.restart()
    }
    function stop() {
        Backend.record("ngf", "stop", [event])
        end.stop()
        status = NonGraphicalFeedback.Stopped
    }
    property Timer _end: Timer {
        id: end
        onTriggered: fb.status = NonGraphicalFeedback.Stopped
    }
}
