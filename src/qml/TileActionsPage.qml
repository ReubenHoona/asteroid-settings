/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import "tileactions.js" as Actions

// Apps & notifications > Assistant > Tile actions (tiles-individual-25): the
// action chips of the Assistant tile, the second edit path the audit named
// (the tile's own editing screen adds a chip; this page takes one away).
// Stock's tile has no remove: "To change button actions, remove this tile
// and then add it back" (assistant change_button_action_content); our tile
// keeps up to five actions and shows the first two, so a way to drop one is
// kept here. The list is the launcher's dconf string list
// /org/asteroidos/assistant/tile-actions, read and written with a copy of the
// launcher's tileactions.js: unset (or ["@default"]) = the three chips the
// tile always had, ["@none"] = no action; a tap asks first, then removes.
SettingsPage {
    id: page
    objectName: "tileActionsPage"
    //% "Tile actions"
    title: qsTrId("id-tile-actions")

    ConfigurationValue {
        id: stored
        key: "/org/asteroidos/assistant/tile-actions"
        defaultValue: ["@default"]
    }

    // the chips of an untouched tile, in the launcher's words and ids
    // (AssistantTile.suggestions), so a kept default keeps its icon there
    readonly property var defaults: [
        //% "What's the weather?"
        qsTrId("id-tile-asst-weather"),
        //% "Set a timer for 5 minutes"
        qsTrId("id-tile-asst-timer"),
        //% "When is my next alarm?"
        qsTrId("id-tile-asst-alarm")
    ]
    readonly property var actions: Actions.parse(stored.value, defaults)

    function remove(text) {
        stored.value = Actions.toStore(Actions.remove(page.actions, text))
    }

    SettingsText {
        objectName: "tileActionsCaption"
        text: page.actions.length > 0
              //% "Tap an action to remove it from the Assistant tile"
              ? qsTrId("id-tile-actions-explain")
              //% "No actions. Add one on the Assistant tile"
              : qsTrId("id-tile-actions-none")
    }
    Repeater {
        model: page.actions
        delegate: SettingsChip {
            required property string modelData
            objectName: "tileActionItem"
            title: modelData
            //% "Remove action?"
            onClicked: confirm.ask(qsTrId("id-tile-action-remove"), modelData,
                                   function () { page.remove(modelData) })
        }
    }
}
