/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A Wear OS settings screen (Wear Material's preference list): the title as
 * the first row, scrolling with the list, then the rows (SettingsChip,
 * SettingsCategory, SettingsText, SettingsSlider) 8 dp apart. The list
 * starts 16.8 % down, keeps 5.2 % off each side and ends with 35.6 % of
 * room, so its last row can come up to the middle of the circle. The crown
 * scrolls it (the controls' RotaryInput takes the Flickable under the
 * middle of the window).
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
        contentHeight: column.y + column.height + Math.round(page.height * 0.356)
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.DragOverBounds

        Column {
            id: column
            objectName: "settingsColumn"
            y: Math.round(page.height * 0.168)
            x: Math.round(page.width * 0.052)
            width: page.width - 2 * x
            spacing: Dims.h(4)

            Label {
                id: titleLabel
                objectName: "settingsTitle"
                visible: page.title !== ""
                width: parent.width
                leftPadding: Math.round(page.width * 0.023)
                rightPadding: leftPadding
                bottomPadding: Dims.h(1)
                text: page.title
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                clip: false
                font.pixelSize: Dims.l(7.8)
                font.styleName: "SemiCondensed Medium"
                EdgeEffect { id: titleEdge; item: titleLabel }
                opacity: titleEdge.alpha
                transform: Scale {
                    origin.x: titleLabel.width / 2
                    origin.y: titleLabel.height / 2
                    xScale: titleEdge.scale
                    yScale: titleEdge.scale
                }
            }
        }
    }
}
