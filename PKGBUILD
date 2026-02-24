# Maintainer: Mathias DeWeerdt <your@email.com>
pkgname=discord-deb2arch
pkgver=0.0.126
pkgrel=1
pkgdesc="Discord - All-in-one voice, video and text communication (latest upstream .deb release)"
arch=('x86_64')
url="https://discord.com"
license=('custom')
depends=('gtk3' 'nss' 'libxss' 'alsa-lib' 'libnotify' 'xdg-utils' 'libglvnd')
optdepends=(
  'libappindicator-gtk3: systray support'
  'libayatana-appindicator: systray support'
)
provides=('discord')
conflicts=('discord')
source=("discord-${pkgver}.deb::https://stable.dl2.discordapp.net/apps/linux/${pkgver}/discord-${pkgver}.deb")
sha256sums=('SKIP')

package() {
  cd "${srcdir}"
  ar x "discord-${pkgver}.deb"

  local data_tar
  data_tar=$(find . -maxdepth 1 -name 'data.tar.*' | head -1)
  [[ -n "${data_tar}" ]] || { echo "error: data.tar.* not found in .deb"; exit 1; }
  tar xf "${data_tar}" -C "${pkgdir}"

  install -Dm644 "${pkgdir}/usr/share/discord/resources/LICENSE.html" \
    "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE.html" 2>/dev/null || true
}
