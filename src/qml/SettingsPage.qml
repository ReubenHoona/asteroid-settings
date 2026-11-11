/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A stock CP3A Settings screen (ScreenScaffold around a ScalingLazyColumn,
 * ItemLazyColumnKt.java:67,153-166): the title is the first list item, an
 * M3 ListHeader that scrolls with the list, then the rows (SettingsChip,
 * SettingsCategory, SettingsText, SettingsSlider) 4 dp (8 px) apart
 * (ScalingLazyColumnKt.java:166-167). The list keeps 5.2 % of the width
 * at each side, starts 16.64 % down and ends with 36.46 % of the height
 * of room, so its last row can come up to the middle of the circle
 * (CustomDimensions.java:22-24): 20, 64 and 140 px on the 384 px screen.
 * The title: titleMedium (16 sp, 32 px, weight 550) in onBackground #FFFFFF,
 * centred, at most 3 lines with an ellipsis, line height 1.1 em, 12 % of the
 * width (46 px) at each side inside the list, 4 dp (8 px) above, 12 dp
 * (24 px) below, at least 48 dp (96 px) tall (ListHeaderTokens.java:6-8,
 * ListHeaderKt.java:58,84, CustomDimensions.java:25,
 * PaddingDefaultValuesKt.java:156-158,
 * ItemLazyColumnKt$$ExternalSyntheticLambda7.java:37).
 * The crown scrolls it (the controls' RotaryInput takes the Flickable under
 * the middle of the window); the TimeText at the top scrolls away with it
 * (Application).
 *
 *   SettingsPage {
 *       title: qsTrId("id-display-page")
 *       SettingsChip { title: ...; onClicked: ... }
 *   }
 */
Item {
    id: page

    property int depth
    property var pop
    property string title: ""
    default property alias content: column.data
    property alias flickable: flick
    property alias column: column

    Flickable {
        id: flick
        objectName: "settingsFlickable"
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.y + column.height + Math.round(page.height * 0.3646)
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: column
            objectName: "settingsColumn"
            y: Math.round(page.height * 0.1664)
            x: Math.round(page.width * 0.052)
            width: page.width - 2 * x
            spacing: Theme.space.xs

            ListHeader {
                id: titleHeader
                objectName: "settingsTitle"
                visible: page.title !== ""
                text: page.title
                horizontalPadding: Math.round(page.width * 0.12)
                topPadding: Theme.dp(4)
                bottomPadding: Theme.space.l
                // the Settings ListHeader text has a 1.1 em line
                label.lineHeight: label.font.pixelSize * 1.1
                EdgeEffect { id: titleEdge; item: titleHeader }
                opacity: titleEdge.alpha
                transform: Scale {
                    origin.x: titleHeader.width / 2
                    origin.y: titleHeader.height / 2
                    xScale: titleEdge.scale
                    yScale: titleEdge.scale
                }
            }
        }
    }
}
