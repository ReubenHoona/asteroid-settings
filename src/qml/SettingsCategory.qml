/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A category header of a Settings list (CategoryHeaderItem), the
 * org.asteroid.controls ListSubHeader as the Wear OS 6 emulator draws it
 * ('Ring volume', 'Notification volume', S21 / S21-d; NEWLOOK-61 N61-41):
 * labelSmall (13 sp, 26 px, Medium) in onSurface #E8E7EE, start-aligned,
 * the ink of a stem letter at x 52 (16 dp inside the list's 5.2 %), no
 * least height; its cap top 38 px under the row above and the next row
 * 22 px under its baseline (the list's 4 dp spacing included). The first
 * row of its page (only the title before it) has no space above (CP3A:
 * titleSmall 14 sp at x 36 in a box at least 48 dp tall, 12 dp above and
 * 8 dp below; ListSubHeaderTokens.java:6-8, CategoryHeaderItemKt.java:46,55).
 */
ListSubHeader {
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

    first: firstInPage
}
