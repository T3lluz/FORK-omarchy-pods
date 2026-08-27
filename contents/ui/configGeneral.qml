import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_ctlPath: ctlPathField.text
    property alias cfg_statusPollMs: pollSpin.value

    property int cfg_displayMode
    property bool cfg_showStatusDot
    property bool cfg_showIcon
    property bool cfg_showName
    property bool cfg_showLeft
    property bool cfg_showRight
    property bool cfg_showCase
    property bool cfg_showHeadset
    property bool cfg_showMode
    property bool cfg_showMiniBars
    property bool cfg_showSeparators
    property bool cfg_hideWhenDisconnected
    property bool cfg_batteryWarnLow
    property int cfg_batteryLowPercent
    property string cfg_metricOrder
    property bool cfg_monochrome
    property int cfg_monoAccent
    property string cfg_middleClickAction

    readonly property var defaultOrder: [
        "status", "icon", "name", "left", "right", "case", "headset", "mode"
    ]

    readonly property var metricCatalog: [
        { id: "status",  label: i18n("Status dot"),     shortLabel: i18n("Status"), kind: "status",   tint: "#34d399" },
        { id: "icon",    label: i18n("Pair silhouette"),shortLabel: i18n("Pair"),   kind: "buds",     tint: "#7d93f0" },
        { id: "name",    label: i18n("Device name"),    shortLabel: i18n("Name"),   kind: "text",     tint: "#56b6f0" },
        { id: "left",    label: i18n("Left AirPod"),    shortLabel: i18n("L"),      kind: "leftpod",  tint: "#60a5fa" },
        { id: "right",   label: i18n("Right AirPod"),   shortLabel: i18n("R"),      kind: "rightpod", tint: "#a78bfa" },
        { id: "case",    label: i18n("Case"),           shortLabel: i18n("Case"),   kind: "case",     tint: "#34d399" },
        { id: "headset", label: i18n("Headphones (Max)"),shortLabel: i18n("Max"),   kind: "headset",  tint: "#22d3ee" },
        { id: "mode",    label: i18n("Listening mode"), shortLabel: i18n("Mode"),   kind: "noise",    tint: "#7d93f0" }
    ]

    readonly property var panelCatalog: [
        { id: "status",  label: i18n("Status dot"),      kind: "status",   tint: "#34d399" },
        { id: "icon",    label: i18n("Pair silhouette"), kind: "buds",     tint: "#7d93f0" },
        { id: "name",    label: i18n("Device name"),     kind: "text",     tint: "#56b6f0" },
        { id: "left",    label: i18n("Left AirPod"),     kind: "leftpod",  tint: "#60a5fa" },
        { id: "right",   label: i18n("Right AirPod"),    kind: "rightpod", tint: "#a78bfa" },
        { id: "case",    label: i18n("Case"),            kind: "case",     tint: "#34d399" },
        { id: "headset", label: i18n("Headphones (Max)"),kind: "headset",  tint: "#22d3ee" },
        { id: "mode",    label: i18n("Listening mode"),  kind: "noise",    tint: "#7d93f0" }
    ]

    readonly property var extraCatalog: [
        { id: "separators", label: i18n("Dot separators"),      kind: "dots",     tint: "#9aa7bd" },
        { id: "bars",       label: i18n("Battery mini-bars"),   kind: "bars",     tint: "#7d93f0" },
        { id: "hide",       label: i18n("Hide when disconnected"), kind: "hide", tint: "#f2596a" },
        { id: "lowWarn",    label: i18n("Tint when battery is low"), kind: "battery", tint: "#f4b73d" }
    ]

    readonly property color muted: "#9aa7bd"
    readonly property color accent: "#7d93f0"

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    readonly property var accentOptions: [
        { name: i18n("White"),  color: "#e6e9ef" },
        { name: i18n("Green"),  color: "#34d399" },
        { name: i18n("Teal"),   color: "#2dd4bf" },
        { name: i18n("Orange"), color: "#fb923c" },
        { name: i18n("Red"),    color: "#f2596a" },
        { name: i18n("Blue"),   color: "#56b6f0" },
        { name: i18n("Purple"), color: "#a78bfa" }
    ]

    property bool writingOrder: false

    readonly property string showStamp: [
        cfg_showStatusDot, cfg_showIcon, cfg_showName, cfg_showLeft, cfg_showRight,
        cfg_showCase, cfg_showHeadset, cfg_showMode, cfg_showSeparators,
        cfg_showMiniBars, cfg_hideWhenDisconnected, cfg_batteryWarnLow, cfg_monochrome
    ].join(",")

    ListModel { id: orderModel }

    function parseOrder(raw) {
        var known = {}
        var out = []
        var parts = String(raw || "").split(",")
        for (var i = 0; i < parts.length; i++) {
            var id = parts[i].trim()
            if (root.defaultOrder.indexOf(id) !== -1 && !known[id]) {
                known[id] = true
                out.push(id)
            }
        }
        for (var j = 0; j < root.defaultOrder.length; j++) {
            if (!known[root.defaultOrder[j]])
                out.push(root.defaultOrder[j])
        }
        return out
    }

    function reloadModel() {
        if (root.writingOrder)
            return
        orderModel.clear()
        var ids = parseOrder(root.cfg_metricOrder)
        for (var i = 0; i < ids.length; i++)
            orderModel.append({ mid: ids[i] })
    }

    function writeOrder() {
        var ids = []
        for (var i = 0; i < orderModel.count; i++)
            ids.push(orderModel.get(i).mid)
        root.writingOrder = true
        root.cfg_metricOrder = ids.join(",")
        root.writingOrder = false
    }

    function moveItem(index, dir) {
        var dest = index + dir
        if (dest < 0 || dest >= orderModel.count)
            return
        orderModel.move(index, dest, 1)
        writeOrder()
    }

    function catalogEntry(id) {
        for (var i = 0; i < root.metricCatalog.length; i++) {
            if (root.metricCatalog[i].id === id)
                return root.metricCatalog[i]
        }
        return { id: id, label: id, shortLabel: id, kind: "buds", tint: "#9aa7bd" }
    }

    function showFor(id) {
        switch (id) {
        case "status": return root.cfg_showStatusDot
        case "icon": return root.cfg_showIcon
        case "name": return root.cfg_showName
        case "left": return root.cfg_showLeft
        case "right": return root.cfg_showRight
        case "case": return root.cfg_showCase
        case "headset": return root.cfg_showHeadset
        case "mode": return root.cfg_showMode
        case "separators": return root.cfg_showSeparators
        case "bars": return root.cfg_showMiniBars
        case "hide": return root.cfg_hideWhenDisconnected
        case "lowWarn": return root.cfg_batteryWarnLow
        }
        return false
    }

    function setShow(id, on) {
        switch (id) {
        case "status": root.cfg_showStatusDot = on; break
        case "icon": root.cfg_showIcon = on; break
        case "name": root.cfg_showName = on; break
        case "left": root.cfg_showLeft = on; break
        case "right": root.cfg_showRight = on; break
        case "case": root.cfg_showCase = on; break
        case "headset": root.cfg_showHeadset = on; break
        case "mode": root.cfg_showMode = on; break
        case "separators": root.cfg_showSeparators = on; break
        case "bars": root.cfg_showMiniBars = on; break
        case "hide": root.cfg_hideWhenDisconnected = on; break
        case "lowWarn": root.cfg_batteryWarnLow = on; break
        }
    }

    onCfg_metricOrderChanged: reloadModel()
    Component.onCompleted: reloadModel()

    component SectionCard: Rectangle {
        id: card
        default property alias content: inner.data
        property string title

        Layout.fillWidth: true
        implicitHeight: head.implicitHeight + inner.implicitHeight + Kirigami.Units.largeSpacing * 2.5
        radius: Kirigami.Units.smallSpacing * 1.5
        color: root.alpha(Kirigami.Theme.textColor, 0.04)
        border.width: 1
        border.color: root.alpha(Kirigami.Theme.textColor, 0.08)

        QQC2.Label {
            id: head
            x: Kirigami.Units.largeSpacing
            y: Kirigami.Units.largeSpacing
            width: parent.width - Kirigami.Units.largeSpacing * 2
            text: card.title
            color: root.muted
            font.weight: Font.DemiBold
            font.letterSpacing: 1.4
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        }

        ColumnLayout {
            id: inner
            x: Kirigami.Units.largeSpacing
            y: head.y + head.implicitHeight + Kirigami.Units.smallSpacing * 1.5
            width: parent.width - Kirigami.Units.largeSpacing * 2
            spacing: Kirigami.Units.smallSpacing * 1.5
        }
    }

    component FieldLabel: QQC2.Label {
        Layout.fillWidth: true
        color: root.muted
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
        font.weight: Font.DemiBold
    }

    component ToggleTile: Rectangle {
        id: tile

        property string mid
        property string label
        property string kind
        property color accent
        readonly property bool on: {
            var _ = root.showStamp
            return root.showFor(tile.mid)
        }

        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 4.4
        radius: Kirigami.Units.smallSpacing * 1.4
        color: on ? root.alpha(accent, 0.16) : root.alpha(Kirigami.Theme.textColor, 0.035)
        border.width: on ? 2 : 1
        border.color: on ? root.alpha(accent, 0.55)
                         : root.alpha(Kirigami.Theme.textColor, 0.10)

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.smallSpacing * 2
            spacing: Kirigami.Units.smallSpacing * 0.6

            MetricIcon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                kind: tile.kind
                color: tile.on ? tile.accent : root.muted
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: tile.label
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.weight: tile.on ? Font.DemiBold : Font.Normal
                color: tile.on ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            }
        }

        HoverHandler { id: tileHover }
        TapHandler { onTapped: root.setShow(tile.mid, !tile.on) }

        QQC2.ToolTip.visible: tileHover.hovered
        QQC2.ToolTip.text: tile.on ? i18n("On") : i18n("Off")
    }

    component ChoiceTile: Rectangle {
        id: choice

        property bool selected: false
        property string label
        property string kind
        property color accent: root.accent
        signal picked

        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 3.6
        radius: Kirigami.Units.smallSpacing * 1.4
        color: selected ? root.alpha(accent, 0.16) : root.alpha(Kirigami.Theme.textColor, 0.035)
        border.width: selected ? 2 : 1
        border.color: selected ? root.alpha(accent, 0.55)
                               : root.alpha(Kirigami.Theme.textColor, 0.10)

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing * 0.5

            MetricIcon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                kind: choice.kind
                color: choice.selected ? choice.accent : root.muted
            }

            QQC2.Label {
                text: choice.label
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                font.weight: choice.selected ? Font.DemiBold : Font.Normal
                color: choice.selected ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            }
        }

        TapHandler { onTapped: choice.picked() }
    }

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        SectionCard {
            title: i18n("CONNECTION")

            FieldLabel { text: i18n("Path to librepods-ctl") }
            QQC2.TextField {
                id: ctlPathField
                Layout.fillWidth: true
                placeholderText: i18n("Leave empty to use PATH, then ~/.local/bin")
            }
            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("The widget reads $XDG_STATE_HOME/librepods/status.json and sends commands through librepods-ctl. Build the daemon with install.sh.")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }

            FieldLabel { text: i18n("Status refresh interval") }
            QQC2.SpinBox {
                id: pollSpin
                Layout.fillWidth: true
                from: 250
                to: 5000
                stepSize: 50
                textFromValue: function(value, locale) { return i18n("%1 ms", value) }
                valueFromText: function(text, locale) {
                    var n = parseInt(text.replace(/[^0-9]/g, ""), 10)
                    return isNaN(n) ? root.cfg_statusPollMs : n
                }
            }
            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("How often to re-read the daemon status file. 800 ms is enough for battery.")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }
        }

        SectionCard {
            title: i18n("APPEARANCE")

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                MetricIcon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    kind: "bars"
                    color: root.cfg_monochrome ? root.accentOptions[root.cfg_monoAccent].color : root.accent
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    text: i18n("Monochrome palette")
                    font.weight: Font.DemiBold
                }

                QQC2.Switch {
                    checked: root.cfg_monochrome
                    onToggled: root.cfg_monochrome = checked
                }
            }

            FieldLabel { text: i18n("Accent") }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing * 1.2
                opacity: root.cfg_monochrome ? 1.0 : 0.55

                Repeater {
                    model: root.accentOptions

                    delegate: Rectangle {
                        required property int index
                        required property var modelData

                        readonly property bool selected: root.cfg_monoAccent === index

                        implicitWidth: Kirigami.Units.gridUnit * 1.7
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: modelData.color
                        border.width: selected ? 3 : 1
                        border.color: selected
                            ? Kirigami.Theme.textColor
                            : Qt.rgba(Kirigami.Theme.textColor.r,
                                      Kirigami.Theme.textColor.g,
                                      Kirigami.Theme.textColor.b, 0.28)

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: parent.width * 0.5
                            height: width
                            source: "checkmark"
                            visible: parent.selected
                            color: index === 0 ? "#222428" : "#ffffff"
                            isMask: true
                        }

                        QQC2.ToolTip.visible: swatchHover.hovered
                        QQC2.ToolTip.text: modelData.name
                        HoverHandler { id: swatchHover }
                        TapHandler { onTapped: root.cfg_monoAccent = index }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            QQC2.Label {
                Layout.fillWidth: true
                visible: root.cfg_monochrome
                text: i18n("White stays fully neutral. A hue tints the active controls and panel glyphs.")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }

            FieldLabel {
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: i18n("Display style")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                ChoiceTile {
                    label: i18n("Icons + values")
                    kind: "both"
                    selected: root.cfg_displayMode === 0
                    onPicked: root.cfg_displayMode = 0
                }
                ChoiceTile {
                    label: i18n("Values only")
                    kind: "text"
                    selected: root.cfg_displayMode === 1
                    onPicked: root.cfg_displayMode = 1
                }
                ChoiceTile {
                    label: i18n("Icons only")
                    kind: "buds"
                    selected: root.cfg_displayMode === 2
                    onPicked: root.cfg_displayMode = 2
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Battery items always keep their earbud or case graphic so left and right stay distinct. This style only changes percentages, mini-bars, and the listening-mode label.")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }
        }

        SectionCard {
            title: i18n("PANEL")

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Left and right AirPods show as earbud graphics with the battery percent beside them — not the words Left or Right.")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.panelCatalog

                    ToggleTile {
                        required property var modelData
                        mid: modelData.id
                        label: modelData.label
                        kind: modelData.kind
                        accent: modelData.tint
                    }
                }
            }

            FieldLabel {
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: i18n("Order on the panel")
            }

            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: orderModel

                    delegate: Rectangle {
                        readonly property int rowIndex: index
                        readonly property string mid: model.mid
                        readonly property var entry: root.catalogEntry(mid)
                        readonly property bool on: {
                            var _ = root.showStamp
                            return root.showFor(mid)
                        }

                        implicitHeight: Kirigami.Units.gridUnit * 1.85
                        implicitWidth: chipRow.implicitWidth + Kirigami.Units.smallSpacing * 1.6
                        radius: height / 2
                        opacity: on ? 1.0 : 0.45
                        color: on ? root.alpha(entry.tint, 0.16)
                                  : root.alpha(Kirigami.Theme.textColor, 0.04)
                        border.width: 1
                        border.color: on ? root.alpha(entry.tint, 0.4)
                                         : root.alpha(Kirigami.Theme.textColor, 0.10)

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 0

                            QQC2.ToolButton {
                                icon.name: "go-previous"
                                enabled: rowIndex > 0
                                implicitWidth: Kirigami.Units.gridUnit * 1.3
                                implicitHeight: implicitWidth
                                display: QQC2.AbstractButton.IconOnly
                                QQC2.ToolTip.text: i18n("Move left")
                                QQC2.ToolTip.visible: hovered
                                onClicked: root.moveItem(rowIndex, -1)
                            }

                            MetricIcon {
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                kind: entry.kind
                                color: on ? entry.tint : root.muted
                            }

                            QQC2.Label {
                                text: entry.shortLabel
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                font.weight: Font.DemiBold
                                leftPadding: Kirigami.Units.smallSpacing * 0.6
                            }

                            QQC2.ToolButton {
                                icon.name: "go-next"
                                enabled: rowIndex < orderModel.count - 1
                                implicitWidth: Kirigami.Units.gridUnit * 1.3
                                implicitHeight: implicitWidth
                                display: QQC2.AbstractButton.IconOnly
                                QQC2.ToolTip.text: i18n("Move right")
                                QQC2.ToolTip.visible: hovered
                                onClicked: root.moveItem(rowIndex, 1)
                            }
                        }
                    }
                }
            }

            QQC2.Button {
                text: i18n("Reset order")
                onClicked: {
                    root.cfg_metricOrder = root.defaultOrder.join(",")
                    root.reloadModel()
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Tap a tile to show or hide it. Left, right and case hide themselves on AirPods Max. Headphones hide themselves on buds. Missing readings hide themselves.")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }
        }

        SectionCard {
            title: i18n("OPTIONS")

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.extraCatalog

                    ToggleTile {
                        required property var modelData
                        mid: modelData.id
                        label: modelData.label
                        kind: modelData.kind
                        accent: modelData.tint
                    }
                }
            }

            FieldLabel { text: i18n("Low battery at") }
            QQC2.SpinBox {
                Layout.fillWidth: true
                from: 5
                to: 60
                stepSize: 5
                value: root.cfg_batteryLowPercent
                onValueModified: root.cfg_batteryLowPercent = value
                textFromValue: function(value, locale) { return i18n("%1%", value) }
                valueFromText: function(text, locale) {
                    var n = parseInt(text.replace(/[^0-9]/g, ""), 10)
                    return isNaN(n) ? root.cfg_batteryLowPercent : n
                }
            }
            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Mini-bars draw a thin charge meter next to each percentage. Hide when disconnected removes the widget from the panel until AirPods reconnect.")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }
        }

        SectionCard {
            title: i18n("BEHAVIOR")

            FieldLabel { text: i18n("Middle-click action") }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                ChoiceTile {
                    label: i18n("Cycle listening mode")
                    kind: "noise"
                    selected: root.cfg_middleClickAction === "cycle"
                    onPicked: root.cfg_middleClickAction = "cycle"
                }
                ChoiceTile {
                    label: i18n("Refresh status")
                    kind: "refresh"
                    selected: root.cfg_middleClickAction === "refresh"
                    onPicked: root.cfg_middleClickAction = "refresh"
                }
                ChoiceTile {
                    label: i18n("Nothing")
                    kind: "dots"
                    selected: root.cfg_middleClickAction === "none"
                    onPicked: root.cfg_middleClickAction = "none"
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Left click opens the popup. Scroll the panel icon to cycle listening mode. Right click stays Plasma's widget menu.")
                color: Kirigami.Theme.disabledTextColor
                font: Kirigami.Theme.smallFont
                wrapMode: Text.WordWrap
            }
        }
    }
}
