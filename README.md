# AirPods

A KDE Plasma 6 panel widget for AirPods. Battery for each pod and the case, listening mode, adaptive noise, Conversation Awareness, One-Bud ANC, and ear detection, without leaving the desktop.

Same daemon as [omarchy-pods](https://github.com/thisisgm/omarchy-pods). Same card language as [CasaOS Homelab](https://github.com/T3lluz/CasaOSWidget) and [Power Deck](https://github.com/T3lluz/Power-Deck).

![Plasma 6](https://img.shields.io/badge/Plasma-6-blue)
![License](https://img.shields.io/badge/widget-MIT-green)
![Daemon](https://img.shields.io/badge/daemon-GPL--3.0-blue)

## Features

**Panel (always visible, single line)**

- Live connection status dot (pulses while the daemon is down)
- AirPods silhouette that matches the hardware (buds, Pro, or Max)
- Each AirPod as an earbud graphic with its battery percent beside it — not the words Left/Right
- Case battery, or a single headphone row on AirPods Max
- Listening mode when the hardware has one (ANC, Transparency, Adaptive, Off)
- Configurable panel display. Pick any mix of those metrics, then reorder them. Icons + values, values only, or icons only, with optional separators and mini bars
- Scales to whatever width you give the widget on the panel
- Click to open the popup, middle-click to cycle listening mode (configurable), scroll the icon to cycle too

**Popup (click to expand)**

- Header with device name and refresh
- Battery rows: earbud / case / headphone graphic, meter, percent, charging or in-ear hint
- Listening mode list for only the modes the daemon says this unit has
- Adaptive slider while Adaptive is the active mode: 0 = Transparency, 100 = full Noise Cancellation
- Conversation Awareness and One-Bud ANC switches when the model supports them
- Ear detection as three chips (pause when one is out, both are out, or never)

## Requirements

- KDE Plasma **6.0+**
- Qt **6**
- AirPods paired through Plasma's Bluetooth settings
- The librepods daemon in `daemon/`, built and running. Stock librepods and AUR packages will not do. They have no status file and none of the `ca:`, `onebud:`, or `adaptive:` verbs.

**Build packages** for the daemon (names may vary by distro):

- `cmake`, `ninja`, `pkgconf`
- `qt6-connectivity`, `qt6-tools`, `qt6-declarative`
- `libpulse`

**KDE:**

- Plasma 6 (`kpackagetool6`)

## Installation

### One-line install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/T3lluz/FORK-omarchy-pods/main/install.sh | bash
```

The installer clones the repo if needed, registers the widget with `kpackagetool6`, builds the daemon into `~/.local`, enables `librepods.service`, and restarts Plasma. Re-run the same command at any time to upgrade.

Widget only, if the daemon is already running:

```bash
curl -fsSL https://raw.githubusercontent.com/T3lluz/FORK-omarchy-pods/main/install.sh | bash -s -- --skip-daemon
```

### From a local checkout

```bash
git clone https://github.com/T3lluz/FORK-omarchy-pods.git
cd FORK-omarchy-pods
./install.sh
```

### After installing

Add the widget: right-click the panel → **Add Widgets** → search **AirPods**. Stretch it on the panel to whatever width you want. The layout adapts.

Pair the AirPods in Plasma Bluetooth settings, then open the case.

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/T3lluz/FORK-omarchy-pods/main/install.sh | bash -s -- --uninstall
```

Or, from a local checkout:

```bash
./install.sh --uninstall
./install.sh --uninstall --purge
```

`--purge` also deletes `~/.config/AirPodsTrayApp` (device name, `magicAccIRK`, `magicAccEncKey`) and `~/.local/state/librepods`.

## Configuration

Right-click the widget → **Configure AirPods**. The page uses the same card / tile language as Power Deck and CasaOS Homelab:

| Section | What it controls |
|---------|------------------|
| **Connection** | Path to `librepods-ctl`, and how often to re-read the daemon status file. |
| **Appearance** | Monochrome palette + accent swatch, icons+values / values / icons. Battery items always keep their earbud or case graphic. |
| **Panel** | Tap tiles to show or hide status, pair silhouette, name, left AirPod, right AirPod, case, headphones, and mode. Reorder chips with the arrows. |
| **Options** | Dot separators, battery mini-bars, hide when disconnected, low-battery tint. |
| **Behavior** | Middle-click action (cycle listening mode / refresh / nothing). |

Hide when idle is off by default. A widget you just added should stay on the panel until you hide it yourself.

## How it works

The widget never talks to Bluetooth. The daemon writes `$XDG_STATE_HOME/librepods/status.json` when status changes, and removes the file when it stops. The panel re-reads that file and calls `librepods-ctl` only when you change a control.

| Verb | Purpose |
|------|---------|
| `noise:off` `noise:transparency` `noise:adaptive` `noise:anc` | Listening mode |
| `adaptive:N` | Adaptive noise level, 0–100 |
| `ca:on` `ca:off` | Conversation Awareness |
| `onebud:on` `onebud:off` | One-Bud ANC |
| `ear:one` `ear:both` `ear:off` | Ear detection |

A dead daemon disappears the status file. The connection status dot goes red.

## Development

Test in a standalone window:

```bash
plasmawindowed org.fredde.airpods
```

After editing QML:

```bash
kpackagetool6 -t Plasma/Applet -u .
kquitapp6 plasmashell && kstart plasmashell
```

`Model.js` is plain JS, so the parser tests run outside Plasma:

```bash
deno run --allow-read tests/model.test.js
# or: node tests/model.test.js
```

Project layout:

```
metadata.json
install.sh
contents/
  config/          # KCM settings schema (main.xml + config.qml)
  ui/              # QML sources
    main.qml                  # PlasmoidItem entry point
    Theme.qml                 # Centralized colors + metrics
    PodsClient.qml            # Status file + librepods-ctl
    CompactRepresentation.qml # Single-line panel view (reorderable metrics)
    FullRepresentation.qml    # Popup: battery rows, listening modes, adaptive slider
    AnimeChip.qml             # Selectable pill chips
    RogSwitch.qml             # Animated toggle
    MetricIcon.qml            # Canvas-drawn metric / action / earbud icons
    AirPodsIcon.qml           # Hardware silhouette
    Model.js                  # Status parse + verbs
    configGeneral.qml         # KCM page
daemon/                       # GPL-3.0 librepods fork (see daemon/UPSTREAM.md)
tests/model.test.js
```

## Credits

The hard part is not this panel. It is [librepods](https://github.com/kavishdevar/librepods) by Kavish Devar, and GM's [omarchy-pods](https://github.com/thisisgm/omarchy-pods), which published the status file, the extra verbs, and the model map through AirPods Max 2.

The three product outlines in `AirPodsIcon.qml` are Apple's, taken from the chapter navigation on apple.com/airpods. AirPods, AirPods Pro and AirPods Max are trademarks of Apple Inc., which does not sponsor or endorse this plugin. Those outlines are not this project's to license.

## License

Two programs live here, licensed separately because they talk over a state file and a command line.

| Path | License |
|------|---------|
| repository root, the Plasma widget | MIT, [LICENSE](LICENSE) |
| `daemon/`, a modified copy of librepods | GPL-3.0, [daemon/LICENSE](daemon/LICENSE) |

Shipping both in one repository is aggregation, not combination. What was modified, and the upstream commit the daemon was forked from, are recorded in [daemon/UPSTREAM.md](daemon/UPSTREAM.md).
