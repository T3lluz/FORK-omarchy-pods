#!/usr/bin/env bash
# AirPods for Plasma. Installer / uninstaller.
#
# Install from a cloned repo:   ./install.sh
# Install from the network:     curl -fsSL https://raw.githubusercontent.com/T3lluz/FORK-omarchy-pods/main/install.sh | bash
# Widget only:                  ./install.sh --skip-daemon
# Uninstall:                    curl -fsSL https://raw.githubusercontent.com/T3lluz/FORK-omarchy-pods/main/install.sh | bash -s -- --uninstall
# Uninstall + pairing state:    ./install.sh --uninstall --purge
set -euo pipefail

APPLET_ID="org.fredde.airpods"
APPLET_NAME="AirPods"
REPO_URL="${AIRPODS_REPO:-https://github.com/T3lluz/FORK-omarchy-pods.git}"
REPO_BRANCH="main"
TARGET="${HOME}/.local/share/plasma/plasmoids/${APPLET_ID}"

ACTION="install"
SKIP_DAEMON=0
PURGE=0
for arg in "$@"; do
    case "$arg" in
        --uninstall|uninstall|--remove|remove) ACTION="uninstall" ;;
        --skip-daemon) SKIP_DAEMON=1 ;;
        --purge) PURGE=1 ;;
        --help|-h)
            cat <<EOF
Usage: install.sh [--uninstall] [--purge] [--skip-daemon]

  install.sh                     Install or upgrade the widget and daemon.
  install.sh --skip-daemon       Install the widget only.
  install.sh --uninstall         Remove the widget and stop librepods.
  install.sh --uninstall --purge Also delete pairing secrets and the status file.
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $arg (try --help)" >&2
            exit 1
            ;;
    esac
done

# ---------- visuals ----------
if [ -t 1 ]; then
    C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
    C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
    C_CYAN=$'\033[36m'; C_MAGENTA=$'\033[35m'
else
    C_RESET=""; C_BOLD=""; C_DIM=""
    C_GREEN=""; C_YELLOW=""; C_RED=""; C_CYAN=""; C_MAGENTA=""
fi

LOG_FILE="$(mktemp /tmp/airpods-plasma-install.XXXXXX.log)"
WARNINGS=()
CLEANUP_DIR=""

banner() {
    printf '\n'
    printf '%s\n' "${C_MAGENTA}${C_BOLD}  ░█▀█░▀█▀░█▀▄░█▀█░█▀█░█▀▄░█▀▀${C_RESET}"
    printf '%s\n' "${C_MAGENTA}${C_BOLD}  ░█▀█░░█░░█▀▄░█▀▀░█░█░█░█░▀▀█${C_RESET}"
    printf '%s\n' "${C_MAGENTA}${C_BOLD}  ░▀░▀░▀▀▀░▀░▀░▀░░░▀▀▀░▀▀░░▀▀▀${C_RESET}"
    printf '%s\n\n' "${C_DIM}  AirPods battery and listening controls for KDE Plasma 6${C_RESET}"
}

section() { printf '\n%s\n' "${C_CYAN}${C_BOLD}── $1 ──${C_RESET}"; }
step()    { printf '  %s %-46s' "${C_DIM}▸${C_RESET}" "$1"; }
ok()      { printf '%s\n' "${C_GREEN}✓${C_RESET}"; }
skipped() { printf '%s\n' "${C_DIM}skipped${C_RESET}"; }
failed()  { printf '%s\n' "${C_RED}✗${C_RESET}"; }
warn() {
    printf '%s\n' "${C_YELLOW}!${C_RESET}"
    WARNINGS+=("$1")
}

die() {
    printf '\n  %s %s\n' "${C_RED}${C_BOLD}error:${C_RESET}" "$1" >&2
    printf '  %s\n\n' "${C_DIM}full log: ${LOG_FILE}${C_RESET}" >&2
    exit 1
}

run() { "$@" >>"$LOG_FILE" 2>&1; }

cleanup() {
    if [ -n "$CLEANUP_DIR" ]; then
        rm -rf "$CLEANUP_DIR"
    fi
}
trap cleanup EXIT

banner

restart_plasma() {
    step "Restarting Plasma shell"
    if run systemctl --user try-restart plasma-plasmashell.service; then
        ok
    elif command -v kquitapp6 >/dev/null 2>&1; then
        run kquitapp6 plasmashell || true
        (setsid plasmashell >>"$LOG_FILE" 2>&1 &)
        ok
    else
        warn "could not restart plasmashell. Log out and back in."
    fi
}

print_warnings() {
    if [ "${#WARNINGS[@]}" -gt 0 ]; then
        printf '\n%s\n' "${C_YELLOW}${C_BOLD}  Warnings:${C_RESET}"
        for w in "${WARNINGS[@]}"; do
            printf '  %s %s\n' "${C_YELLOW}•${C_RESET}" "$w"
        done
    fi
}

kpackagetool_bin() {
    if command -v kpackagetool6 >/dev/null 2>&1; then
        echo kpackagetool6
    elif command -v kpackagetool5 >/dev/null 2>&1; then
        echo kpackagetool5
    else
        echo ""
    fi
}

# ---------- uninstall ----------
if [ "$ACTION" = "uninstall" ]; then
    KPT="$(kpackagetool_bin)"

    section "Stopping services"
    step "librepods.service"
    run systemctl --user disable --now librepods.service || true
    ok

    section "Removing files"

    step "Plasma widget (${APPLET_ID})"
    if [ -z "$KPT" ]; then
        warn "kpackagetool not found, skipped package unregister"
    elif ! "$KPT" -t Plasma/Applet -l 2>/dev/null | grep -qx "$APPLET_ID"; then
        skipped
    elif run "$KPT" -t Plasma/Applet -r "$APPLET_ID"; then
        ok
    else
        warn "widget removal failed. Remove it from the panel first, then re-run."
    fi

    step "Widget files"
    if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
        rm -rf "$TARGET"
        ok
    else
        skipped
    fi

    step "librepods binaries"
    rm -f "${HOME}/.local/bin/librepods" "${HOME}/.local/bin/librepods-ctl"
    rm -f "${HOME}/.local/share/systemd/user/librepods.service"
    run systemctl --user daemon-reload || true
    ok

    step "Pairing state"
    if [ "$PURGE" -eq 1 ]; then
        rm -rf "${HOME}/.config/AirPodsTrayApp" "${HOME}/.local/state/librepods"
        ok
    else
        skipped
        WARNINGS+=("pairing secrets kept in ~/.config/AirPodsTrayApp. Pass --purge to delete them.")
    fi

    section "Finishing up"
    restart_plasma

    printf '\n%s\n' "${C_GREEN}${C_BOLD}  AirPods widget removed.${C_RESET}"
    print_warnings
    printf '\n  %s\n\n' "${C_DIM}Log: ${LOG_FILE}${C_RESET}"
    exit 0
fi

# ---------- locate or fetch the repo ----------
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_SOURCE" ] && [ -f "$SCRIPT_SOURCE" ] \
   && [ -f "$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)/metadata.json" ] \
   && [ -d "$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)/contents" ]; then
    REPO_ROOT="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
elif [ -f "$PWD/metadata.json" ] && [ -d "$PWD/contents" ]; then
    REPO_ROOT="$PWD"
else
    section "Fetching ${APPLET_NAME}"
    command -v git >/dev/null 2>&1 || die "git is required to download ${APPLET_NAME}."
    CLEANUP_DIR="$(mktemp -d /tmp/airpods-plasma.XXXXXX)"
    step "Cloning ${REPO_URL}"
    run git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$CLEANUP_DIR/repo" \
        || die "git clone failed"
    ok
    REPO_ROOT="$CLEANUP_DIR/repo"
fi

# ---------- dependency check ----------
section "Checking dependencies"

require() {
    step "$1"
    if command -v "$1" >/dev/null 2>&1; then ok; else
        failed
        die "'$1' not found. Install it first (see README requirements)."
    fi
}

recommend() {
    step "$1"
    if command -v "$1" >/dev/null 2>&1; then ok; else
        warn "'$1' not found. $2"
    fi
}

KPT="$(kpackagetool_bin)"
if [ -z "$KPT" ]; then
    die "kpackagetool6 not found. Install plasma-sdk (or kf6-kpackage)."
fi
require "$KPT"
require systemctl

if [ "$SKIP_DAEMON" -eq 0 ]; then
    recommend cmake      "the librepods daemon will not be built"
    recommend ninja      "the librepods daemon will not be built"
    recommend pkg-config "the librepods daemon will not be built"
fi

# ---------- widget ----------
section "Installing files"

step "Plasma widget (${APPLET_ID})"
if [ -L "$TARGET" ] && [ ! -e "$TARGET" ]; then
    rm -f "$TARGET"
fi

STAGE="$(mktemp -d /tmp/airpods-plasmoid.XXXXXX)"
cp "$REPO_ROOT/metadata.json" "$STAGE/"
cp -a "$REPO_ROOT/contents" "$STAGE/"

if "$KPT" -t Plasma/Applet -l 2>/dev/null | grep -qx "$APPLET_ID"; then
    run "$KPT" -t Plasma/Applet -u "$STAGE" || die "widget upgrade failed"
else
    run "$KPT" -t Plasma/Applet -i "$STAGE" || die "widget install failed"
fi
rm -rf "$STAGE"
ok

# ---------- daemon ----------
if [ "$SKIP_DAEMON" -eq 1 ]; then
    section "librepods daemon"
    step "Build skipped (--skip-daemon)"
    skipped
elif [ ! -f "$REPO_ROOT/daemon/CMakeLists.txt" ]; then
    section "librepods daemon"
    step "daemon/ sources"
    warn "daemon/ is missing from this checkout"
elif ! command -v cmake >/dev/null 2>&1 || ! command -v ninja >/dev/null 2>&1; then
    section "librepods daemon"
    step "Build tools"
    warn "install cmake ninja pkgconf qt6-connectivity qt6-tools qt6-declarative libpulse, then re-run without --skip-daemon"
else
    section "Building librepods"
    DAEMON="$REPO_ROOT/daemon"

    step "cmake configure"
    if run cmake -S "$DAEMON" -B "$DAEMON/build" -G Ninja -DBUILD_TESTING=OFF; then
        ok
    else
        warn "cmake configure failed. Widget is installed, daemon is not. See ${LOG_FILE}"
        DAEMON=""
    fi

    if [ -n "$DAEMON" ]; then
        step "cmake build"
        if run cmake --build "$DAEMON/build"; then
            ok
        else
            warn "cmake build failed. Widget is installed, daemon is not. See ${LOG_FILE}"
            DAEMON=""
        fi
    fi

    if [ -n "$DAEMON" ]; then
        step "cmake install -> ~/.local"
        if run cmake --install "$DAEMON/build" --prefix "${HOME}/.local"; then
            ok
        else
            warn "cmake install failed. See ${LOG_FILE}"
            DAEMON=""
        fi
    fi

    if [ -n "$DAEMON" ]; then
        step "librepods.service"
        run systemctl --user daemon-reload || true
        if run systemctl --user enable librepods.service && run systemctl --user restart librepods.service; then
            ok
        else
            warn "could not enable librepods.service (check: systemctl --user status librepods.service)"
        fi
    fi
fi

# ---------- restart plasma ----------
section "Finishing up"
restart_plasma

# ---------- summary ----------
printf '\n%s\n' "${C_GREEN}${C_BOLD}  AirPods widget installed successfully.${C_RESET}"
print_warnings

cat <<EOF

  ${C_BOLD}Next step:${C_RESET} add the widget to your panel
    right-click panel → Add Widgets → search "${C_BOLD}${APPLET_NAME}${C_RESET}"

  Pair AirPods in Plasma Bluetooth settings, then open the case.

  ${C_DIM}Install log: ${LOG_FILE}${C_RESET}

EOF
