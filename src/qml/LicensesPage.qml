/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: BSD-3-Clause
 */

import QtQuick
import org.asteroid.settings

// System > About > System licenses as stock CP3A's
// (SystemLicenseLibrariesFragment: one plain row per library, no second
// line, sorted by name (SystemLicenseRepo.java:59, Collections.sort), read
// off the main thread and listed when it is there (supplyAsync, then
// thenAcceptAsync, SystemLicenseLibrariesFragment.java:24-42), each opening
// its licence, SystemLicenseDetailsFragment): one row per part of this
// system, a source recipe of the installed packages, sorted by name, each
// opening its text page (LicenseTextPage) with the part's licence as the
// package manager records it (PackageInfo.readLicenses(), the License field
// of /var/lib/opkg/info/<package>.control), e.g. "LGPL-2.1-only". The image
// ships no full licence texts (the layer would add them with
// LICENSE_CREATE_PACKAGE). The image has some 260 parts: a list that makes
// only the rows near the screen (ChoiceList, as Language).
Item {
    id: page
    objectName: "licensesPage"
    property int depth
    property var pop

    // the parts, read in the background (stock: supplyAsync) and listed
    // when they are there
    property var parts: []
    property bool loaded: false
    PackageInfo {
        id: packages
        onLicensesRead: (parts) => {
            page.parts = parts
            page.loaded = true
        }
    }
    Component.onCompleted: packages.readLicenses()

    Component { id: textLayer; LicenseTextPage { } }
    function show(heading, body) {
        layerStack.push(textLayer, { "heading": heading, "body": body })
    }

    ChoiceList {
        anchors.fill: parent
        //% "System licenses"
        title: qsTrId("id-about-licenses")
        // no package data to list: where the licences are
        message: page.loaded && page.parts.length === 0 ? qsTrId("id-about-legal-text") : ""
        model: page.parts
        textOf: function (i) { return page.parts[i].name }
        // plain rows that open a page (no radio mark)
        opensMore: function (i) { return true }
        currentIndex: -1
        onChosen: (index) => page.show(page.parts[index].name, page.parts[index].license)
    }
}
