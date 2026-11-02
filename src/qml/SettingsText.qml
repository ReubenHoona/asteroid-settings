/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * An explanation in a Wear OS settings list (WearTextBoxPreference): plain
 * text under the row it explains, not a chip, not selectable.
 */
Label {
    id: text
    width: parent ? parent.width : 0
    leftPadding: Dims.w(2.3)
    rightPadding: leftPadding
    color: "#c4c7c5"
    wrapMode: Text.Wrap
    clip: false
    font.pixelSize: Dims.l(6.3)
    EdgeEffect { id: edge; item: text }
    opacity: edge.alpha
    transform: Scale {
        origin.x: text.width / 2
        origin.y: text.height / 2
        xScale: edge.scale
        yScale: edge.scale
    }
}
