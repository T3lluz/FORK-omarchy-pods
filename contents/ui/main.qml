pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "Model.js" as Model

PlasmoidItem {
    id: root

    readonly property alias pods: podsImpl
    readonly property string podsVariant: pods.isHeadset ? "max" : pods.isProSeries ? "pro" : "buds"
    readonly property string displayTitle: pods.modelName !== ""
        ? pods.modelName
        : (pods.deviceName !== "" ? pods.deviceName : i18n("AirPods"))

    Plasmoid.icon: "audio-headphones"
    Plasmoid.title: displayTitle
    Plasmoid.status: {
        if (!Plasmoid.configuration.hideWhenDisconnected)
            return PlasmaCore.Types.ActiveStatus
        if (pods.hasAirPods || pods.hasBattery)
            return PlasmaCore.Types.ActiveStatus
        return PlasmaCore.Types.HiddenStatus
    }

    toolTipMainText: displayTitle
    toolTipSubText: {
        if (!pods.daemonReachable)
            return i18n("librepods is not running")
        if (pods.schemaUnsupported)
            return pods.lastError
        if (!pods.hasAirPods && !pods.hasBattery)
            return i18n("Not connected")
        if (pods.isHeadset)
            return i18n("Headphones %1  ·  %2",
                Model.levelText(pods.headsetBattery.level),
                Model.noiseModeName(pods.noiseMode))
        var bits = []
        if (pods.leftPod.level !== Model.LEVEL_UNKNOWN)
            bits.push(i18n("L %1", Model.levelText(pods.leftPod.level)))
        if (pods.rightPod.level !== Model.LEVEL_UNKNOWN)
            bits.push(i18n("R %1", Model.levelText(pods.rightPod.level)))
        if (pods.caseBattery.level !== Model.LEVEL_UNKNOWN)
            bits.push(i18n("Case %1", Model.levelText(pods.caseBattery.level)))
        if (pods.hasAirPods && pods.availableModes().length > 0)
            bits.push(Model.noiseModeName(pods.noiseMode))
        return bits.join("  ·  ")
    }

    preferredRepresentation: compactRepresentation
    switchWidth: -1
    switchHeight: -1

    Binding { target: Theme; property: "monochrome"; value: Plasmoid.configuration.monochrome }
    Binding { target: Theme; property: "accentChoice"; value: Plasmoid.configuration.monoAccent }

    PodsClient {
        id: podsImpl
        ctlPath: Plasmoid.configuration.ctlPath
        statusPollMs: Plasmoid.configuration.statusPollMs
    }

    compactRepresentation: CompactRepresentation {
        pods: root.pods
        plasmoidItem: root
        podsVariant: root.podsVariant
    }

    fullRepresentation: FullRepresentation {
        pods: root.pods
        plasmoidItem: root
        podsVariant: root.podsVariant
        displayTitle: root.displayTitle
    }
}
