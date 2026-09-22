```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Debian 13 KDE Daily Driver
#
# Intended for:
#   - Minimal Debian 13 (Trixie)
#   - amd64
#   - Internet connection available
#
# Installs:
#   - KDE Plasma desktop
#   - Selected KDE applications
#   - Daily-driver utilities
#   - Media / graphics software
#   - Virtualization
#   - Networking tools
#
# Intentionally NOT installed:
#   - Steam
#   - VeraCrypt
#   - Flatpak
#   - SDDM
#   - Firefox
#   - UFW
#   - FUSE3
#   - KDE PIM / mail
#   - K3b
#   - KolourPaint
#   - Sweeper
#   - KDE Mobile
#   - non-free-firmware
#   - custom KDE configuration
#
# Run as root:
#   sudo ./install-kde-daily.sh
# ============================================================

export DEBIAN_FRONTEND=noninteractive

# ----------------------------
# Root check
# ----------------------------

if [[ "${EUID}" -ne 0 ]]; then
    echo "ERROR: Run this script as root:"
    echo "  sudo $0"
    exit 1
fi

# ----------------------------
# Basic checks
# ----------------------------

echo "==> Checking operating system..."

if [[ ! -r /etc/os-release ]]; then
    echo "ERROR: Cannot determine operating system."
    exit 1
fi

source /etc/os-release

if [[ "${ID}" != "debian" ]]; then
    echo "ERROR: This script is intended for Debian."
    echo "Detected: ${ID:-unknown}"
    exit 1
fi

if [[ "${VERSION_CODENAME:-}" != "trixie" ]]; then
    echo "WARNING: This script was written for Debian 13 (Trixie)."
    echo "Detected codename: ${VERSION_CODENAME:-unknown}"
    read -r -p "Continue anyway? [y/N] " answer
    [[ "${answer}" =~ ^[Yy]$ ]] || exit 1
fi

ARCH="$(dpkg --print-architecture)"

if [[ "${ARCH}" != "amd64" ]]; then
    echo "ERROR: This script targets amd64."
    echo "Detected architecture: ${ARCH}"
    exit 1
fi

echo "    Debian: ${VERSION_ID:-unknown} (${VERSION_CODENAME:-unknown})"
echo "    Architecture: ${ARCH}"

# ----------------------------
# Configure Debian repositories
# ----------------------------

echo
echo "==> Configuring Debian repositories..."

# Back up existing APT configuration.
BACKUP_DIR="/root/apt-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "${BACKUP_DIR}"

cp -a /etc/apt/sources.list "${BACKUP_DIR}/sources.list" 2>/dev/null || true
cp -a /etc/apt/sources.list.d "${BACKUP_DIR}/sources.list.d" 2>/dev/null || true

# Remove old traditional sources.list if present.
rm -f /etc/apt/sources.list

# Use deb822 format.
cat > /etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: https://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main contrib non-free
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

echo "    Enabled:"
echo "      main"
echo "      contrib"
echo "      non-free"
echo "      trixie"
echo "      trixie-updates"
echo "      trixie-security"
echo
echo "    non-free-firmware was intentionally NOT enabled."

# ----------------------------
# Update package metadata
# ----------------------------

echo
echo "==> Updating APT..."

apt-get update

# ----------------------------
# Package list
# ----------------------------

PACKAGES=(
    # --------------------------------------------------------
    # KDE Plasma
    # --------------------------------------------------------
    kde-plasma-desktop

    # KDE applications
    okular
    dragonplayer
    gwenview
    elisa
    strawberry
    kcalc
    kweather
    kclock
    dolphin-plugins
    kleopatra
    kde-spectacle
    ark
    kdegraphics-thumbnailers
    filelight
    partitionmanager
    krita

    # --------------------------------------------------------
    # System utilities
    # --------------------------------------------------------
    btop
    fastfetch
    btrfs-assistant
    bleachbit
    gzip
    unzip
    fish
    python3
    network-manager
    wget
    curl
    openvpn
    putty

    # --------------------------------------------------------
    # Media / graphics
    # --------------------------------------------------------
    obs-studio
    libgl1-mesa-dri
    mesa-vulkan-drivers
    gstreamer1.0-plugins-base
    gstreamer1.0-plugins-good
    gstreamer1.0-plugins-bad
    gstreamer1.0-plugins-ugly
    ffmpeg

    # --------------------------------------------------------
    # Virtualization
    # --------------------------------------------------------
    virt-manager
    qemu-kvm
    libvirt-daemon-system

    # --------------------------------------------------------
    # Display manager
    #
    # SDDM is intentionally excluded.
    # LightDM provides the graphical login instead.
    # --------------------------------------------------------
    lightdm
    lightdm-gtk-greeter
)

# ----------------------------
# Verify packages exist
# ----------------------------

echo
echo "==> Verifying requested Debian packages..."

MISSING=()

for package in "${PACKAGES[@]}"; do
    if ! apt-cache show "${package}" >/dev/null 2>&1; then
        MISSING+=("${package}")
    fi
done

if (( ${#MISSING[@]} > 0 )); then
    echo
    echo "ERROR: These packages were not found in the configured Debian repositories:"
    printf '  %s\n' "${MISSING[@]}"
    echo
    echo "No installation was attempted."
    exit 1
fi

echo "    All requested packages are available."

# ----------------------------
# Install packages
# ----------------------------

echo
echo "==> Installing KDE and daily-driver packages..."

apt-get install -y \
    --no-install-recommends \
    "${PACKAGES[@]}"

# ----------------------------
# Make LightDM the display manager
# ----------------------------

echo
echo "==> Configuring LightDM..."

# Debian's lightdm package normally handles this through debconf,
# but explicitly selecting it makes the result deterministic.
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager

systemctl enable lightdm.service

# ----------------------------
# Virtualization permissions
# ----------------------------

echo
echo "==> Configuring virtualization permissions..."

# libvirt creates these groups on normal Debian installations.
# group creation may vary depending on exactly which dependencies
# were installed, so only modify groups that exist.

for group in libvirt libvirt-qemu kvm; do
    if getent group "${group}" >/dev/null 2>&1; then
        echo "    Group exists: ${group}"
    fi
done

# Add every regular local user to useful virtualization groups.
while IFS=: read -r username _ uid _ _ home shell; do
    [[ "${uid}" =~ ^[0-9]+$ ]] || continue

    # Normal human users generally start at UID 1000.
    if (( uid >= 1000 && uid < 60000 )); then
        if getent group kvm >/dev/null 2>&1; then
            usermod -aG kvm "${username}" || true
        fi

        if getent group libvirt >/dev/null 2>&1; then
            usermod -aG libvirt "${username}" || true
        fi
    fi
done < /etc/passwd

# ----------------------------
# Enable virtualization daemon
# ----------------------------

echo
echo "==> Enabling libvirt..."

if systemctl list-unit-files libvirtd.service >/dev/null 2>&1; then
    systemctl enable libvirtd.service || true
fi

if systemctl list-unit-files virtlogd.service >/dev/null 2>&1; then
    systemctl enable virtlogd.service || true
fi

# ----------------------------
# Enable NetworkManager
# ----------------------------

echo
echo "==> Enabling NetworkManager..."

if systemctl list-unit-files NetworkManager.service >/dev/null 2>&1; then
    systemctl enable NetworkManager.service || true
fi

# ----------------------------
# Set graphical boot target
# ----------------------------

echo
echo "==> Setting graphical boot target..."

systemctl set-default graphical.target

# ----------------------------
# Remove packages that violate
# our explicit exclusions
# ----------------------------

echo
echo "==> Checking excluded packages..."

EXCLUDED_PACKAGES=(
    steam
    steam-installer
    steam-devices
    veracrypt
    flatpak
    firefox
    firefox-esr
    ufw
    fuse
    fuse3
    kdepim
    kmail
    kontact
    kaddressbook
    korganizer
    k3b
    kolourpaint
    sweeper
    plasma-mobile
    sddm
)

# Only remove packages that are actually installed.
INSTALLED_EXCLUDED=()

for package in "${EXCLUDED_PACKAGES[@]}"; do
    if dpkg-query -W -f='${Status}\n' "${package}" 2>/dev/null | \
        grep -q '^install ok installed$'; then
        INSTALLED_EXCLUDED+=("${package}")
    fi
done

if (( ${#INSTALLED_EXCLUDED[@]} > 0 )); then
    echo "    Removing explicitly excluded packages:"
    printf '      %s\n' "${INSTALLED_EXCLUDED[@]}"

    apt-get purge -y "${INSTALLED_EXCLUDED[@]}"
fi

# ----------------------------
# Cleanup
# ----------------------------

echo
echo "==> Cleaning APT caches..."

apt-get autoremove -y
apt-get autoclean -y

rm -rf /var/lib/apt/lists/*

# Recreate apt lists directory.
mkdir -p /var/lib/apt/lists/partial

# ----------------------------
# Final report
# ----------------------------

echo
echo "============================================================"
echo " Debian 13 KDE Daily Driver installation complete"
echo "============================================================"
echo
echo "Desktop:"
echo "  KDE Plasma"
echo "  LightDM"
echo
echo "Repositories:"
echo "  main"
echo "  contrib"
echo "  non-free"
echo
echo "Intentionally excluded:"
echo "  Steam"
echo "  VeraCrypt"
echo "  Flatpak"
echo "  SDDM"
echo "  Firefox"
echo "  UFW"
echo "  FUSE3"
echo "  KDE PIM / mail"
echo "  K3b"
echo "  KolourPaint"
echo "  Sweeper"
echo "  KDE Mobile"
echo "  non-free-firmware"
echo
echo "A reboot is recommended."
echo

exit 0
```

### Run it

On the minimal Debian installation:

```bash
chmod +x install-kde-daily.sh
sudo ./install-kde-daily.sh
```

Then reboot:

```bash
sudo reboot
```

One deliberate detail: I **didn't enable `non-free-firmware`**, as requested. I also didn't add Flatpak or third-party repositories.

I used `--no-install-recommends` to keep the installation lean. That can make KDE slightly less complete than Debian's default KDE task, but the explicit applications you requested are installed.
