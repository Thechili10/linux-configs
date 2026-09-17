#!/bin/bash

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
sudo snap install sqlmap