network --bootproto=dhcp --activate
url --metalink="https://mirrors.fedoraproject.org/metalink?repo=fedora-44&arch=x86_64"
repo --name="updates" --metalink="https://mirrors.fedoraproject.org/metalink?repo=updates-released-f44&arch=x86_64"
# Include official Fedora repositories

# System Configuration
lang en_US.UTF-8
keyboard us
timezone UTC
authselect select minimal
clearpart --all --initlabel
zerombr
bootloader --location=mbr
part / --fstype="ext4" --size=10240 --grow

# ==============================================================================
# PACKAGE SELECTION
# ==============================================================================
%packages
dracut-live
# 1. Base Fedora Server / Core System
@server-product
@core
@standard

# 2. KDE Plasma Desktop Core & Utilities
@kde-desktop
alacritty
ark
dolphin
dolphin-plugins
kdegraphics-thumbnailers
ffmpegthumbs
dragon
filelight
gwenview
kcalc
partitionmanager
kfind
kleopatra
korganizer
krita
kwalletmanager
kmenuedit
okular
spectacle
kinfocenter
plasma-discover-flatpak
sweeper
strawberry

# 3. System Tools & Utilities
btop
btrfs-assistant
bleachbit
gzip
unzip
flatpak
ufw
fish

# 4. Media Creation & Drivers
obs-studio
vlc
mesa-dri-drivers
mesa-vulkan-drivers
gstreamer1-plugins-base
gstreamer1-plugins-good
gstreamer1-plugins-bad-free
gstreamer1-plugins-ugly-free
ffmpeg-free

# 5. Virtualization & Cockpit Admin
virt-manager
libvirt
qemu-kvm
cockpit-networkmanager
cockpit-storaged

# 6. Core Web Browsers
firefox

%end

# ==============================================================================
# POST-INSTALLATION SCRIPT (Flathub & Service Hooks)
# ==============================================================================
%post --erroronfail
# Enable Graphical Systemd Targets & Services
systemctl enable sddm.service
systemctl set-default graphical.target
systemctl enable libvirtd.service
systemctl enable cockpit.socket

# Add Flathub Repository
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Flatpak Desktop Applications
flatpak install -y flathub com.brave.Browser || true
flatpak install -y flathub com.vscodium.codium || true
flatpak install -y flathub org.onlyoffice.desktopeditors || true
flatpak install -y flathub com.spotify.Client || true
flatpak install -y flathub md.obsidian.Obsidian || true
flatpak install -y flathub net.mullvad.MullvadBrowser || true
flatpak install -y flathub com.discordapp.Discord || true
flatpak install -y flathub io.gitlab.librewolf-community || true
flatpak install -y flathub org.sweethome3d.Sweethome3d || true
flatpak install -y flathub org.localsend.localsend_app || true
flatpak install -y flathub org.gnome.Snapshot || true
flatpak install -y flathub com.protonvpn.www || true

%end
