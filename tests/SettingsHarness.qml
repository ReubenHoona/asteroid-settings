/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * The real main.qml at 384x384 inside the round mask of the display, and
 * what the tests do with it: find items, scroll to them, tap them, go back,
 * take screenshots (into /tmp/setstk-shots, the runner moves them).
 */

import QtQuick
import QtTest
import SettingsTest

Item {
    id: harness
    width: 384
    height: 384

    // context properties of main.cpp
    property string kernelVersion: "6.12.0-eos"
    property string qtVersion: "6.11.3"

    property alias app: loader.item
    property var stack: null
    property string shots: "/tmp/setstk-shots"
    // how often a page asked the app to end (Change watch face, Touch lock):
    // the app does not quit under test
    property int closeCount: 0

    Rectangle { anchors.fill: parent; color: "black" }

    Item {
        id: screen
        width: 384
        height: 384
        clip: true
        Loader {
            id: loader
            anchors.fill: parent
            active: false
            source: Qt.resolvedUrl("../src/qml/main.qml")
        }
        // the round display: what is outside it is never seen
        Canvas {
            anchors.fill: parent
            z: 100
            onPaint: {
                var ctx = getContext("2d")
                ctx.fillStyle = "#000000"
                ctx.beginPath()
                ctx.rect(0, 0, width, height)
                ctx.arc(width / 2, height / 2, width / 2, 0, 2 * Math.PI, true)
                ctx.fill()
                ctx.strokeStyle = "#555555"
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.arc(width / 2, height / 2, width / 2 - 0.5, 0, 2 * Math.PI)
                ctx.stroke()
            }
        }
    }

    function typeName(o) {
        return String(o).replace(/_QML(TYPE)?_[0-9]+.*$/, "").replace(/\(0x.*$/, "")
    }
    function find(item, name) {
        if (!item)
            return null
        if (item.objectName === name)
            return item
        var kids = item.children || []
        for (var i = 0; i < kids.length; i++) {
            var r = find(kids[i], name)
            if (r)
                return r
        }
        if (item.contentItem && item.contentItem !== item) {
            var c = find(item.contentItem, name)
            if (c)
                return c
        }
        return null
    }
    function findAll(item, pred, out) {
        out = out || []
        if (!item)
            return out
        if (pred(item))
            out.push(item)
        var kids = item.children || []
        for (var i = 0; i < kids.length; i++)
            findAll(kids[i], pred, out)
        return out
    }
    function shown(item) {
        for (var p = item; p; p = p.parent)
            if (!p.visible)
                return false
        return true
    }
    function start(t) {
        Backend.reset()
        loader.active = false
        loader.active = true
        t.tryCompare(loader, "status", Loader.Ready)
        stack = find(loader.item, "LayerStack")
        t.verify(stack !== null, "the LayerStack")
        closeCount = 0
        loader.item.closeApp = function () { harness.closeCount++ }
        t.wait(300)
    }
    // the selection dialog while it is up (list settings open in it), else
    // the page on top of the stack
    function chooser() { return find(loader.item, "choiceDialog") }
    function current() {
        var d = chooser()
        if (d && d.shown)
            return d
        return stack.layers.length > 0 ? stack.currentLayer : stack.firstPageItem
    }
    function flickableOf(item) {
        for (var p = item.parent; p; p = p.parent)
            if (p.hasOwnProperty("contentY") && p.hasOwnProperty("flickableDirection"))
                return p
        return null
    }
    // scroll the page so the item sits in the middle of the screen
    function bringIntoView(t, item) {
        var f = flickableOf(item)
        if (!f)
            return
        var y = item.mapToItem(f.contentItem, 0, 0).y
        var target = y + item.height / 2 - f.height / 2
        var lo = f.originY - f.topMargin
        var hi = Math.max(lo, f.originY + f.contentHeight + f.bottomMargin - f.height)
        f.contentY = Math.max(lo, Math.min(hi, target))
        t.wait(50)
    }
    // the dialogs (selection, confirmation) spring in: tap once they are still
    function settleDialogs(t) {
        var ds = [chooser(), find(loader.item, "confirmDialog")]
        for (var i = 0; i < ds.length; i++) {
            var d = ds[i]
            if (!d)
                continue
            if (d.shown)
                t.tryVerify(function () { return d.alpha > 0.99 && Math.abs(d.contentScale - 1) < 0.002 }, 3000,
                            "the dialog has settled")
            else if (d.active)
                t.tryVerify(function () { return !d.active }, 3000, "the dialog has left")
        }
    }
    function tap(t, item) {
        settleDialogs(t)
        // an edge button shows once its list is scrolled to the end
        if (item.hasOwnProperty("preferredHeight") && item.flickable) {
            var ef = item.flickable
            ef.contentY = Math.max(ef.originY - ef.topMargin, ef.originY + ef.contentHeight + ef.bottomMargin - ef.height)
            t.tryVerify(function () { return item.visible }, 3000, "the edge button is revealed")
            t.wait(400)
        }
        bringIntoView(t, item)
        var p = item.mapToItem(harness, item.width / 2, item.height / 2)
        t.mouseClick(harness, p.x, p.y)
        t.wait(50)
    }
    // row i of a ListView, made and scrolled to first
    function listItem(t, list, i) {
        list.positionViewAtIndex(i, ListView.Center)
        t.wait(50)
        var item = list.itemAtIndex(i)
        t.verify(item !== null, "row " + i + " of " + list.objectName)
        return item
    }
    function tapName(t, name) {
        var item = find(current(), name)
        t.verify(item !== null, "no " + name + " on " + current().objectName)
        t.verify(shown(item), name + " is hidden")
        tap(t, item)
        return item
    }
    function back(t) {
        var d = chooser()
        if (d && d.shown) {
            d.pop()
            t.wait(400)
            return
        }
        var n = stack.layers.length
        stack.pop(stack.currentLayer)
        t.compare(stack.layers.length, n - 1)
        t.wait(50)
    }
    function home(t) {
        var d = chooser()
        if (d && d.shown)
            d.pop()
        while (stack.layers.length > 0)
            stack.pop(stack.currentLayer)
        t.wait(50)
    }
    function settle(t) { t.wait(400) }
    function shot(t, name) {
        t.wait(150)
        var img = t.grabImage(screen)
        img.save(shots + "/" + name + ".png")
    }
    // scroll a list that does not fit to its end (false: it fits)
    function scrollToEnd(t) {
        var f = find(current(), "settingsFlickable") || find(current(), "choiceList")
        if (!f)
            return false
        var col = find(current(), "settingsColumn")
        var used = col ? col.y + col.height : f.contentHeight
        if (used <= f.height * 0.9)
            return false
        var hi = f.originY + f.contentHeight + f.bottomMargin - f.height
        f.contentY = hi
        t.wait(100)
        return true
    }
    function confirmDialog() { return find(loader.item, "dialogYes").parent }
}
