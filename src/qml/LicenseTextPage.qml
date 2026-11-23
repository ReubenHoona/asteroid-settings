/*
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// A licence text of System licenses as stock CP3A's
// (SystemLicenseDetailsFragment.java:36-44: a list of the header and the
// paragraphs; layout/watch_license_view_header_item.xml,
// license_view_paragraph_item.xml): the part's name as the header, centred,
// in onSurfaceVariant, 12 dp above the text; the text in plain paragraphs,
// left-aligned, outline #A5A5AC, 12 sp on 14 sp lines, the list item padding
// at the sides (x 59 on the 384 px screen, as the emulator draws it). No
// rows and no edge effect: the circle cuts the text at the top and the
// bottom.
//
// The header's TextView sets android:textAppearance="?android:attr/
// textAppearanceMedium" itself, and that wins over the text appearance of
// its style textStyleWearTitle3: on the watch TextAppearance.DeviceDefault
// .Medium -> TextAppearance.Material.Medium (framework values/styles.xml
// 7469, 3622-3624, 4027-4030), text_size_medium_material 14 sp
// (values-watch/dimens.xml:53; the watch is 192 dp wide, under the w210dp
// 16 sp), textColorSecondary, sans-serif-medium, no tracking: titleSmall
// (28 px, weight 500) with no tracking here. The rest of Title3 still
// applies (Widget.TextView.WearMaterial.Title3, values/styles.xml:8374-8380,
// Flex title_medium, dimens.xml:971,1009,1047): includeFontPadding false,
// 18 sp lines, the first baseline at least 14 sp under the top, the last at
// least 4 sp over the bottom (the stock font's ascent and descent are
// smaller, so those win). The emulator (S35-c) draws the header's baseline
// at y 94 and the text's first baseline at y 152 (caps from 134): the
// header's box 66-102, 12 dp, then the paragraph from y 126, a plain
// TextView (includeFontPadding) with its first baseline 26 px under its
// top. The stock list starts 2 px lower than this column (64).
SettingsPage {
    id: page
    objectName: "licenseTextPage"

    property string heading: ""
    property string body: ""

    readonly property real _sp: Theme.density * Theme.fontScale
    // what Qt lays out under a text's last baseline: its last line keeps
    // the font's whole (rounded up) height
    function _lastDescent(t, m) {
        return t.contentHeight - (t.lineCount - 1) * t.lineHeight - m.ascent
    }
    FontMetrics { id: headMetrics; font: headingLabel.font }
    FontMetrics { id: textMetrics; font: licenseText.font }

    Label {
        id: headingLabel
        objectName: "licenseHeading"
        width: parent.width
        role: "titleSmall"
        color: Theme.color.onSurfaceVariant
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: page.heading
        // Title3's 18 sp lines, the first baseline 14 sp under the box
        // (1 dp lower: where the stock list starts), the last 4 sp over it,
        // then 12 dp to the text, the list's own gap included
        lineHeight: 18 * page._sp
        topPadding: Theme.dp(1) + 14 * page._sp - headMetrics.ascent
        bottomPadding: 4 * page._sp - page._lastDescent(headingLabel, headMetrics)
                       + Theme.dp(12) - page.column.spacing
        clip: false
        // no tracking (TextAppearance.Material sets none; titleSmall's is 0.4 sp)
        Component.onCompleted: font.letterSpacing = 0
    }
    Label {
        id: licenseText
        objectName: "licenseText"
        width: parent.width
        role: "bodySmall"
        color: Theme.color.outline
        leftPadding: Math.round(page.width * 0.1536) - page.column.x
        rightPadding: leftPadding
        // the paragraph's first baseline 13 sp (26 px) under its top
        topPadding: 13 * page._sp - textMetrics.ascent
        wrapMode: Text.Wrap
        text: page.body
        clip: false
    }
}
