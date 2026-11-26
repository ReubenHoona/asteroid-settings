/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

.pragma library

/*
 * The names of the languages as System > Language lists them
 * (LanguagePage) and as System's Language row shows the current one
 * (SystemPage), for row i of a LanguageModel.
 */

// sentence case: "français" -> "Français"
function sentence(s) {
    return s.length > 0 ? s.charAt(0).toLocaleUpperCase() + s.slice(1) : s
}

// the country in its own language ("United Kingdom"); "" when Qt does not
// know the code
function nativeCountry(model, i) {
    var l = Qt.locale(model.locale(i))
    return l.name !== "C" ? (l.nativeTerritoryName !== undefined ? l.nativeTerritoryName : l.nativeCountryName) : ""
}

// QLocale(code): the native language name; the model's own name when Qt
// does not know the code. Qt names a dialect ("British English", "español
// de España"), stock the language: the shortest of the names of the code,
// of the language's world locale and of its default one, with a trailing
// " de <territory>" cut
function nativeLanguage(model, i) {
    var code = String(model.locale(i))
    var base = code.split(/[_@.]/)[0]
    var own = Qt.locale(code)
    if (own.name === "C")
        return model.languageName(i)
    var best = ""
    var cands = [own, Qt.locale(base + "_001"), Qt.locale(base)]
    for (var k = 0; k < cands.length; k++) {
        var n = cands[k].nativeLanguageName
        if (cands[k].name !== "C" && n !== "" && (best === "" || n.length < best.length))
            best = n
    }
    var suffix = " de " + nativeCountry(model, i)
    if (suffix.length > 4 && best.length > suffix.length && best.slice(-suffix.length) === suffix)
        best = best.slice(0, -suffix.length)
    return sentence(best)
}
