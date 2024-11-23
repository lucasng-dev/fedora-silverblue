#!/bin/bash
set -eux -o pipefail

### prepare ###
tmpdir=$(mktemp -d) && pushd "$tmpdir"

### extra repos ###
# tailscale: https://pkgs.tailscale.com/stable/fedora/tailscale.repo
cat >/etc/yum.repos.d/tailscale.repo <<-"EOF"
	[tailscale-stable]
	name=Tailscale stable
	baseurl=https://pkgs.tailscale.com/stable/fedora/$basearch
	enabled=1
	type=rpm
	repo_gpgcheck=1
	gpgcheck=1
	gpgkey=https://pkgs.tailscale.com/stable/fedora/repo.gpg
EOF

### packages ###
dnf5 install -y \
	langpacks-{en,pt} \
	zsh eza bat micro mc \
	fzf fd-find ripgrep ncdu tldr tmux \
	btop htop xclip xsel wl-clipboard \
	iperf3 firewall-config syncthing tailscale \
	distrobox podman{,-compose} \
	btrfs-assistant gparted p7zip{,-plugins} cabextract \
	cups-pdf gnome-themes-extra gnome-tweaks tilix \
	wireguard-tools \
	openrgb \
	virt-manager \
	onedrive python3-pyside6 python3-requests \
	tailscale \
	https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

### onedrive ###
git clone https://github.com/bpozdena/OneDriveGUI.git /usr/lib/OneDriveGUI
cat >/usr/share/applications/OneDriveGUI.desktop <<-"EOF"
	[Desktop Entry]
	Type=Application
	StartupNotify=true
	Name=OneDriveGUI
	Comment=A simple GUI for OneDrive Linux client
	Exec=/usr/bin/python3 /usr/lib/OneDriveGUI/src/OneDriveGUI.py
	Icon=/usr/lib/OneDriveGUI/src/resources/images/OneDriveGUI.png
	Categories=Network;Office
EOF

### cleanup ###
rm -rf /etc/yum.repos.d/tailscale.repo /var/log/dnf*
popd && rm -rf "$tmpdir"
