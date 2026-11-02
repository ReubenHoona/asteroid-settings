/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls

// Settings > Watch face & style (stock: the system UI's
// WatchfaceAndStyleSettingsActivity): Change watch face, then the wallpaper
// behind the faces (stock has its system theme in that place).
SettingsPage {
    objectName: "stylePage"
    title: qsTrId("id-style-page")

    SettingsChip {
        objectName: "styleWatchface"
        title: qsTrId("id-change-watchface")
        iconName: "ios-watch"
        onClicked: layerStack.push(watchfaceLayer)
    }
    SettingsChip {
        objectName: "wallpaperItem"
        title: qsTrId("id-wallpaper-page")
        iconName: "ios-image-outline"
        onClicked: layerStack.push(wallpaperLayer)
    }
}
