/*
 * Copyright (C) 2023 - Arseniy Movshev <dodoradio@outlook.com>
 *               2022 - Ed Beroset <github.com/beroset>
 *               2017-2022 - Chupligin Sergey <neochapay@gmail.com>
 *               2021 - Darrel Griët <idanlcontact@gmail.com>
 *               2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 *               2015 - Florent Revest <revestflo@gmail.com>
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

/* A large proportion of this code has been referenced from Nemomobile-UX Glacier-Settings, published at https://github.com/nemomobile-ux/glacier-settings/blob/master/src/plugins/wifi/WifiSettings.qml
 */

import QtQuick
import org.asteroid.controls
import org.asteroid.utils
import Connman

Item {
    id: dialogItem
    property int depth
    property var pop
    property string servicePath
    property NetworkService modelData: NetworkService {path: dialogItem.servicePath}
    UserAgent {
        id: userAgent
        onUserInputRequested: (requestServicePath, fields) => {
            dialogItem.servicePath = requestServicePath
            dialogItem.sourceFields = fields
        }
        onErrorReported: {
            console.log("Got error from model: " + error)
        }
    }
    property var sourceFields: ({})
    property var loginFields: ({})

    onSourceFieldsChanged: () => { //keep any fields that already exist, add new ones, discard old ones
        var fieldsBackup = loginFields
        loginFields = {}
        for (const [field, args] of Object.entries(sourceFields)) {
            if(fieldsBackup[field]) {
                loginFields[field] = fieldsBackup[field]
                delete fieldsBackup[field]
            } else {
                loginFields[field] = loginField.createObject(loginFieldsColumn,{"fieldName": field, "fieldArgs": args})
            }
        }
        for (const [field, fieldInstance] of Object.entries(fieldsBackup)) {
            fieldInstance.destroy()
        }
    }


    Connections {
        target: modelData
        function onConnectRequestFailed(error) {
            console.log(error)
            layerStack.push(errorPopup, {networkService: modelData, text: qsTrId("id-wifi-connectionError")})
        }

        function onConnectedChanged(connected) {
            if(connected) {
                sourceFields = {}
            }
        }
    }

    // A network as the stock Wi-Fi pages show one: its name as the title,
    // the fields the network asks for (with Connect), then the IP address
    // and Disconnect while connected, Autoconnect, and Forget, which asks
    // first ("Forget network %1?", ✕ / ✓)
    SettingsPage {
        id: networkPage
        anchors.fill: parent
        //% "Hidden network"
        title: modelData.name ? modelData.name : qsTrId("id-wifi-hiddennetwork")

        Column {
            id: loginFieldsColumn
            width: parent.width
        }
        SettingsChip {
            objectName: "wifiConnect"
            // easiest way to check if we've got some active agent fields
            visible: loginFieldsColumn.children.length > 0 && !modelData.connected
            //% "Connect"
            title: qsTrId("id-wifi-connect")
            iconName: "ios-checkmark"
            onClicked: {
                var reply = {}
                for (const [field, args] of Object.entries(sourceFields)) {
                    if(loginFields[field].text != "" && args["Requirement"] != "informational")
                        reply[field] = loginFields[field].text
                }
                userAgent.sendUserReply(reply)
            }
        }
        SettingsChip {
            objectName: "wifiIp"
            visible: modelData.connected
            clickable: false
            //% "IP address"
            title: qsTrId("id-wifi-ip")
            summary: modelData.ipv4 && modelData.ipv4["Address"] ? modelData.ipv4["Address"] : ""
        }
        SettingsChip {
            objectName: "wifiDisconnect"
            visible: modelData.connected
            //% "Disconnect"
            title: qsTrId("id-wifi-disconnect")
            iconName: "ios-close-circle-outline"
            onClicked: {
                modelData.requestDisconnect()
                layerStack.pop(layerStack.currentLayer)
            }
        }
        SettingsChip {
            objectName: "wifiAutoconnect"
            //% "Autoconnect"
            title: qsTrId("id-wifi-autoconnect")
            control: "toggle"
            checked: modelData.autoConnect
            onClicked: modelData.autoConnect = !modelData.autoConnect
        }
        SettingsChip {
            objectName: "wifiForget"
            visible: modelData.connected || modelData.favorite
            //% "Forget network"
            title: qsTrId("id-wifi-removenetwork")
            iconName: "ios-trash-outline"
            onClicked: confirm.ask(
                           //% "Forget network %1?"
                           qsTrId("id-wifi-forget-confirm").arg(networkPage.title), "",
                           function () {
                               modelData.remove()
                               layerStack.pop(layerStack.currentLayer)
                           })
        }
    }

    Component {
        id: loginField

        Column {
            width: parent.width
            property string fieldName
            property var fieldArgs
            property alias text: fieldInput.text
            visible: fieldArgs["Requirement"] != "informational"
            Component.onCompleted: if(fieldArgs["Requirement"] == "mandatory" && sourceFields["PreviousPassphrase"]) fieldInput.text = sourceFields["PreviousPassphrase"]["Value"]
            Label {
                id: fieldLabel
                text: switch (fieldName) {
                    //% "Name (SSID):"
                    case "Name": qsTrId("id-wifi-ssid"); break;
                    //% "Name (Identity):"
                    case "Identity": qsTrId("id-wifi-identity"); break;
                    //% "Passphrase:"
                    case "Passphrase": qsTrId("id-wifi-passphrase"); break;
                    //% "WPS:"
                    case "WPS": qsTrId("id-wifi-wps"); break;
                    //% "Username:"
                    case "Username": qsTrId("id-wifi-username"); break;
                    //% "Password:"
                    case "Password": qsTrId("id-wifi-password"); break;
                }
                font.pixelSize: Dims.l(6)
            }
            // a tap opens the full screen keyboard (qml-asteroid's
            // WearKeyboard); a passphrase shows as dots there and here
            TextField {
                id: fieldInput
                // the agent's value for the field, if any (it was the
                // network object's name as text: "NetworkService(0x...)")
                text: fieldArgs && fieldArgs["Value"] ? fieldArgs["Value"] : ""
                width: parent.width
                echoMode: (fieldName === "Passphrase" || fieldName === "Password" || fieldName === "WPS")
                          ? TextInput.Password : TextInput.Normal
                previewText: fieldLabel.text
            }
        }
    }

    Component {
        id: errorPopup
        StatusPage {
            icon: "ios-remove-circle"
            anchors.fill: undefined
            property NetworkService networkService
            Component.onDestruction: networkService.requestConnect()
        }
    }
}
