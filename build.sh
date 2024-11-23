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
	onedrive \
	tailscale \
	https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

### cleanup ###
rm -f /etc/yum.repos.d/tailscale.repo
popd && rm -rf "$tmpdir"
