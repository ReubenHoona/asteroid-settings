/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 */

.pragma library

/*
 * The top-level pages of stock CP3A Settings that are stubs here until the
 * package that builds them gives them rows: their main list entries keep
 * the stock place (main.qml) and show once the flag is true. The package
 * that fills a page sets its flag here (a one-word change; main.qml stays
 * owned by W1-settings-structure).
 */
var healthProfile = true    // Health profile, HealthProfilePage.qml (W3-settings-apps-privacy)
var location = true         // Location (W3-settings-apps-privacy)
var safety = true           // Safety & Emergency, SafetyPage.qml (with Emergency SOS)
var accessibility = true    // Accessibility (W3-settings-apps-privacy)
var security = true         // Security (W3-settings-apps-privacy)
