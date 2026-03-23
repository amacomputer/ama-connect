Name:       ama-connect
Version:    1.4.6
Release:    0
Summary:    RPM package
License:    GPL-3.0
URL:        https://ama-connect.com
Vendor:     ama-connect <info@ama-connect.com>
Requires:   gtk3 libxcb libXfixes alsa-lib libva2 pam gstreamer1-plugins-base
Recommends: libayatana-appindicator-gtk3 libxdo

# https://docs.fedoraproject.org/en-US/packaging-guidelines/Scriptlets/

%description
The best open-source remote desktop client software, written in Rust.

%prep
# we have no source, so nothing here

%build
# we have no source, so nothing here

%global __python %{__python3}

%install
mkdir -p %{buildroot}/usr/bin/
mkdir -p %{buildroot}/usr/share/ama-connect/
mkdir -p %{buildroot}/usr/share/ama-connect/files/
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps/
mkdir -p %{buildroot}/usr/share/icons/hicolor/scalable/apps/
install -m 755 $HBB/target/release/ama-connect %{buildroot}/usr/bin/ama-connect
install $HBB/libsciter-gtk.so %{buildroot}/usr/share/ama-connect/libsciter-gtk.so
install $HBB/res/ama-connect.service %{buildroot}/usr/share/ama-connect/files/
install $HBB/res/128x128@2x.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/ama-connect.png
install $HBB/res/scalable.svg %{buildroot}/usr/share/icons/hicolor/scalable/apps/ama-connect.svg
install $HBB/res/ama-connect.desktop %{buildroot}/usr/share/ama-connect/files/
install $HBB/res/ama-connect-link.desktop %{buildroot}/usr/share/ama-connect/files/

%files
/usr/bin/ama-connect
/usr/share/ama-connect/libsciter-gtk.so
/usr/share/ama-connect/files/ama-connect.service
/usr/share/icons/hicolor/256x256/apps/ama-connect.png
/usr/share/icons/hicolor/scalable/apps/ama-connect.svg
/usr/share/ama-connect/files/ama-connect.desktop
/usr/share/ama-connect/files/ama-connect-link.desktop
/usr/share/ama-connect/files/__pycache__/*

%changelog
# let's skip this for now

%pre
# can do something for centos7
case "$1" in
  1)
    # for install
  ;;
  2)
    # for upgrade
    systemctl stop ama-connect || true
  ;;
esac

%post
cp /usr/share/ama-connect/files/ama-connect.service /etc/systemd/system/ama-connect.service
cp /usr/share/ama-connect/files/ama-connect.desktop /usr/share/applications/
cp /usr/share/ama-connect/files/ama-connect-link.desktop /usr/share/applications/
systemctl daemon-reload
systemctl enable ama-connect
systemctl start ama-connect
update-desktop-database

%preun
case "$1" in
  0)
    # for uninstall
    systemctl stop ama-connect || true
    systemctl disable ama-connect || true
    rm /etc/systemd/system/ama-connect.service || true
  ;;
  1)
    # for upgrade
  ;;
esac

%postun
case "$1" in
  0)
    # for uninstall
    rm /usr/share/applications/ama-connect.desktop || true
    rm /usr/share/applications/ama-connect-link.desktop || true
    update-desktop-database
  ;;
  1)
    # for upgrade
  ;;
esac
