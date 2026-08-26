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

    readonly property int edgeMargin: Kirigami.Units.smallSpacing * 1.5
    readonly property int popupWidth: Kirigami.Units.gridUnit * 38
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

    readonly property int popupContentHeight: body.implicitHeight
    Layout.preferredWidth: popupWidth
    Layout.minimumWidth: Kirigami.Units.gridUnit * 32
    Layout.maximumWidth: Kirigami.Units.gridUnit * 44
    Layout.preferredHeight: popupContentHeight
    Layout.minimumHeight: popupContentHeight
    Layout.maximumHeight: popupContentHeight
    implicitHeight: popupContentHeight
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

        RowLayout {
            id: body
            width: parent.width
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                visible: pods.hasBattery
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 7.5
                Layout.maximumWidth: Kirigami.Units.gridUnit * 8.5
                Layout.leftMargin: root.edgeMargin
                Layout.topMargin: root.edgeMargin
                Layout.bottomMargin: root.edgeMargin
                implicitHeight: Kirigami.Units.gridUnit * 22
                radius: Kirigami.Units.smallSpacing * 1.5
                color: Theme.alpha(Kirigami.Theme.textColor, 0.045)
                border.width: 1
                border.color: Theme.alpha(Kirigami.Theme.textColor, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    spacing: 0

                    GaugeRing {
                        visible: pods.isHeadset
                        label: i18n("HEADPHONES")
                        percent: pods.headsetBattery.level === Model.LEVEL_UNKNOWN ? -1 : pods.headsetBattery.level
                        accentColor: pods.batteryColor(pods.headsetBattery.level, pods.headsetBattery.charging)
                        subText: pods.headsetBattery.charging ? i18n("Charging") : ""
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 1
                    }
                    GaugeRing {
                        visible: !pods.isHeadset
                        label: i18n("LEFT")
                        percent: pods.leftPod.level === Model.LEVEL_UNKNOWN ? -1 : pods.leftPod.level
                        accentColor: pods.batteryColor(pods.leftPod.level, pods.leftPod.charging)
                        subText: Model.podMeta(pods.leftPod)
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 1
                    }
                    GaugeRing {
                        visible: !pods.isHeadset
                        label: i18n("RIGHT")
                        percent: pods.rightPod.level === Model.LEVEL_UNKNOWN ? -1 : pods.rightPod.level
                        accentColor: pods.batteryColor(pods.rightPod.level, pods.rightPod.charging)
                        subText: Model.podMeta(pods.rightPod)
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 1
                    }
                    GaugeRing {
                        visible: !pods.isHeadset
                        label: i18n("CASE")
                        percent: pods.caseBattery.level === Model.LEVEL_UNKNOWN ? -1 : pods.caseBattery.level
                        accentColor: pods.batteryColor(pods.caseBattery.level, pods.caseBattery.charging)
                        subText: {
                            var bits = []
                            if (pods.caseBattery.charging)
                                bits.push(i18n("Charging"))
                            if (root.lidLabel.length > 0)
                                bits.push(root.lidLabel)
                            return bits.join(" · ")
                        }
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 1
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: pods.hasBattery ? 0 : root.edgeMargin
                Layout.rightMargin: root.edgeMargin
                Layout.topMargin: root.edgeMargin
                Layout.bottomMargin: root.edgeMargin
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    Layout.fillWidth: true
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
                                font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.25)
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
                    visible: root.modesVisible
                    title: i18n("Listening mode")
                    iconKind: "noise"
                    glyphColor: Theme.noise
                    trailingText: Model.noiseModeName(pods.noiseMode)
                    trailingColor: Theme.accentBright

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Kirigami.Units.smallSpacing
                        rowSpacing: Kirigami.Units.smallSpacing

                        Repeater {
                            model: pods.availableModes()

                            AnimeChip {
                                required property var modelData
                                label: Model.noiseModeName(modelData)
                                isActive: pods.noiseMode === modelData
                                accentColor: Theme.accent
                                onClicked: pods.setNoiseMode(modelData)
                            }
                        }
                    }

                    RowLayout {
                        visible: root.adaptiveVisible
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        PC3.Label {
                            text: i18n("Adaptive noise")
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
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

                        PC3.Label {
                            text: i18n("%1%", pods.adaptiveNoiseLevel)
                            color: Kirigami.Theme.textColor
                            font.weight: Font.DemiBold
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.4
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                SectionCard {
                    visible: root.caVisible || root.oneBudVisible
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
                    Layout.fillWidth: true
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
}
