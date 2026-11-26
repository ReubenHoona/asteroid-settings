/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * An explanation in a Settings list (CaptionItem / TextItem): plain text
 * under the row it explains, not a button, not selectable. As the Wear OS 6
 * emulator draws it (S20-b, S21-b, S23-b; NEWLOOK-61 N61-41): 13 sp (26 px,
 * labelSmall, weight 500, cap about 18 px) on 28 px lines in the caption
 * grey #9AA0A6 (Theme.color.caption), start-aligned with its ink from x 49,
 * the first cap top 12 px under the row above and the next row 14 px
 * under the last baseline (CP3A: bodySmall 12 sp in onSurfaceVariant
 * #CECDD4, padding 14/6/14/6 dp; CaptionItemKt.java:26, TextItemKt.java:60,
 * ButtonDefaults.java:21). 14 dp (28 px) at the sides.
 */
Label {
    id: text
    width: parent ? parent.width : 0
    role: "labelSmall"
    lineHeight: Theme.dp(14)
    color: Theme.color.caption
    leftPadding: Theme.space.xl
    rightPadding: leftPadding
    // Qt puts each baseline the font's ascent under the top of its 28 px
    // line and keeps the font's whole (rounded up) height for the last
    // line: the first cap top 2 dp under the box (12 px under the row above
    // with the list's 4 dp), the box 3 dp under the last baseline (the next
    // row 14 px under it, S20-b: last baseline 313, next row 327)
    topPadding: Theme.dp(2) - (captionMetrics.ascent - capMetrics.tightBoundingRect.height)
    bottomPadding: Theme.dp(3) - (Math.ceil(captionMetrics.height) - captionMetrics.ascent)
    wrapMode: Text.Wrap
    clip: false
    FontMetrics { id: captionMetrics; font: text.font }
    TextMetrics { id: capMetrics; font: text.font; text: "H" }
    // packed with the page's rows (SettingsChip)
    EdgeEffect { id: edge; item: text; packed: true }
    opacity: edge.alpha
    transform: [
        Scale {
            origin.x: text.width / 2
            origin.y: edge.originY
            xScale: edge.scale
            yScale: edge.scale
        },
        Translate { y: edge.translateY }
    ]
}
