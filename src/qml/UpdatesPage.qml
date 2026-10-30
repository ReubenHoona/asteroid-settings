/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import Nemo.DBus

// System update, as Wear OS's System > System updates: the state of the
// system updater (eos-update writes it to dconf), "Check for update", and
// "Install now" once an update is ready (it also installs by itself while
// the watch charges). The buttons start a user unit that hands the request
// to eos-update, which decides as root.
Item {
    id: page
    property int depth
    property var pop
    property bool checking: false

    ConfigurationValue { id: updState; key: "/org/asteroidos/eos-update/state"; defaultValue: "" }
    ConfigurationValue { id: updVersion; key: "/org/asteroidos/eos-update/version"; defaultValue: "" }
    ConfigurationValue { id: updAvailable; key: "/org/asteroidos/eos-update/available"; defaultValue: "" }
    ConfigurationValue { id: updChecked; key: "/org/asteroidos/eos-update/checked"; defaultValue: "" }
    ConfigurationValue { id: updStatus; key: "/org/asteroidos/eos-update/status"; defaultValue: "" }

    // a finished check rewrites the keys; the "Checking" label goes then
    Connections {
        target: updChecked
        function onValueChanged() { page.checking = false }
    }
    Timer { id: checkTimeout; interval: 60000; onTriggered: page.checking = false }

    DBusInterface {
        id: userSystemd
        bus: DBus.SessionBus
        service: "org.freedesktop.systemd1"
        path: "/org/freedesktop/systemd1"
        iface: "org.freedesktop.systemd1.Manager"
    }
    function request(unit) {
        userSystemd.call("StartUnit", [unit, "replace"])
    }

    readonly property string headline: {
        switch (updState.value) {
        //% "Version %1 is ready to install"
        case "staged": return qsTrId("id-update-ready").arg(updAvailable.value)
        //% "Installing the update"
        case "installing": return qsTrId("id-update-installing")
        //% "Finishing the update"
        case "trial": return qsTrId("id-update-trial")
        //% "The update couldn't be installed"
        case "failed": return qsTrId("id-update-failed")
        //% "The update needs attention. Connect your watch to the computer."
        case "broken": return qsTrId("id-update-broken")
        //% "Your watch is up to date"
        case "current": return qsTrId("id-update-current")
        default: return updStatus.value
        }
    }
    readonly property string detail: {
        //% "It installs while your watch charges"
        if (updState.value === "staged") return qsTrId("id-update-ready-hint")
        //% "Version %1"
        var v = updVersion.value !== "" ? qsTrId("id-update-version").arg(updVersion.value) : ""
        //% "Last checked %1"
        var c = updChecked.value !== "" ? qsTrId("id-update-checked").arg(updChecked.value) : ""
        return c !== "" ? v + "\n" + c : v
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: title.height
        clip: true
        contentHeight: column.implicitHeight
        Column {
            id: column
            width: parent.width
            Icon {
                name: updState.value === "staged" ? "ios-cloud-download-outline"
                    : (updState.value === "failed" || updState.value === "broken") ? "ios-alert-outline"
                    : "ios-cloud-done-outline"
                width: Dims.l(16)
                height: width
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Item { width: parent.width; height: Dims.l(2) }
            Label {
                width: parent.width * 0.8
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.pixelSize: Dims.l(7)
                text: page.headline
            }
            Label {
                width: parent.width * 0.8
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                opacity: 0.7
                font.pixelSize: Dims.l(5)
                text: page.detail
                visible: text !== ""
            }
            Item { width: parent.width; height: Dims.l(4) }
            LabeledActionButton {
                width: parent.width
                height: Dims.l(20)
                visible: updState.value === "staged"
                //% "Install now"
                text: qsTrId("id-update-install")
                icon: "ios-arrow-dropright"
                onClicked: remorse.start()
            }
            LabeledActionButton {
                width: parent.width
                height: Dims.l(20)
                visible: updState.value !== "staged" && updState.value !== "installing" && updState.value !== "trial"
                enabled: !page.checking
                opacity: page.checking ? 0.5 : 1.0
                //% "Checking for updates"
                text: page.checking ? qsTrId("id-update-checking")
                    //% "Check for update"
                    : qsTrId("id-update-check")
                icon: "ios-sync"
                onClicked: {
                    page.checking = true
                    checkTimeout.restart()
                    request("eos-update-check-request.service")
                }
            }
            Item { width: parent.width; height: Dims.l(15) }
        }
    }

    RemorseTimer {
        id: remorse
        duration: 3000
        //% "Restarting to install"
        action: qsTrId("id-update-restarting")
        cancelText: qsTrId("id-tap-to-cancel")
        onTriggered: request("eos-update-install-request.service")
    }

    PageHeader {
        id: title
        //% "System update"
        text: qsTrId("id-update-page")
    }
}
