/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A category header of a stock CP3A Settings list (CategoryHeaderItem, an M3
 * ListSubHeader): titleSmall (14 sp, 28 px, weight 550, 16 sp line) in
 * onSurface #E8E7EE, start-aligned, at the bottom of a box at least 48 dp
 * (96 px) tall; 4.16 % of the width (8 dp, 16 px) at each side, 12 dp
 * (24 px) above (none when it is the first row of the page, under the
 * title), 8 dp (16 px) below (ListSubHeaderTokens.java:6-8,
 * ListHeaderKt.java:130,156, CategoryHeaderItemKt.java:46,55,
 * CustomDimensions.java:26).
 */
Label {
    id: header

    /* the first row of its page (only the page title before it): no space above */
    readonly property bool firstInPage: {
        var p = parent
        if (!p || !p.children)
            return false
        for (var i = 0; i < p.children.length; i++) {
            var c = p.children[i]
            if (c === header)
                return true
            if (c.visible && c.objectName !== "settingsTitle" && c.height > 0)
                return false
        }
        return false
    }

    width: parent ? parent.width : 0
    height: Math.max(Theme.size.listHeader, implicitHeight)
    role: "titleSmall"
    color: Theme.color.onSurface
    leftPadding: Math.round(Theme.margin.subtitleSide)
    rightPadding: leftPadding
    topPadding: firstInPage ? 0 : Theme.space.l
    bottomPadding: Theme.space.m
    verticalAlignment: Text.AlignBottom
    wrapMode: Text.Wrap
    maximumLineCount: 2
    clip: false
    Accessible.role: Accessible.Heading
    EdgeEffect { id: edge; item: header }
    opacity: edge.alpha
    transform: Scale {
        origin.x: header.width / 2
        origin.y: header.height / 2
        xScale: edge.scale
        yScale: edge.scale
    }
}
