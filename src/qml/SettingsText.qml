/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * An explanation in a stock CP3A Settings list (CaptionItem / TextItem):
 * plain text under the row it explains, not a button, not selectable.
 * bodySmall (12 sp, 24 px, weight 500, 14 sp line) in onSurfaceVariant
 * #CECDD4, padding 14/6/14/6 dp (28/12/28/12 px) (CaptionItemKt.java:26,
 * TextItemKt.java:60, ButtonDefaults.java:21, TypeScaleTokens.java:122-127).
 */
Label {
    id: text
    width: parent ? parent.width : 0
    role: "bodySmall"
    color: Theme.color.onSurfaceVariant
    leftPadding: Theme.space.xl
    rightPadding: leftPadding
    topPadding: Theme.space.s
    bottomPadding: Theme.space.s
    wrapMode: Text.Wrap
    clip: false
    EdgeEffect { id: edge; item: text }
    opacity: edge.alpha
    transform: Scale {
        origin.x: text.width / 2
        origin.y: text.height / 2
        xScale: edge.scale
        yScale: edge.scale
    }
}
