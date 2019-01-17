function install_apps {
if [ "$INSTALL_AURMAN" = "1" ]
then
cat << EOB > /tmp/aurman.sh
cd ~
mkdir -p /tmp/aurman_install
cd /tmp/aurman_install
sudo pacman -Sy binutils make gcc fakeroot pkg-config git python python-feedparser python-dateutil python-regex python-requests pyalpm --noconfirm --needed
curl -o PKGBUILD https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=expac-git
makepkg PKGBUILD --skippgpcheck --syncdeps --install --noconfirm --needed
curl -o PKGBUILD https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=aurman
makepkg PKGBUILD --skippgpcheck --syncdeps --install --noconfirm --needed
rm -rf aurman_install
EOB
( su - $ADMIN_USERNAME -c "bash /tmp/aurman.sh" )
rm -r /tmp/aurman.sh

fi
if [ "$INSTALL_GUI" = "1" ]
then
pacman -Sy xorg cinnamon lightdm lightdm-gtk-greeter --noconfirm --needed
cat << EOM > /etc/lightdm/lightdm.conf
[LightDM]
run-directory=/run/lightdm
[Seat:*]
greeter-session=lightdm-gtk-greeter
greeter-hide-users=true
greeter-show-manual-login=true
session-wrapper=/etc/lightdm/Xsession
[XDMCPServer]
[VNCServer]
EOM
systemctl enable lightdm
fi
if [ "$INSTALL_EXTRAAPPS" = "1" ]
then
pacman -Sy $EXTRAAPPS --noconfirm --needed
fi
}
