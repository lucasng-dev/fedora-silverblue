#!/bin/bash
set -eux -o pipefail

# prepare
tmpdir=$(mktemp -d) && pushd "$tmpdir"

# helper
rpm-install() {
	local rpm_url=$1
	local opt_dir=$2
	local lib_dir=$3
	local rpm_file && rpm_file=$(basename "$lib_dir").rpm
	mkdir -p /var/opt
	wget -q -O "$rpm_file" "$rpm_url"
	rpm -ivh ./"$rpm_file"
	mv "$opt_dir" "$lib_dir"
	search_dirs=("$lib_dir" /usr/share/{applications,appdata,gnome-control-center/default-apps})
	{ grep -rl "$opt_dir" "${search_dirs[@]}" 2>/dev/null || true; } | xargs sed -i "s|$opt_dir|$lib_dir|g"
}

# tailscale repo: https://pkgs.tailscale.com/stable/fedora/tailscale.repo
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

# 1password repo: https://support.1password.com/install-linux/#fedora-or-red-hat-enterprise-linux
cat >/etc/yum.repos.d/1password.repo <<-"EOF"
	[1password]
	name=1Password Stable Channel
	baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
	enabled=1
	gpgcheck=1
	repo_gpgcheck=1
	gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

# packages
rpm-ostree install --idempotent \
	langpacks-{en,pt} \
	zsh eza bat micro mc \
	fzf fd-find ripgrep ncdu tldr tmux \
	btop htop xclip xsel wl-clipboard \
	iperf3 firewall-config syncthing tailscale \
	distrobox podman{,-compose} docker{,-compose} \
	btrfs-assistant gparted p7zip{,-plugins} cabextract \
	cups-pdf gnome-themes-extra gnome-tweaks tilix \
	wireguard-tools \
	openrgb \
	virt-manager \
	onedrive \
	tailscale 1password-cli \
	liberation-fonts https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

# 1password - https://github.com/btkostner/silverblue/blob/main/scripts/1password.sh
rpm-install https://downloads.1password.com/linux/rpm/stable/x86_64/1password-latest.rpm /opt/1Password /usr/lib/1Password
ln -srf /usr/lib/1Password /usr/bin/1password

# chrome
rpm-install https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm /opt/google/chrome /usr/lib/google-chrome
ln -srf /usr/lib/google-chrome/google-chrome-stable /usr/bin/google-chrome-stable

# edge
rpm-install 'https://go.microsoft.com/fwlink?linkid=2149137' /opt/microsoft/msedge /usr/lib/microsoft-edge
ln -srf /usr/lib/microsoft-edge/microsoft-edge-stable /usr/bin/microsoft-edge-stable

# cleanup
rpm-ostree override remove ublue-os-just just nvtop
rm -f /etc/yum.repos.d/{1password,tailscale,google-chrome,microsoft-edge}.repo

# cleanup
rpm-ostree cleanup -m
popd && rm -rf "$tmpdir"
