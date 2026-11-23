/*
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// Display > Color theme as stock CP3A's theme page (the Display row,
// ColorThemePreference.java:53-81, opens it; sysui jbp.java:33-123): the
// title "Color theme", then Match watch face, the eight presets of
// Theme.colorPresets in stock order (muy.a) and No theme, one checkable chip
// each (SystemThemePreference.java, layout/color_settings_preference.xml: a
// WearChipButton in the avatar style, checked primaryContainer with
// onPrimaryContainer text, else surfaceContainer and onSurface). The avatar
// is 38 dp (color_settings_icon_size), 10 dp from the start, 8 dp before the
// text: for a theme its swatch (jbb.java:45-69: a disc 3 dp inside a 1.5 dp
// ring, its top half primary_fixed_dim, the bottom left quarter
// secondary_fixed, the bottom right secondary_container; the ring in
// onPrimaryContainer when checked), for No theme the palette in primary
// with a white ring when checked (drawable/paint_palette_stateful.xml).
// A tap applies the theme at once and the page stays (jbp N(): the tapped
// chip checked, the others not). The keys say No theme until the faces
// report their colours (DECISIONS Q1c), so No theme is the checked row.
// Theme (qml-asteroid) holds the colour logic; this page lists and writes.
SettingsPage {
    id: page
    objectName: "colorThemePage"
    //% "Color theme"
    title: qsTrId("id-color-theme")

    // the stock theme_style of each preset style (Theme._resolveColorTheme)
    readonly property var styleIds: ({ "neutral": 0, "tonal-spot": 1, "vibrant": 2, "expressive": 3, "content": 6 })
    function styleOf(seed) {
        for (var i = 0; i < Theme.colorPresets.length; i++)
            if (Theme.colorPresets[i].seed === seed)
                return page.styleIds[Theme.colorPresets[i].style]
        return page.styleIds["content"]
    }
    // the swatch of a seed: [top half, bottom left, bottom right]. Stock
    // takes primary_fixed_dim, secondary_fixed and secondary_container of
    // the seed's scheme (muy.java:56-76, hqx b, d, e), which are tones 80,
    // 90 and 30 of its primary and secondary palettes; the palettes' hue
    // and chroma here are those of the Wear scheme PaletteGenerator makes
    // for the seed, so the swatch is close to stock's, not exact.
    function swatchOf(seed, accent) {
        var g = PaletteGenerator.generate(seed, accent || "", page.styleOf(seed))
        if (g.primary === undefined)
            return []
        var p = PaletteGenerator.hct(g.primary)
        var s = PaletteGenerator.hct(g.secondary)
        return [PaletteGenerator.fromHct(p.hue, p.chroma, 80),
                PaletteGenerator.fromHct(s.hue, s.chroma, 90),
                PaletteGenerator.fromHct(s.hue, s.chroma, 30)]
    }

    // the rows: Match watch face, the presets, No theme (made once: a
    // theme change recolours them, it does not remake them)
    readonly property var entries: {
        //% "Match watch face"
        var out = [{ "id": "watchface", "source": "watchface", "name": qsTrId("id-color-theme-match-face"), "seed": "" }]
        for (var i = 0; i < Theme.colorPresets.length; i++) {
            var p = Theme.colorPresets[i]
            out.push({ "id": p.id, "source": "preset", "name": p.name, "seed": p.seed })
        }
        //% "No theme"
        out.push({ "id": "static", "source": "static", "name": qsTrId("id-color-theme-none"), "seed": "" })
        return out
    }
    // the checked row: it follows the keys, so a change made elsewhere too
    readonly property string current: {
        if (Theme.colorSource === "watchface" || Theme.colorSource === "static")
            return Theme.colorSource
        for (var i = 0; i < Theme.colorPresets.length; i++)
            if (Theme.colorPresets[i].seed === Theme.colorSeed)
                return Theme.colorPresets[i].id
        return ""
    }
    function choose(entry) {
        Theme.setColorTheme(entry.source, entry.seed)
    }

    // the avatar: 38 dp, 10 dp from the chip's start, the text 8 dp after it
    readonly property real avatarSize: Theme.dp(38)
    readonly property real avatarStart: Theme.dp(10)
    readonly property real textStart: avatarStart + avatarSize + Theme.dp(8)

    Repeater {
        model: page.entries
        SettingsChip {
            id: row
            required property var modelData
            objectName: "colorTheme_" + modelData.id
            title: modelData.name
            control: "select"
            checked: page.current === modelData.id
            onClicked: page.choose(modelData)
            // Match watch face: the face's colours once it reports them
            // (Theme), Moonstone before (jbp.java:41, O().a())
            readonly property bool _face: modelData.source === "watchface"
            readonly property string seed: _face ? (Theme.colorSource === "watchface" ? Theme.colorSeed : Theme.colorDefaultSeed)
                                                 : modelData.seed
            readonly property string accent: _face && Theme.colorSource === "watchface" ? Theme.colorAccent : ""

            // the text after the avatar (the row's own padding is 14 dp)
            textInset: page.textStart - Theme.space.xl

            Item {
                id: avatar
                objectName: "colorThemeAvatar"
                x: page.avatarStart
                y: (row.height - height) / 2
                width: page.avatarSize
                height: width
                opacity: row.contentAlpha
                readonly property bool isPalette: row.modelData.source === "static"
                readonly property var swatch: isPalette ? [] : page.swatchOf(row.seed, row.accent)

                Canvas {
                    id: swatchCanvas
                    objectName: "colorThemeSwatch"
                    anchors.fill: parent
                    readonly property var colors: avatar.swatch
                    readonly property bool ring: row.checked
                    readonly property color ringColor: avatar.isPalette ? "#FFFFFF" : Theme.color.onPrimaryContainer
                    onColorsChanged: requestPaint()
                    onRingChanged: requestPaint()
                    onRingColorChanged: requestPaint()
                    // Java Math.rint: halves go to the even neighbour
                    function rint(v) {
                        var r = Math.round(v)
                        return (Math.abs(v - Math.floor(v) - 0.5) < 1e-9 && r % 2 !== 0) ? r - 1 : r
                    }
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        var c = width / 2
                        var stroke = Theme.dp(1.5)
                        if (!avatar.isPalette && colors.length === 3) {
                            // jbb: the ring's centre line 0.75 dp inside, the disc 3 dp inside it
                            var r = rint(c - stroke / 2 - Theme.dp(3))
                            var parts = [[Math.PI, 1.5 * Math.PI, colors[0]], [1.5 * Math.PI, 2 * Math.PI, colors[0]],
                                         [0, 0.5 * Math.PI, colors[2]], [0.5 * Math.PI, Math.PI, colors[1]]]
                            for (var i = 0; i < parts.length; i++) {
                                ctx.beginPath()
                                ctx.moveTo(c, c)
                                ctx.arc(c, c, r, parts[i][0], parts[i][1], false)
                                ctx.closePath()
                                ctx.fillStyle = parts[i][2]
                                ctx.fill()
                            }
                        }
                        if (ring) {
                            ctx.beginPath()
                            // the palette's ring: 440 of 960 units, 38 wide
                            var rr = avatar.isPalette ? width * 440 / 960 : c - stroke / 2
                            ctx.lineWidth = avatar.isPalette ? width * 38 / 960 : stroke
                            ctx.strokeStyle = ringColor
                            ctx.arc(c, c, rr, 0, 2 * Math.PI, false)
                            ctx.stroke()
                        }
                    }
                }
                // No theme: the palette (paint_palette, 38 dp box) in primary
                Icon {
                    objectName: "colorThemePalette"
                    visible: avatar.isPalette
                    x: (avatar.width - width) / 2
                    y: (avatar.height - height) / 2
                    width: Theme.dp(26)
                    height: width
                    name: "ios-color-palette-outline"
                    color: Theme.color.primary
                }
            }
        }
    }
}
