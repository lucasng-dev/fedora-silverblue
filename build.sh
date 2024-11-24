#!/bin/bash
set -eux -o pipefail

### prepare ###
tmpdir=$(mktemp -d) && pushd "$tmpdir"
mkdir -p /var/lib/alternatives

### enable repos ###
sed -Ei '0,/^enabled=.*$/s//enabled=1/' /etc/yum.repos.d/rpmfusion-nonfree-steam.repo

### install packages ###
dnf5 install -y \
	langpacks-{en,pt} \
	zsh eza bat micro mc \
	fzf fd-find ripgrep ncdu tldr tmux \
	btop htop xclip xsel wl-clipboard \
	iperf3 firewall-config syncthing \
	distrobox podman{,-compose,-docker,-tui} \
	btrfs-assistant gparted p7zip{,-plugins} cabextract \
	cups-pdf gnome-themes-extra gnome-tweaks tilix \
	wireguard-tools \
	openrgb steam-devices \
	virt-manager \
	onedrive python3-pyside6 python3-requests \
	tailscale 1password-cli \
	https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

### install cloudflared ###
wget -q -O /usr/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x /usr/bin/cloudflared
/usr/bin/cloudflared --version

### install onedrive-gui ###
git clone --branch=main --depth=1 https://github.com/bpozdena/OneDriveGUI.git /usr/lib/OneDriveGUI
rm -rf /usr/lib/OneDriveGUI/.git
ln -s /usr/share/applications/OneDriveGUI.desktop /etc/xdg/autostart/OneDriveGUI.desktop

### configure rpm-ostree ###
sed -Ei '/AutomaticUpdatePolicy=/c\AutomaticUpdatePolicy=stage' /etc/rpm-ostreed.conf >/dev/null
systemctl enable rpm-ostreed-automatic.timer

### configure flatpak ###
(
	git clone --branch=main --depth=1 https://github.com/ublue-os/config.git ublue-config
	for dirname in system{,-preset} user{,-preset}; do
		src="ublue-config/files/usr/lib/systemd/$dirname"
		dest="/usr/lib/systemd/$dirname" && mkdir -p "$dest"
		cp "$src"/*flatpak* "$dest/"
	done
	rm -rf ublue-config
)
systemctl enable flatpak-system-update.timer
systemctl --global enable flatpak-user-update.timer

### configure podman ###
sed -Ei 's|(--filter)|--filter restart-policy=unless-stopped \1|g' /usr/lib/systemd/system/podman-restart.service >/dev/null

### configure ssh ###
systemctl disable sshd.service

### configure virt-manager ###
systemctl enable libvirtd.service

### configure tailscale ###
systemctl enable tailscaled.service

### configure gnome-disk-image-mounter ###
sed -Ei 's|(^Exec=gnome-disk-image-mounter\b)|\1 --writable|g' /usr/share/applications/gnome-disk-image-mounter.desktop

### configure udisks2 ###
udisks2_generate() { echo "$(grep -Eo "\b$1=.+" /etc/udisks2/mount_options.conf.example | tail -n 1),$2"; }
cat >/etc/udisks2/mount_options.conf <<-EOF
	[defaults]
	$(udisks2_generate 'ntfs_defaults' 'dmask=0022,fmask=0133,noatime')
	$(udisks2_generate 'exfat_defaults' 'dmask=0022,fmask=0133,noatime')
	$(udisks2_generate 'vfat_defaults' 'dmask=0022,fmask=0133,noatime')
EOF

### cleanup ###
rm -rf /etc/yum.repos.d/{tailscale,1password}.repo /var/log/dnf*
popd && rm -rf "$tmpdir"

### commit ###
ostree container commit
