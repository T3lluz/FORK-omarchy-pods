pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import "Model.js" as Model

Item {
    id: root

    required property var pods
    required property var plasmoidItem
    required property string podsVariant

    readonly property var defaultOrder: [
        "status", "icon", "name", "left", "right", "case", "headset", "mode"
    ]
    readonly property var orderedIds: parseOrder(Plasmoid.configuration.metricOrder)

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int displayMode: Plasmoid.configuration.displayMode
    readonly property bool showIcons: displayMode !== 1
    readonly property bool showValues: displayMode !== 2
    readonly property bool sepsOn: Plasmoid.configuration.showSeparators
    readonly property int batLowAt: Plasmoid.configuration.batteryLowPercent

    readonly property bool vStatus: Plasmoid.configuration.showStatusDot
    readonly property bool vIcon: Plasmoid.configuration.showIcon && root.showIcons
    readonly property bool vName: Plasmoid.configuration.showName && root.showValues
        && (pods.modelName.length > 0 || pods.deviceName.length > 0)
    readonly property bool vLeft: Plasmoid.configuration.showLeft && !pods.isHeadset
        && pods.leftPod.level !== Model.LEVEL_UNKNOWN
    readonly property bool vRight: Plasmoid.configuration.showRight && !pods.isHeadset
        && pods.rightPod.level !== Model.LEVEL_UNKNOWN
    readonly property bool vCase: Plasmoid.configuration.showCase && !pods.isHeadset
        && pods.caseBattery.level !== Model.LEVEL_UNKNOWN
    readonly property bool vHeadset: Plasmoid.configuration.showHeadset && pods.isHeadset
        && pods.headsetBattery.level !== Model.LEVEL_UNKNOWN
    readonly property bool vMode: Plasmoid.configuration.showMode && pods.hasAirPods
        && pods.availableModes().length > 0

    readonly property string visStamp: [
        vStatus, vIcon, vName, vLeft, vRight, vCase, vHeadset, vMode
    ].join(",")

    readonly property string dataStamp: [
        pods.daemonReachable, pods.connected, pods.busy,
        pods.deviceName, pods.modelName, pods.isHeadset, pods.isProSeries,
        pods.leftPod.level, pods.leftPod.charging,
        pods.rightPod.level, pods.rightPod.charging,
        pods.caseBattery.level, pods.caseBattery.charging,
        pods.headsetBattery.level, pods.headsetBattery.charging,
        pods.noiseMode, pods.lidState,
        showIcons, showValues, Plasmoid.configuration.batteryWarnLow,
        Plasmoid.configuration.batteryLowPercent
    ].join("|")

    readonly property int panelIconSize: Math.round(
        Math.min(isVertical ? width : height, Kirigami.Units.gridUnit * 2) * 0.92)

    implicitWidth: isVertical
        ? Math.max(Kirigami.Units.gridUnit * 1.75, verticalCol.implicitWidth + Kirigami.Units.smallSpacing * 2)
        : horizontalRow.implicitWidth + Kirigami.Units.largeSpacing * 2
    implicitHeight: isVertical
        ? verticalCol.implicitHeight + Kirigami.Units.smallSpacing * 2
        : Kirigami.Units.gridUnit * 1.75

    Layout.minimumWidth: implicitWidth
    Layout.preferredWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.preferredHeight: implicitHeight

    function parseOrder(raw) {
        var known = {}
        var out = []
        var parts = String(raw || "").split(",")
        for (var i = 0; i < parts.length; i++) {
            var id = parts[i].trim()
            if (defaultOrder.indexOf(id) !== -1 && !known[id]) {
                known[id] = true
                out.push(id)
            }
        }
        for (var j = 0; j < defaultOrder.length; j++) {
            if (!known[defaultOrder[j]])
                out.push(defaultOrder[j])
        }
        return out
    }

    function slotVisible(id) {
        switch (id) {
        case "status": return vStatus
        case "icon": return vIcon
        case "name": return vName
        case "left": return vLeft
        case "right": return vRight
        case "case": return vCase
        case "headset": return vHeadset
        case "mode": return vMode
        }
        return false
    }

    function hasVisibleBefore(index) {
        for (var i = 0; i < index; i++) {
            if (slotVisible(orderedIds[i]))
                return true
        }
        return false
    }

    function slotKind(id) {
        switch (id) {
        case "left": return "leftpod"
        case "right": return "rightpod"
        case "headset": return "headset"
        case "case": return "case"
        case "mode": return "noise"
        }
        return "buds"
    }

    function slotIsBattery(id) {
        return id === "left" || id === "right" || id === "case" || id === "headset"
    }

    function slotText(id, stamp) {
        switch (id) {
        case "left": return Model.levelText(pods.leftPod.level)
        case "right": return Model.levelText(pods.rightPod.level)
        case "case": return Model.levelText(pods.caseBattery.level)
        case "headset": return Model.levelText(pods.headsetBattery.level)
        case "mode": return Model.noiseModeShortName(pods.noiseMode)
        }
        return ""
    }

    function slotTip(id, stamp) {
        switch (id) {
        case "left": return i18n("Left AirPod %1", Model.levelText(pods.leftPod.level))
        case "right": return i18n("Right AirPod %1", Model.levelText(pods.rightPod.level))
        case "case": return i18n("Case %1", Model.levelText(pods.caseBattery.level))
        case "headset": return i18n("Headphones %1", Model.levelText(pods.headsetBattery.level))
        case "mode": return Model.noiseModeName(pods.noiseMode)
        }
        return ""
    }

    function slotCharging(id) {
        switch (id) {
        case "left": return pods.leftPod.charging === true
        case "right": return pods.rightPod.charging === true
        case "case": return pods.caseBattery.charging === true
        case "headset": return pods.headsetBattery.charging === true
        }
        return false
    }

    function slotLevel(id) {
        switch (id) {
        case "left": return pods.leftPod.level
        case "right": return pods.rightPod.level
        case "case": return pods.caseBattery.level
        case "headset": return pods.headsetBattery.level
        }
        return Model.LEVEL_UNKNOWN
    }

    function slotAccent(id, stamp) {
        switch (id) {
        case "left": return batColor(pods.leftPod.level, pods.leftPod.charging, Theme.left)
        case "right": return batColor(pods.rightPod.level, pods.rightPod.charging, Theme.right)
        case "case": return batColor(pods.caseBattery.level, pods.caseBattery.charging, Theme.caseBat)
        case "headset": return batColor(pods.headsetBattery.level, pods.headsetBattery.charging, Theme.headset)
        case "mode": return Theme.noise
        }
        return Kirigami.Theme.textColor
    }

    function slotPercent(id, stamp) {
        var level = slotLevel(id)
        return level === Model.LEVEL_UNKNOWN ? -1 : level
    }

    function batColor(level, charging, fallback) {
        if (charging)
            return Theme.success
        if (Plasmoid.configuration.batteryWarnLow
            && level !== Model.LEVEL_UNKNOWN
            && level <= root.batLowAt)
            return Theme.danger
        return fallback
    }

    function statusColor() {
        if (pods.hasAirPods)
            return Theme.success
        if (pods.daemonReachable)
            return Theme.warning
        return Theme.danger
    }

    function runMiddleAction() {
        switch (Plasmoid.configuration.middleClickAction) {
        case "refresh":
            root.pods.refresh()
            break
        case "none":
            break
        default:
            root.pods.cycleNoiseMode()
        }
    }

    RowLayout {
        id: horizontalRow
        visible: !root.isVertical
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing * 1.5

        Repeater {
            model: root.orderedIds

            delegate: RowLayout {
                id: hSlot
                required property int index
                required property string modelData

                spacing: Kirigami.Units.smallSpacing
                Layout.alignment: Qt.AlignVCenter
                visible: {
                    var _ = root.visStamp
                    return root.slotVisible(hSlot.modelData)
                }

                Sep {
                    show: {
                        var _ = root.visStamp
                        return root.sepsOn && root.hasVisibleBefore(hSlot.index)
                    }
                }

                Rectangle {
                    visible: hSlot.modelData === "status"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    implicitWidth: 8
                    implicitHeight: 8
                    radius: 4
                    color: {
                        var _ = root.dataStamp
                        return root.statusColor()
                    }

                    SequentialAnimation on opacity {
                        running: !root.pods.daemonReachable
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.3; duration: 700 }
                        NumberAnimation { from: 0.3; to: 1; duration: 700 }
                    }
                }

                AirPodsIcon {
                    visible: hSlot.modelData === "icon"
                    iconSize: root.panelIconSize
                    color: {
                        var _ = root.dataStamp
                        return root.pods.hasAirPods ? Kirigami.Theme.textColor : Theme.muted
                    }
                    variant: root.podsVariant
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.panelIconSize
                    Layout.preferredHeight: root.panelIconSize
                }

                Text {
                    visible: hSlot.modelData === "name"
                    text: {
                        var _ = root.dataStamp
                        return root.pods.modelName !== "" ? root.pods.modelName : root.pods.deviceName
                    }
                    color: Kirigami.Theme.textColor
                    font.weight: Font.DemiBold
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    renderType: Text.NativeRendering
                    Layout.alignment: Qt.AlignVCenter
                }

                Metric {
                    visible: hSlot.modelData !== "status"
                        && hSlot.modelData !== "icon"
                        && hSlot.modelData !== "name"
                    kind: root.slotKind(hSlot.modelData)
                    valueText: root.slotText(hSlot.modelData, root.dataStamp)
                    accent: root.slotAccent(hSlot.modelData, root.dataStamp)
                    percent: root.slotPercent(hSlot.modelData, root.dataStamp)
                    charging: root.slotCharging(hSlot.modelData)
                    showIcon: root.showIcons || root.slotIsBattery(hSlot.modelData)
                    showValue: root.showValues
                    tip: root.slotTip(hSlot.modelData, root.dataStamp)
                }
            }
        }
    }

    ColumnLayout {
        id: verticalCol
        visible: root.isVertical
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: root.orderedIds

            delegate: ColumnLayout {
                id: vSlot
                required property int index
                required property string modelData

                spacing: 3
                Layout.alignment: Qt.AlignHCenter
                visible: {
                    var _ = root.visStamp
                    return root.slotVisible(vSlot.modelData)
                }

                Sep {
                    vertical: true
                    show: {
                        var _ = root.visStamp
                        return root.sepsOn && root.hasVisibleBefore(vSlot.index)
                    }
                }

                Rectangle {
                    visible: vSlot.modelData === "status"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    implicitWidth: 8
                    implicitHeight: 8
                    radius: 4
                    color: {
                        var _ = root.dataStamp
                        return root.statusColor()
                    }
                }

                AirPodsIcon {
                    visible: vSlot.modelData === "icon"
                    iconSize: root.panelIconSize
                    color: {
                        var _ = root.dataStamp
                        return root.pods.hasAirPods ? Kirigami.Theme.textColor : Theme.muted
                    }
                    variant: root.podsVariant
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: root.panelIconSize
                    Layout.preferredHeight: root.panelIconSize
                }

                Text {
                    visible: vSlot.modelData === "name"
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        var _ = root.dataStamp
                        return root.pods.modelName !== "" ? root.pods.modelName : root.pods.deviceName
                    }
                    color: Kirigami.Theme.textColor
                    font.weight: Font.DemiBold
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    renderType: Text.NativeRendering
                }

                VMetric {
                    visible: vSlot.modelData !== "status"
                        && vSlot.modelData !== "icon"
                        && vSlot.modelData !== "name"
                    kind: root.slotKind(vSlot.modelData)
                    valueText: root.slotText(vSlot.modelData, root.dataStamp)
                    accent: root.slotAccent(vSlot.modelData, root.dataStamp)
                    charging: root.slotCharging(vSlot.modelData)
                    showIcon: root.showIcons || root.slotIsBattery(vSlot.modelData)
                    showValue: root.showValues
                    tip: root.slotTip(vSlot.modelData, root.dataStamp)
                }
            }
        }
    }

    MouseArea {
        id: clickLayer
        anchors.fill: parent
        z: 1000
        hoverEnabled: false
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        property bool wasExpanded: false

        onPressed: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                mouse.accepted = false
                return
            }
            wasExpanded = root.plasmoidItem.expanded
        }
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                mouse.accepted = false
                return
            }
            if (mouse.button === Qt.MiddleButton) {
                root.runMiddleAction()
                return
            }
            root.plasmoidItem.expanded = !wasExpanded
        }
        onReleased: function(mouse) {
            if (mouse.button === Qt.RightButton)
                mouse.accepted = false
        }
        onWheel: function(wheel) {
            if (wheel.angleDelta.y > 0)
                root.pods.cycleNoiseMode()
            else
                root.pods.cycleNoiseMode()
        }
    }

    component Sep: Rectangle {
        property bool show: false
        property bool vertical: false
        visible: show
        implicitWidth: 3
        implicitHeight: 3
        radius: 1.5
        color: Theme.muted
        Layout.alignment: vertical ? Qt.AlignHCenter : Qt.AlignVCenter
    }

    component Metric: RowLayout {
        id: m
        required property string kind
        required property string valueText
        required property color accent
        property real percent: -1
        property bool charging: false
        property bool showIcon: true
        property bool showValue: true
        property string tip: ""

        Layout.alignment: Qt.AlignVCenter
        spacing: Kirigami.Units.smallSpacing

        MetricIcon {
            visible: m.showIcon
            kind: m.kind
            color: m.accent
            charging: m.charging
            boltColor: Kirigami.Theme.textColor
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: root.panelIconSize
            Layout.preferredHeight: root.panelIconSize
        }

        Text {
            visible: m.showValue
            text: m.valueText
            color: Kirigami.Theme.textColor
            font.weight: Font.DemiBold
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.features: { "tnum": 1 }
            renderType: Text.NativeRendering
        }

        HoverHandler { id: metricHover }
        PC3.ToolTip.visible: metricHover.hovered && m.tip.length > 0
        PC3.ToolTip.delay: 400
        PC3.ToolTip.text: m.tip

        Rectangle {
            visible: Plasmoid.configuration.showMiniBars && m.percent >= 0
            Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
            Layout.preferredHeight: 4
            radius: 2
            color: Theme.alpha(Kirigami.Theme.textColor, 0.12)
            Layout.leftMargin: 2

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, m.percent / 100))
                height: parent.height
                radius: parent.radius
                color: m.accent
                Behavior on width { NumberAnimation { duration: 400; easing.type: Theme.easeOut } }
            }
        }
    }

    component VMetric: ColumnLayout {
        id: vm
        required property string kind
        required property string valueText
        required property color accent
        property bool charging: false
        property bool showIcon: true
        property bool showValue: true
        property string tip: ""

        Layout.alignment: Qt.AlignHCenter
        spacing: 0

        MetricIcon {
            visible: vm.showIcon
            kind: vm.kind
            color: vm.accent
            charging: vm.charging
            boltColor: Kirigami.Theme.textColor
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.panelIconSize
            Layout.preferredHeight: root.panelIconSize
        }
        Text {
            visible: vm.showValue
            Layout.alignment: Qt.AlignHCenter
            text: vm.valueText
            color: Kirigami.Theme.textColor
            font.weight: Font.DemiBold
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.features: { "tnum": 1 }
            renderType: Text.NativeRendering
        }

        HoverHandler { id: vMetricHover }
        PC3.ToolTip.visible: vMetricHover.hovered && vm.tip.length > 0
        PC3.ToolTip.delay: 400
        PC3.ToolTip.text: vm.tip
    }
}
