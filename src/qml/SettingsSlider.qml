/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

/*
 * The Settings slider (SliderItem): the org.asteroid.controls InlineSlider,
 * the Wear OS 6 emulator's stepper (S21, S21-d volumes, S24 Brightness;
 * NEWLOOK-61 N61-42), px on the 384 px Pixel Watch 2 (2 px per dp):
 * - a 52 dp (104 px) pill the row's width (x 20-363), surfaceContainer
 *   #2F3036;
 * - decrease and increase segments 36 dp (72 px) wide at the ends, cut from
 *   the middle by 1 dp (2 px) black dividers the pill's height (x 92-93 and
 *   290-291), the glyphs pure white with square ends: the minus 32 x 4 px,
 *   the plus 32 x 32 px with 4 px strokes; at the limit, or inactive, 38 %;
 * - the bar 7 dp inside the dividers (x 108-275), 6 dp (12 px) tall, fully
 *   round: #202124 with the selected part in tertiary #D4C7FF from the start;
 *   the selected fraction animates 150 ms with (0, 0, 0, 1), as CP3A;
 * - segmented sliders (stock SliderUiState.segmented: Brightness and Audio
 *   balance) cut the bar into the steps with 1 px black gaps, no dots; the
 *   volume streams and Vibration are one bar (CP3A
 *   SliderController$Brightness$$ExternalSyntheticLambda0.java:44,
 *   MediaVolumeSliderPreference.java:65, SliderItemAdapter.java:402);
 * - a tap on a segment steps by stepSize between lowest and to: the step
 *   onto the first or last value plays GESTURE_END, every other one
 *   SEGMENT_FREQUENT_TICK (CP3A SliderKt$$ExternalSyntheticLambda8.java:20-40);
 *   a tap that moves nothing plays nothing.
 * CP3A drew the Wear Material 3 Slider instead (48 dp buttons, a 24 px
 * primary selected part, 8 px step dots). The Display size & text sliders
 * follow it too. In the list it shrinks and fades packed with the page's
 * rows (InlineSlider's own packed EdgeEffect; edgeEffect turns it off).
 *
 *   SettingsSlider { from: 0; to: 100; stepSize: 10; value: level; onMoved: (v) => level = v }
 *   SettingsSlider { segmented: true; ... }   // Brightness
 */
InlineSlider {
    id: slider
    // the API, the steps, the haptics and the accessibility of the old
    // SettingsSlider are InlineSlider's: from, to, stepSize, value, lowest,
    // active, segmented, decreaseDescription, increaseDescription,
    // valueDescription, edgeEffect, steps, position, segments, moved(),
    // stepBy()
}
