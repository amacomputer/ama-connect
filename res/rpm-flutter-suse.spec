Name:       ama-connect
Version:    1.4.6
Release:    0
Summary:    RPM package
License:    GPL-3.0
URL:        https://ama-connect.com
Vendor:     ama-connect <info@ama-connect.com>
Requires:   gtk3 libxcb1 libXfixes3 alsa-utils libXtst6 libva2 pam gstreamer-plugins-base gstreamer-plugin-pipewire
Recommends: libayatana-appindicator3-1 xdotool
Provides:   libdesktop_drop_plugin.so()(64bit), libdesktop_multi_window_plugin.so()(64bit), libfile_selector_linux_plugin.so()(64bit), libflutter_custom_cursor_plugin.so()(64bit), libflutter_linux_gtk.so()(64bit), libscreen_retriever_plugin.so()(64bit), libtray_manager_plugin.so()(64bit), liburl_launcher_linux_plugin.so()(64bit), libwindow_manager_plugin.so()(64bit), libwindow_size_plugin.so()(64bit), libtexture_rgba_renderer_plugin.so()(64bit)

# https://docs.fedoraproject.org/en-US/packaging-guidelines/Scriptlets/

%description
The best open-source remote desktop client software, written in Rust.

%prep
# we have no source, so nothing here

%build
# we have no source, so nothing here

# %global __python %{__python3}

%install

mkdir -p "%{buildroot}/usr/share/ama-connect" && cp -r ${HBB}/flutter/build/linux/x64/release/bundle/* -t "%{buildroot}/usr/share/ama-connect"
mkdir -p "%{buildroot}/usr/bin"
install -Dm 644 $HBB/res/ama-connect.service -t "%{buildroot}/usr/share/ama-connect/files"
install -Dm 644 $HBB/res/ama-connect.desktop -t "%{buildroot}/usr/share/ama-connect/files"
install -Dm 644 $HBB/res/ama-connect-link.desktop -t "%{buildroot}/usr/share/ama-connect/files"
install -Dm 644 $HBB/res/128x128@2x.png "%{buildroot}/usr/share/icons/hicolor/256x256/apps/ama-connect.png"
install -Dm 644 $HBB/res/scalable.svg "%{buildroot}/usr/share/icons/hicolor/scalable/apps/ama-connect.svg"

%files
/usr/share/ama-connect/*
/usr/share/ama-connect/files/ama-connect.service
/usr/share/icons/hicolor/256x256/apps/ama-connect.png
/usr/share/icons/hicolor/scalable/apps/ama-connect.svg
/usr/share/ama-connect/files/ama-connect.desktop
/usr/share/ama-connect/files/ama-connect-link.desktop

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
ln -sf /usr/share/ama-connect/ama-connect /usr/bin/ama-connect
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
    rm /usr/bin/ama-connect || true
    rmdir /usr/lib/ama-connect || true
    rmdir /usr/local/ama-connect || true
    rmdir /usr/share/ama-connect || true
    rm /usr/share/applications/ama-connect.desktop || true
    rm /usr/share/applications/ama-connect-link.desktop || true
    update-desktop-database
  ;;
  1)
    # for upgrade
    rmdir /usr/lib/ama-connect || true
    rmdir /usr/local/ama-connect || true
  ;;
esac
