/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A stock Settings screen (ScreenScaffold around a ScalingLazyColumn,
 * ItemLazyColumnKt.java:67,153-166): the title is the first list item, a
 * ListHeader that scrolls with the list, then the rows (SettingsChip,
 * SettingsCategory, SettingsText, SettingsSlider) 4 dp (8 px) apart
 * (ScalingLazyColumnKt.java:166-167). The list keeps 5.2 % of the width
 * at each side and ends with 36.46 % of the height of room, so its last
 * row can come up to the middle of the circle (CustomDimensions.java:22-24):
 * 20 and 140 px on the 384 px screen. The top is the Wear OS 6 emulator's
 * (the user's choice of its look over CP3A's, NEWLOOK-61 N61-40): the title
 * box from 12.5 % (48 px) down to the first row, the title's cap top at
 * y 69 and the first row at y 123 on every page with a title (S16-S23);
 * with no title the first row at y 84 (S24). The title: labelMedium
 * (15 sp, 30 px, weight 500) in onSurface #E8E7EE, centred, at most 3
 * lines with an ellipsis, line height 1.1 em, 12 % of the width (46 px) at
 * each side inside the list, 7 dp (14 px) above, 12 dp (24 px) below, no
 * least height (CP3A: titleMedium 16 sp in onBackground, 16.64 % down, at
 * least 48 dp; ListHeaderTokens.java:6-8, ListHeaderKt.java:58,84,
 * CustomDimensions.java:25, PaddingDefaultValuesKt.java:156-158,
 * ItemLazyColumnKt$$ExternalSyntheticLambda7.java:37).
 * Near the top and bottom of the screen the title and the rows shrink and
 * fade together, each about its edge nearest the middle, packed 8 px apart
 * (EdgeEffect packed, as the Wear OS 6 emulator, S16-S22).
 * A page that is a legacy preference screen in stock (About, Versions) sets
 * legacyHeader: its title is drawn as that screen draws it (legacyTitle).
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
    /* the title of a stock legacy preference screen (legacyTitle) instead
       of the M3 ListHeader */
    property bool legacyHeader: false
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

        // The title, as the Wear OS 6 emulator draws it on every Settings
        // page with one (S16-S23, S35-b): labelMedium (15 sp, 30 px, weight
        // 500) in onSurface #E8E7EE, centred, its cap top at y 69, the first
        // row at y 123; 'Connectivity' 183 px wide. Its box, 12.5 % down,
        // reaches the first row (no list spacing under it), so at rest it
        // sits where the edge effect leaves it almost whole (0.99), as the
        // emulator's title; scrolled, it shrinks and fades packed with the
        // rows (the ListHeader's own packed EdgeEffect).
        ListHeader {
            id: titleHeader
            objectName: page.legacyHeader ? "" : "settingsTitle"
            visible: page.title !== "" && !page.legacyHeader
            text: page.title
            x: column.x
            y: Math.round(page.height * 0.125)
            width: column.width
            // whole pixels, so the rows under it do not sit between pixels
            height: Math.round(implicitHeight)
            horizontalPadding: Math.round(page.width * 0.12)
            topPadding: Theme.dp(7)
            bottomPadding: Theme.space.l
            minimumHeight: 0
            color: Theme.color.onSurface
            label.role: "labelMedium"
            // the Settings ListHeader text has a 1.1 em line
            label.lineHeight: label.font.pixelSize * 1.1
        }

        Column {
            id: column
            objectName: "settingsColumn"
            // under the title; with no title the first row at y 84 (the
            // emulator's Brightness, S24); a legacy screen at 16.64 %
            // (wear_preference_fragment_top_padding_percent)
            y: page.legacyHeader ? Math.round(page.height * 0.1664)
               : titleHeader.visible ? titleHeader.y + titleHeader.height
               : Math.round(page.height * 0.21875)
            x: Math.round(page.width * 0.052)
            width: page.width - 2 * x
            spacing: Theme.space.xs

            // The title of the legacy preference screens (stock About and
            // Versions, DeviceInfoFragment and DeviceVersionFragment, are
            // WearPreferenceFragments: WearPreferenceScreenTitleAdapter,
            // layout/wear_title_preference.xml): textStyleWearButton1 of the
            // Flex theme, label_medium (15 sp on 18 sp lines, the first
            // baseline 14 sp under its top, the last 4 sp over its bottom,
            // includeFontPadding false; settings values/styles.xml:8296-8302,
            // 1954-2074, dimens.xml:962,1000,1038,1076), in colorOnSurface
            // (Base.V33.PreferenceThemeOverlay.WearMaterial
            // preferenceTitleTextColor), centred, at most 3 lines, 16.64 %
            // of the width from the screen edges (values-round
            // wear_preference_title_horizontal_padding_percent), at the list
            // top (wear_preference_fragment_top_padding_percent 0.1664). It
            // never shrinks or fades at the top (FadingWearableRecyclerView
            // shouldFadeFromTop: not for the first item). The column's 4 dp
            // follow it: with the data rows' own top padding the first row's
            // cap comes 61 px under the title's, where the emulator draws
            // them (S22-b: title cap y 68, first row cap y 129).
            // created only on the legacy pages: its bottom padding reads its own
            // layout, which on every other page only cost time and logged binding loops
            Loader {
                id: legacyLoader
                active: page.legacyHeader
                visible: active && page.title !== ""
                width: column.width
                sourceComponent: Component {
                    Label {
                        id: legacyTitle
                        objectName: page.legacyHeader ? "settingsTitle" : ""
                        visible: page.legacyHeader && page.title !== ""
                        width: legacyLoader.width
                        leftPadding: Math.round(page.width * 0.1664) - column.x
                        rightPadding: leftPadding
                        role: "labelMedium"
                        color: Theme.color.onSurface
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        clip: false
                        text: page.title
                        Accessible.role: Accessible.Heading
                        Accessible.name: text
                        readonly property real _sp: Theme.density * Theme.fontScale
                        // the first baseline 14 sp under the top; Qt lays out the
                        // font's whole (rounded up) height under the last baseline,
                        // so the bottom padding takes that off 4 sp
                        topPadding: 14 * _sp - legacyMetrics.ascent
                        bottomPadding: 4 * _sp - (contentHeight - (lineCount - 1) * lineHeight - legacyMetrics.ascent)
                        FontMetrics { id: legacyMetrics; font: legacyTitle.font }
                    }
                }
            }
        }
    }
}
