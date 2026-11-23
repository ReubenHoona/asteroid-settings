/*
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// A licence text of System licenses as stock CP3A's
// (SystemLicenseDetailsFragment.java:36-44: a list of the header and the
// paragraphs; layout/watch_license_view_header_item.xml,
// license_view_paragraph_item.xml): the part's name as the header, centred,
// textStyleWearTitle3 (titleMedium, 16 sp) in onSurfaceVariant, 12 dp above
// the text; the text in plain paragraphs, left-aligned, outline #A5A5AC,
// 12 sp on 14 sp lines, the list item padding at the sides (x 59 on the
// 384 px screen, as the emulator draws it). No rows and no edge effect: the
// circle cuts the text at the top and the bottom.
SettingsPage {
    id: page
    objectName: "licenseTextPage"

    property string heading: ""
    property string body: ""

    Label {
        objectName: "licenseHeading"
        width: parent.width
        role: "titleMedium"
        color: Theme.color.onSurfaceVariant
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: page.heading
        // 12 dp to the text, the list's own gap included
        bottomPadding: Theme.dp(12) - page.column.spacing
        clip: false
    }
    Label {
        objectName: "licenseText"
        width: parent.width
        role: "bodySmall"
        color: Theme.color.outline
        leftPadding: Math.round(page.width * 0.1536) - page.column.x
        rightPadding: leftPadding
        wrapMode: Text.Wrap
        text: page.body
        clip: false
    }
}
