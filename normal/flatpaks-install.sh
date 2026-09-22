#!/bin/bash

# Add Flathub Repository
sudo apt-get install flatpak -y
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Flatpak Desktop Applications
sudo flatpak install -y flathub com.brave.Browser || true
sudo flatpak install -y flathub com.vscodium.codium || true
sudo flatpak install -y flathub org.onlyoffice.desktopeditors || true
sudo flatpak install -y flathub com.spotify.Client || true
sudo flatpak install -y flathub md.obsidian.Obsidian || true
sudo flatpak install -y flathub net.mullvad.MullvadBrowser || true
sudo flatpak install -y flathub com.discordapp.Discord || true
sudo flatpak install -y flathub io.gitlab.librewolf-community || true
sudo flatpak install -y flathub org.sweethome3d.Sweethome3d || true
sudo flatpak install -y flathub org.localsend.localsend_app || true