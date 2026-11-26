/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import "whatsnew.js" as WhatsNew

// Settings > General > What's new (setup-wizard-15, CR-42): the pages of the
// last update's notes again, as stock's Pixel Tips > What's new runs the
// what's-new pages again (sysui jbm.java:56-62, settings_show_whats_new_
// tutorial; the pages mnw.java: a headline, the text, Next 52 dp, Back,
// Done on the last). The notes are eos-update's
// /org/asteroidos/eos-update/whatsnew-notes, pages split at "|", each
// "Headline: text" (whatsnew.js). One page at a time in the Settings page
// frame: its headline is the title (What's new when it has none), the text
// under it, then Next (Done on the last page, which closes the page) and
// Back from the second page on. Showing them here does not touch
// whatsnew-pending (the launcher's splash clears it).
SettingsPage {
    id: page
    objectName: "whatsNewPage"
    title: page.current.headline !== "" ? page.current.headline : qsTrId("id-whats-new")

    ConfigurationValue {
        id: notes
        key: "/org/asteroidos/eos-update/whatsnew-notes"
        defaultValue: ""
    }

    readonly property var pages: WhatsNew.pages(notes.value)
    property int index: 0
    readonly property int shown: Math.max(0, Math.min(index, pages.length - 1))
    readonly property var current: pages.length > 0 ? pages[shown] : ({ "headline": "", "text": "" })
    readonly property bool last: shown >= pages.length - 1

    // each page starts at its top
    onShownChanged: page.flickable.contentY = 0

    Label {
        objectName: "whatsNewText"
        width: parent.width
        leftPadding: Theme.space.xl
        rightPadding: leftPadding
        bottomPadding: Theme.space.l
        role: "bodyMedium"
        color: Theme.color.onSurface
        wrapMode: Text.Wrap
        text: page.current.text
        visible: text !== ""
    }
    Button {
        objectName: "whatsNewNext"
        width: parent.width
        centered: true
        //% "Done"
        text: page.last ? qsTrId("id-whats-new-done")
                        //% "Next"
                        : qsTrId("id-whats-new-next")
        onClicked: {
            if (page.last)
                layerStack.pop(layerStack.currentLayer)
            else
                page.index = page.shown + 1
        }
    }
    Button {
        objectName: "whatsNewBack"
        width: parent.width
        visible: page.shown > 0
        variant: "tonal"
        centered: true
        //% "Back"
        text: qsTrId("id-whats-new-back")
        onClicked: page.index = page.shown - 1
    }
}
