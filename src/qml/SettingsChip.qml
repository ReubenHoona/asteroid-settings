/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * A stock Settings row, on the Wear Material 3 Button of
 * org.asteroid.controls (px on the 384 px Pixel Watch 2, 2 px per dp); the
 * colours, the switch and the disabled look are the Wear OS 6 emulator's
 * (the user's choice of its look over CP3A's, NEWLOOK-61 N61-38):
 * - a navigation row is a FilledTonalButton (ButtonItemKt.java:110,133):
 *   container surfaceContainer #2F3036, label labelMedium (30 px) in
 *   onSurface #E8E7EE, second line labelSmall (26 px) in primary #DBE2F9
 *   ('After 1 minute', S18-b; CP3A onSurfaceVariant #CECDD4), icon in
 *   primary #DBE2F9, padding 14/6/14/6 dp (28/12 px), at
 *   least 52 dp (104 px) tall (FilledButtonTokens.java:7,31-38,
 *   ButtonDefaults.java:21-33); the icon is the list icon of
 *   settings_list_icon_size 24 dp (48 px, the size its vector declares) in
 *   the 26 dp slot of ButtonDefaults.IconSize (IconProvider.java:249-271),
 *   so the text stays 26 + 6 dp (64 px) after the slot's start;
 * - control "toggle" is the controls' SwitchButton row as the emulator
 *   draws it (S18-b, S20, S21, S23, S24): padding 14/8/14/8 dp (16 px above
 *   and below), the small switch (24 x 10 dp track, 14 dp thumb, its track
 *   translucent over the row) in a 24 dp (48 px) slot 6 dp (12 px) after the
 *   text and 14 dp (28 px) from the end (x 288-335 on a full-width row);
 *   checked: the container stays surfaceContainer with the checked gradient
 *   over it (primary from 0 to 32.5 %: #35363D at x 30, #646772 at x 355),
 *   the label stays onSurface and the second line primary; the gradient
 *   comes in on the slow effects spring (stiffness 260, about 412 ms), the
 *   switch on the fast effects spring (1400, about 177 ms); disabled and
 *   checked, the gradient at 38 % (as SwitchButton);
 * - control "radio" is a RadioButton row (RadioButtonTokens.java:53-64; no
 *   emulator capture, CP3A's look): the radio in a 32 x 24 dp (64 x 48 px)
 *   slot; checked: container primaryContainer #404759, text
 *   onPrimaryContainer #D9E0F7, second line at 90 %, the colours on the
 *   slow effects spring and the dot on the fast one;
 * - a tap plays TOGGLE_ON / TOGGLE_OFF or CONTEXT_CLICK, which Touch
 *   feedback governs (SwitchButtonKt$$ExternalSyntheticLambda0.java:18,
 *   RadioButtonKt$$ExternalSyntheticLambda0.java:17);
 * - disabled (active: false): the container stays surfaceContainer, the
 *   label, second line and icon #80868B (Theme.color.disabledContentFlat;
 *   S23-b 'Set time / 6:58 PM' on #2F3036), the same size; a radio or
 *   select row keeps CP3A's onSurface 12 % container and 38 % content
 *   (FilledButtonTokens.java:26-28);
 * - an information row (clickable: false) is a Button with a transparent
 *   container, 16 dp (32 px) corners, content onSurface, icon onSurface at
 *   38 % (InfoChipItemKt.java:55-69);
 * - a data row (dataRow: true) is the plain two-line row of the legacy
 *   About and Versions pages (SettingsDataPreference.java:37-62,
 *   layout/settings_data_preference.xml): no container, 8 dp (16 px) above
 *   and below, two TextViews in textStyleWearBody4, the title on one line,
 *   the value under it on at most 4. The Settings theme is the Flex one
 *   (Theme.Settings.WearMaterial -> Base.WearMaterialTheme.Flex), so Body4
 *   is body_medium: 14 sp (28 px), weight 450, 16 sp lines, the first
 *   baseline at least 12 sp under the top of each text, the last at least
 *   4 sp over its bottom (TextView.setFirstBaselineToTopHeight and
 *   setLastBaselineToBottomHeight pad only past the font's own ascent and
 *   descent, and the stock font's ascent wins: 13 sp, 26 px); both
 *   onSurface #E8E7EE. One line each: 34 px from baseline to baseline,
 *   100 px tall, 108 px apart in the list (the emulator's About, S22-b;
 *   D60-40);
 * - control "select" is a checkable row with no control drawn (the
 *   checkable WearChipButton of the Color theme page,
 *   SystemThemePreference.java:28-49): checked primaryContainer with
 *   onPrimaryContainer text, as a checked SwitchButton row;
 * - the label takes at most 5 lines with no second line and no control,
 *   else 3; the second line at most 2
 *   (ButtonItemKt$$ExternalSyntheticLambda0.java:87,100,
 *   RadioButtonItemKt$$ExternalSyntheticLambda3.java:85).
 * Near the top and bottom of the round screen it shrinks and fades as it
 * scrolls (EdgeEffect, the ScalingLazyColumn 0.7 and 0.5), packed with the
 * page's other rows as the Wear OS 6 emulator draws them (S16-S22): it
 * shrinks about its edge nearest the middle of the screen and the rows
 * further out close up, so the 8 px gaps stay and the text keeps clear of
 * the bezel (a row bottom at y 74 at 0.85 / 0.75, a row top at y 347 at
 * 0.75 / 0.58; EdgeEffect packed).
 *
 *   SettingsChip {
 *       iconName: "ios-sunny-outline"
 *       title: qsTrId("id-brightness")
 *       summary: "Normal"
 *       onClicked: layerStack.push(brightnessLayer)
 *   }
 */
Item {
    id: chip

    property string title: ""
    property string summary: ""
    property string iconName: ""
    /* "none", "toggle", "radio" or "select" */
    property string control: "none"
    property bool checked: false
    /* false: greyed out, taps do nothing (stock: a mode holds it, e.g. Theater mode) */
    property bool active: true
    /* false: an information row, not a button */
    property bool clickable: true
    /* the legacy About and Versions row (SettingsDataPreference): plain text */
    property bool dataRow: false
    property alias edgeEffect: edge.enabled
    /* the row grows from this height with its text: 52 dp (a data row: its text) */
    property real minHeight: dataRow ? 0 : Theme.size.button
    readonly property bool pressed: button.pressed
    /* more room before the text, for something drawn there (the Color
       theme swatches); 0: the text where the Button puts it */
    property real textInset: 0
    /* the alpha of the row's content near the screen edge (EdgeEffect), for
       what a page draws on the row */
    readonly property real contentAlpha: button.opacity
    /* the Button inside (tests, and rows that need more) */
    readonly property alias button: button
    readonly property bool selectable: control === "toggle" || control === "radio" || control === "select"
    readonly property bool _on: selectable && checked

    signal clicked()

    function _a(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    /* a radio or select row: CP3A's checked container and disabled look */
    readonly property bool _checkRow: control === "radio" || control === "select"
    readonly property color _cp3aDisabled: _a(Theme.color.onSurface, Theme.alpha.disabledContent)
    /* the stock colours of the row in its state */
    readonly property color containerColor: !clickable || dataRow ? "transparent"
        : !_checkRow ? Theme.color.surfaceContainer
        : !active ? _a(Theme.color.onSurface, Theme.alpha.disabledContainer)
        : _on ? Theme.color.primaryContainer : Theme.color.surfaceContainer
    readonly property color titleColor: !active ? (_checkRow ? _cp3aDisabled : Theme.color.disabledContentFlat)
        : _on && _checkRow ? Theme.color.onPrimaryContainer : Theme.color.onSurface
    readonly property color summaryColor: dataRow || !active ? titleColor
        : _on && _checkRow ? _a(Theme.color.onPrimaryContainer, Theme.alpha.secondaryOnChecked)
        : !clickable ? Theme.color.onSurfaceVariant
        : Theme.color.primary
    readonly property color iconColor: !clickable ? _cp3aDisabled
        : !active ? (_checkRow ? _cp3aDisabled : Theme.color.disabledContentFlat)
        : Theme.color.primary
    /* the checked gradient of a toggle row over its container, 0 to 1 (38 %
       when disabled); the row's Button follows it on the slow effects spring */
    readonly property real checkedGradient: control === "toggle" && checked
        ? (active ? 1 : Theme.alpha.disabledContent) : 0
    /* the radio ring and dot: primary selected, outline not, onSurface 12 % disabled */
    readonly property color radioColor: !active ? _a(Theme.color.onSurface, Theme.alpha.disabledContainer)
        : checked ? Theme.color.primary : Theme.color.outline
    /* the slow effects spring of SwitchButton and RadioButton rows (412 ms) */
    readonly property int colorDuration: Motion.springDuration(Motion.standard.slowEffects.stiffness)
    /* the fast effects spring of the switch and the radio dot (177 ms) */
    readonly property int controlDuration: Motion.springDuration(Motion.standard.fastEffects.stiffness)

    width: parent ? parent.width : Theme.dp(172)
    height: Math.max(minHeight, button.implicitHeight)

    EdgeEffect { id: edge; item: chip; packed: true }

    Binding {
        target: button.label; property: "leftPadding"; when: chip.textInset > 0
        value: chip.textInset
    }
    Binding {
        target: button.secondaryLabel; property: "leftPadding"; when: chip.textInset > 0
        value: chip.textInset
    }

    // a data row: each TextView's first baseline 13 sp under its top and its
    // last 4 sp over its bottom, whatever this font's own ascent and
    // descent. Body4 Flex asks for at least 12 sp and 4 sp
    // (firstBaselineToTopHeight, lastBaselineToBottomHeight), but Android
    // pads only past the font's ascent and descent: the stock font's ascent
    // at 14 sp is 13 sp (26 px), its descent under 4 sp, so stock draws
    // 34 px from baseline to baseline (S22-b)
    readonly property real _sp: Theme.density * Theme.fontScale
    readonly property real _dataBaseline: 13 * _sp
    FontMetrics {
        id: dataMetrics
        font: button.label.font
    }
    // what Qt lays out under the last baseline: its last line keeps the
    // font's whole (rounded up) height
    function _lastDescent(t) {
        return t.contentHeight - (t.lineCount - 1) * t.lineHeight - dataMetrics.ascent
    }
    Binding {
        target: button.label; property: "topPadding"; when: chip.dataRow
        value: chip._dataBaseline - dataMetrics.ascent
    }
    Binding {
        target: button.label; property: "bottomPadding"; when: chip.dataRow
        value: 4 * chip._sp - chip._lastDescent(button.label)
    }
    Binding {
        target: button.secondaryLabel; property: "topPadding"; when: chip.dataRow
        value: chip._dataBaseline - dataMetrics.ascent
    }
    Binding {
        target: button.secondaryLabel; property: "bottomPadding"; when: chip.dataRow
        value: 4 * chip._sp - chip._lastDescent(button.secondaryLabel)
    }
    // packed: about the edge nearest the middle, moved to its packed place
    transform: [
        Scale {
            origin.x: chip.width / 2
            origin.y: edge.originY
            xScale: edge.scale
            yScale: edge.scale
        },
        Translate { y: edge.translateY }
    ]

    Button {
        id: button
        anchors.fill: parent
        opacity: edge.alpha
        enabled: chip.active && chip.clickable
        variant: "tonal"
        text: chip.title
        secondaryText: chip.summary
        iconName: chip.iconName
        horizontalPadding: Theme.space.xl
        verticalPadding: chip.selectable || chip.dataRow ? Theme.space.m : Theme.space.s
        // 24 dp drawn at the start of the 26 dp slot: the 2 dp left over
        // go after it, the text keeps its place (D60-45)
        iconSize: Theme.size.iconSmall
        iconSpacing: Theme.space.s + Theme.size.icon - Theme.size.iconSmall
        minimumHeight: chip.minHeight
        radius: chip.clickable && !chip.dataRow ? Theme.shape.large : Theme.dp(16)
        // a data row: the title on one line, the value on at most 4
        // (SettingsDataPreference mSummaryMaxLines)
        maximumLineCount: chip.dataRow ? 1 : chip.summary === "" && chip.control === "none" ? 5 : 3
        secondaryMaximumLineCount: chip.dataRow ? 4 : 2
        labelRole: chip.dataRow ? "bodyMedium" : "labelMedium"
        secondaryLabelRole: chip.dataRow ? "bodyMedium" : "labelSmall"
        trailingWidth: chip.control === "toggle" ? Theme.size.switchTrackWidth
                     : chip.control === "radio" ? Theme.dp(32) : 0
        trailingSpacing: Theme.space.s

        containerColor: chip.containerColor
        contentColor: chip.titleColor
        secondaryContentColor: chip.summaryColor
        iconColor: chip.iconColor
        Behavior on containerColor {
            enabled: chip.selectable
            ColorAnimation { duration: chip.colorDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.springEasing }
        }
        Behavior on contentColor {
            enabled: chip.selectable
            ColorAnimation { duration: chip.colorDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.springEasing }
        }
        Behavior on secondaryContentColor {
            enabled: chip.selectable
            ColorAnimation { duration: chip.colorDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.springEasing }
        }
        // the checked gradient on the slow effects spring, as SwitchButton
        // (written by the spring, which sets the first value as it is: no
        // binding on checkedGradient)
        WearSpring {
            target: button
            property: "checkedGradient"
            to: chip.checkedGradient
            stiffness: Motion.standard.slowEffects.stiffness
            dampingRatio: 1.0
            visibilityThreshold: 0.001
        }

        Accessible.role: chip.control === "toggle" ? Accessible.CheckBox
                       : chip.control === "radio" || chip.control === "select" ? Accessible.RadioButton
                       : chip.clickable ? Accessible.Button : Accessible.StaticText
        Accessible.checkable: chip.selectable
        Accessible.checked: chip.checked

        onClicked: {
            if (chip.control === "toggle") {
                if (typeof Haptics.toggle === "function")
                    Haptics.toggle(!chip.checked)
            } else if ((chip.control === "radio" || chip.control === "select") && !chip.checked) {
                if (typeof Haptics.select === "function")
                    Haptics.select()
            }
            chip.clicked()
        }

        // the switch of a SwitchButton (org.asteroid.controls Switch: a
        // 48 x 20 px track, a 28 px thumb whose centre goes 14 -> 34 px, no
        // border, no tick, 177 ms), its track translucent over the row and
        // its gradient
        Switch {
            id: chipSwitch
            objectName: "chipSwitch"
            visible: chip.control === "toggle"
            anchors.centerIn: parent
            checked: chip.checked
            enabled: chip.active
            toggleOnClick: false
            containerColor: "transparent"
        }

        // the radio of a RadioButton: ring 20 dp (40 px) outside with a 2 dp
        // (4 px) stroke, dot 10 dp (20 px) growing with the fast effects spring
        Item {
            id: chipRadio
            objectName: "chipRadio"
            visible: chip.control === "radio"
            anchors.centerIn: parent
            width: Theme.dp(32)
            height: Theme.dp(24)
            property real dotScale: chip.checked ? 1 : 0
            Behavior on dotScale {
                NumberAnimation {
                    duration: chip.controlDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.springEasing
                }
            }
            Rectangle {
                objectName: "chipRadioRing"
                anchors.centerIn: parent
                width: Theme.size.radio
                height: width
                radius: width / 2
                color: "transparent"
                border.width: Theme.size.radioStroke
                border.color: chip.radioColor
            }
            Rectangle {
                objectName: "chipRadioDot"
                anchors.centerIn: parent
                width: Theme.size.radioDot
                height: width
                radius: width / 2
                color: chip.radioColor
                scale: chipRadio.dotScale
                visible: chipRadio.dotScale > 0
            }
        }
    }
}
