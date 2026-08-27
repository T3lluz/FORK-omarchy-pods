pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami
import "Model.js" as Model

PlasmaExtras.Representation {
    id: root

    required property var pods
    required property var plasmoidItem
    required property string podsVariant
    required property string displayTitle

    collapseMarginsHint: true

    readonly property int edgeMargin: Kirigami.Units.largeSpacing
    readonly property int popupWidth: Kirigami.Units.gridUnit * 22
    readonly property int adaptiveStepPercent: 5
    readonly property int phraseIntervalMs: 2800
    readonly property var activePhrases: [
        "All gone Pete Tong",
        "Essential Selection",
        "Genius Bar stumped",
        "Warming the decks",
        "Hands in the air",
        "Ibiza incoming",
        "Rinsing the low end",
        "Big tune loading",
        "Cued and counting in",
        "Ecosystem escaped"
    ]
    property int phraseIndex: 0

    readonly property bool adaptiveVisible: pods.hasAirPods && pods.supportsAdaptive
        && pods.noiseMode === Model.NOISE_ADAPTIVE
    readonly property bool modesVisible: pods.hasAirPods && pods.availableModes().length > 0
    readonly property bool caVisible: pods.hasAirPods && pods.supportsConversationalAwareness
    readonly property bool oneBudVisible: pods.hasAirPods && pods.supportsOneBudANC
    readonly property bool guidanceVisible: !pods.hasAirPods && !pods.hasBattery && !pods.schemaUnsupported
    readonly property string lidLabel: Model.lidText(pods.lidState)
    readonly property string heroMeta: pods.hasAirPods ? activePhrases[phraseIndex % activePhrases.length]
        : pods.schemaUnsupported ? i18n("Unsupported status schema")
        : pods.daemonReachable ? i18n("Not connected")
        : i18n("librepods is not running")

    readonly property int popupContentHeight: body.implicitHeight + edgeMargin * 2
    readonly property int popupMaxHeight: Kirigami.Units.gridUnit * 32
    Layout.preferredWidth: popupWidth
    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.maximumWidth: Kirigami.Units.gridUnit * 26
    Layout.preferredHeight: Math.min(popupContentHeight, popupMaxHeight)
    Layout.minimumHeight: Math.min(popupContentHeight, Kirigami.Units.gridUnit * 14)
    Layout.maximumHeight: popupMaxHeight
    implicitHeight: Math.min(popupContentHeight, popupMaxHeight)
    implicitWidth: popupWidth

    Component.onCompleted: pods.refresh()

    Timer {
        interval: root.phraseIntervalMs
        running: root.visible && pods.hasAirPods
        repeat: true
        onTriggered: root.phraseIndex = (root.phraseIndex + 1) % root.activePhrases.length
    }

    component SectionCard: Rectangle {
        id: cardRoot
        default property alias content: inner.data
        property string title: ""
        property string iconKind: ""
        property color glyphColor: Theme.iconHeader
        property string trailingText: ""
        property color trailingColor: Theme.success

        Layout.fillWidth: true
        implicitHeight: cardLayout.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.smallSpacing * 1.5
        color: Theme.alpha(Kirigami.Theme.textColor, 0.045)
        border.width: 1
        border.color: Theme.alpha(Kirigami.Theme.textColor, 0.08)

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                visible: cardRoot.title.length > 0
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                spacing: Kirigami.Units.smallSpacing * 1.5

                MetricIcon {
                    visible: cardRoot.iconKind.length > 0
                    kind: cardRoot.iconKind
                    color: cardRoot.glyphColor
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Math.round(Kirigami.Units.gridUnit * 1.1)
                    Layout.preferredHeight: Layout.preferredWidth
                }

                Text {
                    text: cardRoot.title.toUpperCase()
                    color: Kirigami.Theme.textColor
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.6
                    renderType: Text.NativeRendering
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: cardRoot.trailingText.length > 0
                    text: cardRoot.trailingText
                    color: cardRoot.trailingColor
                    font.weight: Font.Bold
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    renderType: Text.NativeRendering
                }
            }

            ColumnLayout {
                id: inner
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing
            }
        }
    }

    component HeaderButton: Rectangle {
        id: hb
        required property string kind
        property string tip: ""
        property color accent: Kirigami.Theme.textColor
        signal clicked()

        Layout.preferredWidth: Kirigami.Units.iconSizes.medium + 6
        Layout.preferredHeight: Kirigami.Units.iconSizes.medium + 6
        radius: Kirigami.Units.smallSpacing * 1.25
        color: hbArea.containsMouse ? Theme.alpha(Kirigami.Theme.textColor, 0.07) : "transparent"
        border.width: 1
        border.color: hbArea.containsMouse ? Theme.alpha(Kirigami.Theme.textColor, 0.12) : "transparent"
        scale: hbArea.pressed ? 0.94 : 1.0

        Behavior on color { ColorAnimation { duration: Theme.durFast; easing.type: Theme.easeOut } }
        Behavior on scale { NumberAnimation { duration: Theme.durFast; easing.type: Theme.easeOut } }

        MetricIcon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.small
            height: width
            kind: hb.kind
            color: hbArea.containsMouse ? hb.accent : Kirigami.Theme.disabledTextColor
        }

        MouseArea {
            id: hbArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hb.clicked()
        }

        PC3.ToolTip.visible: hbArea.containsMouse && hb.tip.length > 0
        PC3.ToolTip.delay: 400
        PC3.ToolTip.text: hb.tip
    }

    component BatteryRow: RowLayout {
        id: brow
        required property string kind
        required property var pod
        required property color accent
        property string meta: ""
        property string tip: ""

        readonly property string metaText: meta !== "" ? meta : Model.podMeta(pod)
        readonly property bool dimmed: kind !== "case" && kind !== "headset"
            && pod.inEar === false && !pod.charging

        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        opacity: dimmed ? 0.55 : 1.0
        Behavior on opacity { NumberAnimation { duration: Theme.durMed; easing.type: Theme.easeOut } }

        MetricIcon {
            kind: brow.kind
            color: brow.accent
            charging: brow.pod.charging === true
            boltColor: Kirigami.Theme.textColor
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
            Layout.preferredHeight: Layout.preferredWidth
        }

        Rectangle {
            id: meterTrack
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            Layout.alignment: Qt.AlignVCenter
            radius: 3
            color: Theme.alpha(Kirigami.Theme.textColor, 0.12)

            Rectangle {
                width: meterTrack.width * Model.levelFraction(brow.pod.level)
                height: parent.height
                radius: parent.radius
                color: brow.accent
                Behavior on width { NumberAnimation { duration: 400; easing.type: Theme.easeOut } }
            }
        }

        Text {
            text: Model.levelText(brow.pod.level)
            color: Kirigami.Theme.textColor
            font.weight: Font.DemiBold
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            font.features: { "tnum": 1 }
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.4
            renderType: Text.NativeRendering
        }

        Text {
            text: brow.metaText
            visible: brow.metaText.length > 0
            color: Theme.muted
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
            elide: Text.ElideRight
            Layout.preferredWidth: Kirigami.Units.gridUnit * 4.2
            renderType: Text.NativeRendering
        }

        HoverHandler { id: batHover }
        PC3.ToolTip.visible: batHover.hovered && brow.tip.length > 0
        PC3.ToolTip.delay: 400
        PC3.ToolTip.text: brow.tip
    }

    component ModeRow: Rectangle {
        id: modeRow
        required property int mode

        readonly property bool selected: pods.noiseMode === mode

        Layout.fillWidth: true
        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.85
        radius: Kirigami.Units.smallSpacing
        color: modeArea.containsMouse || selected
            ? Theme.alpha(Theme.accent, selected ? 0.18 : 0.08)
            : "transparent"
        border.width: selected ? 1 : 0
        border.color: Theme.alpha(Theme.accent, 0.45)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.smallSpacing * 1.2
            anchors.rightMargin: Kirigami.Units.smallSpacing * 1.2
            spacing: Kirigami.Units.smallSpacing

            Text {
                Layout.fillWidth: true
                text: Model.noiseModeName(modeRow.mode)
                color: Kirigami.Theme.textColor
                opacity: modeRow.selected ? 1.0 : 0.78
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize + 1
                font.weight: modeRow.selected ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }

            Text {
                text: "✓"
                color: Theme.accent
                visible: modeRow.selected
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }
        }

        MouseArea {
            id: modeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pods.setNoiseMode(modeRow.mode)
        }
    }

    Rectangle {
        id: toast
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Kirigami.Units.largeSpacing
        z: 99
        radius: Kirigami.Units.smallSpacing * 1.5
        color: Kirigami.Theme.backgroundColor
        border.color: Theme.alpha(Theme.red, 0.45)
        border.width: 1
        opacity: pods.actionStatus !== "" || (pods.lastError !== "" && pods.daemonReachable) ? 1 : 0
        visible: opacity > 0
        implicitWidth: toastLabel.implicitWidth + Kirigami.Units.largeSpacing * 2
        implicitHeight: toastLabel.implicitHeight + Kirigami.Units.smallSpacing * 2

        Text {
            id: toastLabel
            anchors.centerIn: parent
            text: pods.actionStatus !== "" ? pods.actionStatus : pods.lastError
            color: Theme.red
            font.weight: Font.DemiBold
            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            renderType: Text.NativeRendering
        }

        Behavior on opacity { NumberAnimation { duration: Theme.durMed } }
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        ColumnLayout {
            id: body
            width: parent.width
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: root.edgeMargin
                Layout.rightMargin: root.edgeMargin
                Layout.topMargin: root.edgeMargin
                implicitHeight: headerRow.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.smallSpacing * 1.5
                color: Theme.alpha(Kirigami.Theme.textColor, 0.045)
                border.width: 1
                border.color: Theme.alpha(Kirigami.Theme.textColor, 0.08)

                RowLayout {
                    id: headerRow
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing * 1.5

                    Item {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium + 8
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium + 8

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Theme.alpha(Kirigami.Theme.textColor, 0.07)
                            border.width: 2
                            border.color: pods.hasAirPods ? Theme.success
                                : (pods.daemonReachable ? Theme.warning : Theme.danger)
                            Behavior on border.color { ColorAnimation { duration: Theme.durMed; easing.type: Theme.easeOut } }
                        }
                        AirPodsIcon {
                            anchors.centerIn: parent
                            iconSize: Kirigami.Units.iconSizes.medium
                            color: pods.hasAirPods ? Kirigami.Theme.textColor : Theme.muted
                            variant: root.podsVariant
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: i18n("AIRPODS")
                            color: Theme.muted
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                            font.weight: Font.DemiBold
                            font.letterSpacing: 2.2
                            renderType: Text.NativeRendering
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.displayTitle
                            color: Kirigami.Theme.textColor
                            font.weight: Font.Bold
                            font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.2)
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.heroMeta
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            elide: Text.ElideRight
                            renderType: Text.NativeRendering
                        }
                    }

                    HeaderButton {
                        kind: "refresh"
                        tip: i18n("Refresh")
                        accent: Theme.iconRefresh
                        onClicked: pods.refresh()
                    }
                }
            }

            SectionCard {
                visible: pods.hasBattery
                Layout.leftMargin: root.edgeMargin
                Layout.rightMargin: root.edgeMargin
                title: i18n("Battery")
                iconKind: "battery"
                glyphColor: Theme.caseBat

                BatteryRow {
                    visible: pods.isHeadset
                    kind: "headset"
                    pod: pods.headsetBattery
                    accent: pods.batteryColor(pods.headsetBattery.level, pods.headsetBattery.charging)
                    tip: i18n("Headphones %1", Model.levelText(pods.headsetBattery.level))
                }
                BatteryRow {
                    visible: !pods.isHeadset
                    kind: "leftpod"
                    pod: pods.leftPod
                    accent: pods.batteryColor(pods.leftPod.level, pods.leftPod.charging)
                    tip: i18n("Left AirPod %1", Model.levelText(pods.leftPod.level))
                }
                BatteryRow {
                    visible: !pods.isHeadset
                    kind: "rightpod"
                    pod: pods.rightPod
                    accent: pods.batteryColor(pods.rightPod.level, pods.rightPod.charging)
                    tip: i18n("Right AirPod %1", Model.levelText(pods.rightPod.level))
                }
                BatteryRow {
                    visible: !pods.isHeadset
                    kind: "case"
                    pod: pods.caseBattery
                    accent: pods.batteryColor(pods.caseBattery.level, pods.caseBattery.charging)
                    meta: {
                        var bits = []
                        if (pods.caseBattery.charging)
                            bits.push(i18n("Charging"))
                        if (root.lidLabel.length > 0)
                            bits.push(root.lidLabel)
                        return bits.join(" · ")
                    }
                    tip: i18n("Case %1", Model.levelText(pods.caseBattery.level))
                }
            }

            SectionCard {
                visible: root.modesVisible
                Layout.leftMargin: root.edgeMargin
                Layout.rightMargin: root.edgeMargin
                title: i18n("Listening mode")
                iconKind: "noise"
                glyphColor: Theme.noise
                trailingText: Model.noiseModeName(pods.noiseMode)
                trailingColor: Theme.accentBright

                Repeater {
                    model: pods.availableModes()

                    ModeRow {
                        required property var modelData
                        mode: modelData
                    }
                }

                ColumnLayout {
                    visible: root.adaptiveVisible
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing * 0.6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Text {
                            text: i18n("Transparency")
                            color: Theme.muted
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            renderType: Text.NativeRendering
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: i18n("%1%", pods.adaptiveNoiseLevel)
                            color: Kirigami.Theme.textColor
                            font.weight: Font.DemiBold
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            font.features: { "tnum": 1 }
                            renderType: Text.NativeRendering
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: i18n("Noise Cancellation")
                            color: Theme.muted
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            renderType: Text.NativeRendering
                        }
                    }

                    PC3.Slider {
                        Layout.fillWidth: true
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.highlightColor: Theme.accent
                        from: 0
                        to: 100
                        stepSize: root.adaptiveStepPercent
                        snapMode: PC3.Slider.SnapAlways
                        value: pods.adaptiveNoiseLevel
                        onMoved: pods.setAdaptiveNoiseLevel(Math.round(value))
                    }

                    Text {
                        Layout.fillWidth: true
                        text: i18n("0 lets outside sound in. 100 is full noise cancelling.")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                        wrapMode: Text.WordWrap
                        renderType: Text.NativeRendering
                    }
                }
            }

            SectionCard {
                visible: root.caVisible || root.oneBudVisible
                Layout.leftMargin: root.edgeMargin
                Layout.rightMargin: root.edgeMargin
                title: i18n("Controls")
                iconKind: "ear"
                glyphColor: Theme.ear

                RowLayout {
                    visible: root.caVisible
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        PC3.Label {
                            Layout.fillWidth: true
                            text: i18n("Conversation Awareness")
                            color: Kirigami.Theme.textColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            elide: Text.ElideRight
                        }
                        PC3.Label {
                            Layout.fillWidth: true
                            text: i18n("Lower the volume when you start talking")
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                            elide: Text.ElideRight
                        }
                    }

                    RogSwitch {
                        checked: pods.conversationalAwareness
                        onToggled: function(checked) { pods.setConversationalAwareness(checked) }
                    }
                }

                RowLayout {
                    visible: root.oneBudVisible
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        PC3.Label {
                            Layout.fillWidth: true
                            text: i18n("One-Bud ANC")
                            color: Kirigami.Theme.textColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            elide: Text.ElideRight
                        }
                        PC3.Label {
                            Layout.fillWidth: true
                            text: i18n("Keep noise cancellation on with one pod in")
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                            elide: Text.ElideRight
                        }
                    }

                    RogSwitch {
                        checked: pods.oneBudANC
                        onToggled: function(checked) { pods.setOneBudANC(checked) }
                    }
                }
            }

            SectionCard {
                visible: pods.hasAirPods
                Layout.leftMargin: root.edgeMargin
                Layout.rightMargin: root.edgeMargin
                title: i18n("Ear detection")
                iconKind: "ear"
                glyphColor: Theme.iconKbd
                trailingText: Model.earDetectionName(pods.earDetectionBehavior)
                trailingColor: Theme.muted

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    AnimeChip {
                        label: i18n("One out")
                        isActive: pods.earDetectionBehavior === Model.EAR_PAUSE_ONE_OUT
                        onClicked: pods.setEarDetectionBehavior(Model.EAR_PAUSE_ONE_OUT)
                    }
                    AnimeChip {
                        label: i18n("Both out")
                        isActive: pods.earDetectionBehavior === Model.EAR_PAUSE_BOTH_OUT
                        onClicked: pods.setEarDetectionBehavior(Model.EAR_PAUSE_BOTH_OUT)
                    }
                    AnimeChip {
                        label: i18n("Never pause")
                        isActive: pods.earDetectionBehavior === Model.EAR_DISABLED
                        onClicked: pods.setEarDetectionBehavior(Model.EAR_DISABLED)
                    }
                }
            }

            SectionCard {
                visible: root.guidanceVisible
                Layout.leftMargin: root.edgeMargin
                Layout.rightMargin: root.edgeMargin
                Layout.bottomMargin: root.edgeMargin
                title: i18n("Waiting")
                iconKind: "status"
                glyphColor: Theme.warning

                PC3.Label {
                    Layout.fillWidth: true
                    text: pods.daemonReachable
                        ? i18n("Open the case or connect your AirPods to see battery and listening controls.")
                        : i18n("Start the librepods daemon to see battery and listening controls. Run install.sh from this repo if it is not built yet.")
                    color: Kirigami.Theme.disabledTextColor
                    wrapMode: Text.WordWrap
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                }
            }

            PC3.Label {
                visible: !root.guidanceVisible
                Layout.fillWidth: true
                Layout.leftMargin: root.edgeMargin
                Layout.rightMargin: root.edgeMargin
                Layout.bottomMargin: root.edgeMargin
                text: i18n("Scroll the panel icon to cycle listening mode")
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                opacity: 0.5
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }
    }
}
