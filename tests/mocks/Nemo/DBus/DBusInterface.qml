// Test double for the Settings tests (see tests/tst_settings.qml)
// Nemo.DBus' DBusInterface: records each call in Backend.calls (target the
// service, method "interface.method", args the plain values) and answers
// with Backend.replies["interface.method"]
import QtQuick
import SettingsTest

QtObject {
    id: root
    property int bus
    property string service
    property string path
    property string iface
    property bool signalsEnabled: false
    function typedCall(method, args, callback, errorCallback) {
        var plain = []
        if (args)
            for (var i = 0; i < args.length; i++)
                plain.push(args[i] !== null && typeof args[i] === "object" && args[i].hasOwnProperty("value") ? args[i].value : args[i])
        Backend.record(service, iface + "." + method, plain)
        // the launcher's screen lock: a model of the real object (Backend.lockCall)
        if (iface === "org.asteroidos.launcher.Lock") {
            var sig = ""
            for (var j = 0; args && j < args.length; j++)
                sig += (args[j] !== null && typeof args[j] === "object" && args[j].hasOwnProperty("type")) ? args[j].type : "?"
            var sigs = Backend.lockSigs
            sigs[method] = sig
            Backend.lockSigs = sigs
            Backend.lockBus = bus
            if (!Backend.lockAvailable) {
                if (errorCallback)
                    errorCallback("org.freedesktop.DBus.Error.ServiceUnknown", "The name is not owned")
                return
            }
            var answer = Backend.lockCall(method, plain)
            if (callback)
                callback(answer === undefined ? true : answer)
            return
        }
        var reply = Backend.replies[iface + "." + method]
        if (callback)
            callback(reply === undefined ? true : reply)
    }
    function call(method, args, callback, errorCallback) {
        typedCall(method, args, callback, errorCallback)
    }
    // a signal of the lock object reaches the function rc<Signal> of the interface,
    // as Nemo.DBus does for the signals of the introspection XML
    property Connections lockSignals: Connections {
        target: Backend
        function onLockSignal(name, value) {
            if (root.signalsEnabled && root.iface === "org.asteroidos.launcher.Lock") {
                var f = root["rc" + name]
                if (typeof f === "function")
                    f(value)
            }
        }
    }
}
