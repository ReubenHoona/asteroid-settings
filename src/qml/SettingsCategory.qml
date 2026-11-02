/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A category header of a Wear OS settings list (wear_preference_category):
 * a small caption over the rows it heads, 12 dp above it, no chip.
 */
Label {
    id: header
    width: parent ? parent.width : 0
    leftPadding: Dims.w(2.3)
    rightPadding: leftPadding
    topPadding: Dims.h(3)
    color: "#c4c7c5"
    wrapMode: Text.Wrap
    maximumLineCount: 2
    clip: false
    font.pixelSize: Dims.l(6.3)
    font.styleName: "SemiCondensed Medium"
    EdgeEffect { id: edge; item: header }
    opacity: edge.alpha
    transform: Scale {
        origin.x: header.width / 2
        origin.y: header.height / 2
        xScale: edge.scale
        yScale: edge.scale
    }
}
