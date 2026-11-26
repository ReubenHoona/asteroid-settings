/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */
.pragma library

/*
 * What's new after an update (setup-wizard-15, CR-42): eos-update writes
 * /org/asteroidos/eos-update/whatsnew-version (s) and whatsnew-notes (s,
 * pages split at "|", each "Headline: text") once a new version confirmed
 * itself. The launcher's splash shows the pages once; Settings > General >
 * What's new shows them again while both keys hold something. Pure
 * functions (tests/tst_fp3.qml).
 */

function text(v) {
    return v === undefined || v === null ? "" : String(v).trim()
}

/* The pages: [{ headline, text }], blank pages dropped; the headline is what
 * comes before the first ":" (none: the whole page is text). */
function pages(notes) {
    var out = []
    var parts = text(notes).split("|")
    for (var i = 0; i < parts.length; i++) {
        var p = parts[i].trim()
        if (p === "")
            continue
        var cut = p.indexOf(":")
        if (cut > 0)
            out.push({ headline: p.substring(0, cut).trim(), text: p.substring(cut + 1).trim() })
        else
            out.push({ headline: "", text: p })
    }
    return out
}

/* The row is shown when both keys hold something. */
function available(version, notes) {
    return text(version) !== "" && pages(notes).length > 0
}
