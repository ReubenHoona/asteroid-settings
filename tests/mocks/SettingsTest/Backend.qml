// Test double for the Settings tests (see tests/tst_settings.qml)
// The watch the mocks stand for: dconf, mce, PulseAudio, BlueZ, connman,
// timedate1, login1, btsyncd. Every write a mock passes on to its backend
// is recorded in calls; reset() puts the defaults back.
pragma Singleton
import QtQuick

QtObject {
    // dconf
    property var conf: ({})
    signal confWritten(string key)
    function confHas(key) { return conf.hasOwnProperty(key) }
    function confGet(key) { return conf[key] }
    function confSet(key, v) {
        conf[key] = v
        record("dconf", key, [v])
        confWritten(key)
    }

    // mce settings (MceConfigValue) and the display
    property var mce: ({})
    signal mceWritten(string key)
    function mceSet(key, v) {
        mce[key] = v
        record("mce", key, [v])
        mceWritten(key)
    }
    property int brightness: 60
    property bool als: true
    property bool lpm: true
    property bool tilt: true
    property bool tiltAvailable: true
    property bool tap: true

    // battery (mce)
    property int batteryPercent: 57
    property int batteryState: 2      // MceBatteryState.Discharging
    property int chargerType: 0       // MceChargerType.None

    // sound (PulseAudio's main volume)
    property int volume: 70
    // how long a mocked ngfd sample plays (Nemo.Ngf NonGraphicalFeedback), ms
    property int sampleMs: 300

    // Bluetooth (BlueZ adapter) and Wi-Fi (connman)
    property bool btPowered: true
    property bool btConnected: true
    property bool wifiPowered: true
    property bool wifiConnected: true
    property var wifiServices: []
    // airplane mode (connman's offline mode)
    property bool offline: false
    // BlueZ: the adapter, the devices ({ path, name, paired, connected, icon,
    // near (heard in a scan), seen (heard in this scan) }), what a pairing does
    property bool btAvailable: true
    property bool btDiscovering: false
    property var btDevices: []
    property bool btPairFails: false
    function btSet(path, props) {
        var all = btDevices.slice()
        for (var i = 0; i < all.length; i++) {
            if (all[i].path === path) {
                var d = JSON.parse(JSON.stringify(all[i]))
                for (var k in props)
                    d[k] = props[k]
                all[i] = d
            }
        }
        btDevices = all
    }
    // the files FileInfo.exists finds, and what connman says to a hidden network
    property var files: ({})
    property string hiddenError: ""

    // time and language
    property string timezone: "Europe/London"
    property var now: new Date(2026, 10, 2, 10, 9, 0)
    property int languageIndex: 1

    // what was asked of the backends: { target, method, args, t (ms) }
    property var calls: []
    function record(target, method, args) {
        var l = calls.slice()
        l.push({ "target": target, "method": method, "args": args || [], "t": Date.now() })
        calls = l
    }
    function find(target, method) {
        for (var i = calls.length - 1; i >= 0; i--)
            if (calls[i].target === target && calls[i].method === method)
                return calls[i]
        return null
    }
    function clearCalls() { calls = [] }

    // the apps of the watch (AppInventory): the entries with a launcher entry,
    // the owner package of each, the installed packages with their versions,
    // the processes that run and the sizes in bytes
    property var inv: ({})
    function defaultInv() {
        return {
            "apps": [
                { "id": "asteroid-alarmclock", "name": "Alarm clock", "exec": "asteroid-alarmclock", "process": "asteroid-alarmclock" },
                { "id": "asteroid-assistant", "name": "Assistant", "exec": "busctl --user call x", "process": "" },
                { "id": "asteroid-settings", "name": "Settings", "exec": "asteroid-settings", "process": "asteroid-settings" },
                { "id": "asteroid-weather", "name": "Weather", "exec": "asteroid-weather", "process": "asteroid-weather" }
            ],
            "owners": { "asteroid-alarmclock": "asteroid-alarmclock", "asteroid-assistant": "asteroid-assistant",
                        "asteroid-settings": "asteroid-settings", "asteroid-weather": "asteroid-weather" },
            "packages": { "asteroid-alarmclock": "1.0-r0", "asteroid-assistant": "1.1-r0", "asteroid-settings": "2.0-r0",
                          "asteroid-weather": "1.2-r0", "asteroid-btsyncd": "2.1-r1", "asteroid-sensorlogd": "1.0-r0",
                          "eos-update": "3.0-r0" },
            "running": { "asteroid-weather": true, "asteroid-settings": true, "asteroid-btsyncd": true },
            "sizes": {
                "asteroid-alarmclock": { "app": 400000, "data": 12000, "cache": 0 },
                "asteroid-assistant": { "app": 8000000, "data": 25000000, "cache": 3000 },
                "asteroid-settings": { "app": 1500000, "data": 2000, "cache": 100000 },
                "asteroid-weather": { "app": 900000, "data": 1500000, "cache": 4200000 }
            },
            "sizeDelay": 0
        }
    }

    // D-Bus replies, "interface.method" -> value
    property var replies: ({})

    function reset() {
        conf = {}
        // the watch today: dim 10 s + blank 5 s, the screen on for 15 s
        mce = { "/system/osso/dsm/display/display_dim_timeout": 10,
                "/system/osso/dsm/display/display_blank_timeout": 5 }
        brightness = 60; als = true; lpm = true; tilt = true; tiltAvailable = true; tap = true
        batteryPercent = 57; batteryState = 2; chargerType = 0
        volume = 70; sampleMs = 300
        btPowered = true; btConnected = true; wifiPowered = true; wifiConnected = true; wifiServices = []
        offline = false; btAvailable = true; btDiscovering = false; btPairFails = false; files = {}; hiddenError = ""
        btDevices = [
            { "path": "/dev/phone", "name": "Pocket phone", "paired": true, "connected": true, "icon": "phone" },
            { "path": "/dev/buds", "name": "Test buds", "paired": true, "connected": false, "icon": "audio-headset" },
            { "path": "/dev/bike", "name": "Gym bike", "paired": false, "connected": false, "icon": "", "near": true },
            { "path": "/dev/speaker", "name": "Desk speaker", "paired": false, "connected": false, "icon": "audio-card", "near": true }
        ]
        timezone = "Europe/London"; languageIndex = 1
        replies = {
            "org.asteroidos.btsyncd.Phone.Connected": true,
            "org.asteroidos.btsyncd.Phone.BatteryLevel": 80,
            "org.freedesktop.timedate1.ListTimezones": ["Africa/Abidjan", "America/New_York", "Europe/Berlin",
                                                        "Europe/London", "Europe/Paris", "Pacific/Auckland", "Zulu"]
        }
        calls = []
        inv = defaultInv()
    }
    Component.onCompleted: reset()
}
