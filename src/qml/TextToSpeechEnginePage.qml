/*
 * Copyright (C) 2026 eos
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.controls
import Nemo.Configuration
import Nemo.DBus

// A speech engine's page, as stock CP3A's TtsServiceFragment
// (prefs_accessibility_tts_engine.xml, "Engine settings";
// TtsServiceFragment.java:150-292):
// - Language: "Use system language", then the engine's languages; flite
//   has English (United States). /org/asteroidos/assistant/tts-language,
//   "" for the system language, else the locale ("en_US").
// - Listen to an example: the engine reads its sample sentence
//   (tts_default_sample_string) at the current rate. The assistant speaks
//   it (org.asteroidos.assistant Speak(s)), which it announces with
//   /org/asteroidos/assistant/tts-sample-supported (the gate: hidden until
//   then, a row that does nothing is not shown). The speech stops when the
//   page goes, as stock's onDestroy shuts its TextToSpeech down.
// - Set as default: checked for the default engine, greyed while there is
//   only one (TtsServiceFragment.java:282-286).
// As the page opens, stock's toast tells whether the engine speaks the
// language it will use (updateEngineStatus: "%1$s is fully supported",
// "%1$s is not supported"; tts_status_ok / tts_status_not_supported).
SettingsPage {
    id: page
    objectName: "ttsEnginePage"
    //% "Engine settings"
    title: qsTrId("id-tts-engine-settings")

    ConfigurationValue {
        id: language
        key: "/org/asteroidos/assistant/tts-language"
        defaultValue: ""
    }
    ConfigurationValue {
        id: sampleSupported
        key: "/org/asteroidos/assistant/tts-sample-supported"
        defaultValue: false
    }
    DBusInterface {
        id: assistant
        bus: DBus.SessionBus
        service: "org.asteroidos.assistant"
        path: "/org/asteroidos/assistant"
        iface: "org.asteroidos.assistant"
    }

    // the engine's languages: flite's voices are English (United States)
    readonly property var locales: ["en_US"]
    readonly property var localeNames: [
        //% "English (United States)"
        qsTrId("id-tts-lang-en-us")
    ]
    readonly property var languageOptions: [
        //% "Use system language"
        qsTrId("id-tts-use-system-language")
    ].concat(localeNames)
    readonly property int languageIndex: {
        var i = locales.indexOf(String(language.value || ""))
        return i < 0 ? 0 : i + 1
    }
    // the locale the engine speaks: the chosen one, else the system's when
    // the engine has its language; -1 when it has none
    function spokenLocale() {
        if (languageIndex > 0)
            return languageIndex - 1
        var system = Qt.locale().name.split(/[_@.]/)[0]
        for (var i = 0; i < locales.length; i++)
            if (locales[i].split("_")[0] === system)
                return i
        return -1
    }
    function status() {
        var i = spokenLocale()
        if (i >= 0)
            //% "%1 is fully supported"
            return qsTrId("id-tts-status-ok").arg(localeNames[i])
        var own = Qt.locale()
        var name = own.nativeLanguageName || own.name
        //% "%1 is not supported"
        return qsTrId("id-tts-status-not-supported").arg(name.charAt(0).toLocaleUpperCase() + name.slice(1))
    }
    property bool speaking: false
    function listen() {
        speaking = true
        //% "This is an example of speech synthesis"
        assistant.call("Speak", [qsTrId("id-tts-sample")])
    }
    Component.onCompleted: Qt.callLater(function () { toast.show(page.status()) })
    Component.onDestruction: if (speaking) assistant.call("StopSpeaking", [])

    SettingsChip {
        objectName: "ttsLanguageItem"
        title: qsTrId("id-language-page")
        summary: page.languageOptions[page.languageIndex]
        onClicked: app.choose(qsTrId("id-language-page"), page.languageOptions, page.languageIndex,
                              function (i) {
                                  language.value = i === 0 ? "" : page.locales[i - 1]
                                  toast.show(page.status())
                              })
    }
    SettingsChip {
        objectName: "ttsListenItem"
        visible: sampleSupported.value === true || sampleSupported.value === "true"
        active: page.spokenLocale() >= 0
        //% "Listen to an example"
        title: qsTrId("id-tts-listen")
        onClicked: if (active) page.listen()
    }
    SettingsChip {
        objectName: "ttsDefaultSwitch"
        //% "Set as default"
        title: qsTrId("id-tts-set-default")
        control: "toggle"
        checked: true
        active: false
    }
}
