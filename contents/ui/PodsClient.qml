pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support
import "Model.js" as Model

Item {
    id: root

    property string ctlPath: ""
    property int statusPollMs: 800

    property bool daemonReachable: false
    property bool connected: false
    property string deviceName: ""
    property string modelName: ""
    property bool isProSeries: false
    property bool isHeadset: false
    property bool supportsNoiseOff: true
    property bool supportsNoiseControl: true
    property bool supportsAdaptive: false
    property bool supportsConversationalAwareness: false
    property bool supportsOneBudANC: false
    property int noiseMode: Model.NOISE_UNKNOWN
    property int adaptiveNoiseLevel: 0
    property bool oneBudANC: false
    property bool conversationalAwareness: false
    property int earDetectionBehavior: Model.EAR_PAUSE_ONE_OUT
    property int lidState: Model.LID_UNKNOWN
    property bool schemaUnsupported: false
    property var leftPod: Model.defaultPod()
    property var rightPod: Model.defaultPod()
    property var caseBattery: ({ level: Model.LEVEL_UNKNOWN, charging: false })
    property var headsetBattery: ({ level: Model.LEVEL_UNKNOWN, charging: false })
    property string lastError: ""
    property string actionStatus: ""
    property bool busy: false

    readonly property string resolvedCtl: {
        var cfg = String(ctlPath || "").trim()
        if (cfg.length > 0)
            return cfg
        var found = StandardPaths.findExecutable("librepods-ctl")
        if (found && found.toString().length > 0) {
            var loc = found.toString()
            if (loc.indexOf("file://") === 0)
                loc = loc.substring(7)
            return loc
        }
        var home = StandardPaths.writableLocation(StandardPaths.HomeLocation).toString()
        if (home.indexOf("file://") === 0)
            home = home.substring(7)
        return home + "/.local/bin/librepods-ctl"
    }

    readonly property string statePath: {
        var loc = StandardPaths.writableLocation(StandardPaths.GenericStateLocation).toString()
        if (loc.indexOf("file://") === 0)
            loc = loc.substring(7)
        return loc + "/librepods/status.json"
    }

    readonly property bool hasAirPods: daemonReachable && connected
    readonly property bool hasBattery: daemonReachable
        && (isHeadset
            ? headsetBattery.level !== Model.LEVEL_UNKNOWN
            : (leftPod.level !== Model.LEVEL_UNKNOWN
                || rightPod.level !== Model.LEVEL_UNKNOWN
                || caseBattery.level !== Model.LEVEL_UNKNOWN))

    readonly property int settleHoldMs: 4000
    readonly property int actionStatusMs: 2200

    property string _pendingField: ""
    property var _pendingValue: null
    property var _queued: null
    property bool _statusInFlight: false

    function quote(path) {
        return "'" + String(path).replace(/'/g, "'\\''") + "'"
    }

    function refresh() {
        if (_statusInFlight)
            return
        _statusInFlight = true
        statusExec.connectSource("test -r " + quote(statePath)
            + " && cat " + quote(statePath)
            + " || echo __GONE__")
    }

    function applyLine(raw) {
        var text = String(raw || "").trim()
        if (text === "__GONE__") {
            stateGone()
            return
        }
        var status = Model.parseStatus(text)
        if (!status.ok) {
            daemonReachable = true
            connected = false
            schemaUnsupported = status.schemaTooNew
            lastError = status.lastError
            return
        }
        daemonReachable = true
        schemaUnsupported = false
        lastError = ""
        applyStatus(status)
    }

    function stateGone() {
        daemonReachable = false
        connected = false
        schemaUnsupported = false
        lastError = ""
    }

    function applyStatus(status) {
        connected = status.connected
        deviceName = status.deviceName
        modelName = status.modelName
        isProSeries = status.isProSeries
        isHeadset = status.isHeadset
        supportsNoiseOff = status.supportsNoiseOff
        supportsNoiseControl = status.supportsNoiseControl
        supportsAdaptive = status.supportsAdaptive
        supportsConversationalAwareness = status.supportsConversationalAwareness
        supportsOneBudANC = status.supportsOneBudANC
        leftPod = status.left
        rightPod = status.right
        caseBattery = status.caseBattery
        headsetBattery = status.headset
        lidState = status.lidState

        noiseMode = _settle("noiseMode", status.noiseMode)
        adaptiveNoiseLevel = _settle("adaptiveNoiseLevel", status.adaptiveNoiseLevel)
        oneBudANC = _settle("oneBudANC", status.oneBudANC)
        conversationalAwareness = _settle("conversationalAwareness", status.conversationalAwareness)
        earDetectionBehavior = _settle("earDetectionBehavior", status.earDetectionBehavior)
    }

    function _settle(field, reported) {
        if (_pendingField !== field)
            return reported
        if (reported === _pendingValue) {
            _clearPending()
            return reported
        }
        return _pendingValue
    }

    function _clearPending() {
        _pendingField = ""
        _pendingValue = null
        settleTimer.stop()
    }

    function _send(verb, field, optimistic) {
        if (verb === "")
            return
        if (busy) {
            _queued = { verb: verb, field: field, optimistic: optimistic }
            _pendingField = field
            _pendingValue = optimistic
            root[field] = optimistic
            settleTimer.restart()
            return
        }
        _pendingField = field
        _pendingValue = optimistic
        root[field] = optimistic
        settleTimer.restart()
        busy = true
        ctlExec.connectSource(quote(resolvedCtl) + " " + verb)
    }

    function setNoiseMode(mode) {
        if (availableModes().indexOf(mode) < 0)
            return
        _send(Model.noiseModeVerb(mode), "noiseMode", mode)
    }

    function availableModes() {
        return Model.availableModes(supportsNoiseControl, supportsNoiseOff, supportsAdaptive)
    }

    function cycleNoiseMode() {
        if (!hasAirPods)
            return
        var modes = availableModes()
        if (modes.length === 0)
            return
        var at = modes.indexOf(noiseMode)
        setNoiseMode(at < 0 ? modes[0] : modes[(at + 1) % modes.length])
    }

    function setAdaptiveNoiseLevel(level) {
        var clamped = Math.max(0, Math.min(100, Math.round(level)))
        _send("adaptive:" + clamped, "adaptiveNoiseLevel", clamped)
    }

    function setConversationalAwareness(enabled) {
        _send(enabled ? "ca:on" : "ca:off", "conversationalAwareness", enabled)
    }

    function setOneBudANC(enabled) {
        _send(enabled ? "onebud:on" : "onebud:off", "oneBudANC", enabled)
    }

    function setEarDetectionBehavior(behavior) {
        _send(Model.earDetectionVerb(behavior), "earDetectionBehavior", behavior)
    }

    function cycleEarDetection() {
        setEarDetectionBehavior((earDetectionBehavior + 1) % Model.EAR_BEHAVIOR_COUNT)
    }

    function batteryColor(level, charging) {
        if (level === Model.LEVEL_UNKNOWN)
            return Theme.muted
        if (charging)
            return Theme.success
        if (level <= 20)
            return Theme.danger
        if (level <= 40)
            return Theme.warning
        return Theme.success
    }

    Timer {
        id: settleTimer
        interval: root.settleHoldMs
        repeat: false
        onTriggered: {
            root._clearPending()
            root.refresh()
        }
    }

    Timer {
        id: actionStatusTimer
        interval: root.actionStatusMs
        repeat: false
        onTriggered: root.actionStatus = ""
    }

    Timer {
        id: pollTimer
        interval: Math.max(250, root.statusPollMs)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Plasma5Support.DataSource {
        id: statusExec
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            root._statusInFlight = false
            root.applyLine(String(data["stdout"] || ""))
            disconnectSource(sourceName)
        }
    }

    Plasma5Support.DataSource {
        id: ctlExec
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            var stderr = String(data["stderr"] || "")
            var code = data["exit code"]
            root.busy = false
            if (code !== 0) {
                root._clearPending()
                root.refresh()
                root._queued = null
                root.actionStatus = Model.elideError(stderr || "librepods-ctl rejected the command")
                actionStatusTimer.restart()
            }
            disconnectSource(sourceName)
            if (root._queued) {
                var next = root._queued
                root._queued = null
                root._send(next.verb, next.field, next.optimistic)
            }
        }
    }
}
