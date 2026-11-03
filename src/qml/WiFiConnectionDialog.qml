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
    // false: a new secured network (stock's configure page: "Network password
    // required", Enter on watch); true: a connect that failed (Retry, Open on
    // watch, and Forget unless it was the password)
    property bool failed: false
    readonly property bool authFailure: modelData.error === "invalid-key"
    // Enter on watch / Open on watch: connect, so that connman asks this
    // agent for the passphrase, then the fields and Connect
    property bool entering: false
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
            dialogItem.failed = true
            dialogItem.entering = false
            sourceFields = {}
        }

        function onConnectedChanged(connected) {
            if(connected) {
                sourceFields = {}
                layerStack.pop(layerStack.currentLayer)
            }
        }
    }

    // Stock's configure page (prefs_wifi_configure.xml, WifiConfigureNetworkFragment).
    // A new secured network: its name as the title, "Network password
    // required", Enter on watch (stock's Enter on phone needs the phone's
    // Wear OS app: not here). A failed connect: "Wrong password" or "Wi-Fi
    // connection failure" as the title, Retry, Open on watch, and Forget
    // ("Forget network %1?") unless the password was wrong. Enter/Open on
    // watch shows the field connman asks for (the full screen keyboard) and
    // Connect.
    SettingsPage {
        id: networkPage
        objectName: "wifiConnectPage"
        anchors.fill: parent
        title: !dialogItem.failed
               //% "Hidden network"
               ? (modelData.name ? modelData.name : qsTrId("id-wifi-hiddennetwork"))
               : dialogItem.authFailure
                 ? qsTrId("id-wifi-wrong-password")
                 //% "Wi-Fi connection failure"
                 : qsTrId("id-wifi-failure")

        SettingsChip {
            objectName: "wifiPasswordRequired"
            visible: !dialogItem.failed && !dialogItem.entering
            clickable: false
            //% "Network password required"
            title: qsTrId("id-wifi-password-required")
        }
        SettingsChip {
            objectName: "wifiRetry"
            visible: dialogItem.failed && !dialogItem.entering
            //% "Retry"
            title: qsTrId("id-wifi-retry")
            onClicked: {
                modelData.requestConnect()
                layerStack.pop(layerStack.currentLayer)
            }
        }
        SettingsChip {
            objectName: "wifiEnterOnWatch"
            visible: !dialogItem.entering
            title: dialogItem.failed
                   //% "Open on watch"
                   ? qsTrId("id-wifi-open-on-watch")
                   //% "Enter on watch"
                   : qsTrId("id-wifi-enter-on-watch")
            onClicked: {
                dialogItem.entering = true
                modelData.requestConnect()
            }
        }
        SettingsChip {
            objectName: "wifiForget"
            visible: dialogItem.failed && !dialogItem.authFailure && !dialogItem.entering
            title: qsTrId("id-wifi-forget-confirm").arg(modelData.name)
            onClicked: confirm.ask(qsTrId("id-wifi-forget-confirm").arg(modelData.name), "",
                                   function () {
                                       modelData.remove()
                                       layerStack.pop(layerStack.currentLayer)
                                   })
        }

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
}
