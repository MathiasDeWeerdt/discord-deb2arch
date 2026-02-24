# Maintainer: Mathias <your@email.com>
pkgname=discord-deb2arch
pkgver=1.0.0
pkgrel=1
pkgdesc="Converts Discord's official .deb release into a native Arch package using debtap. The community repo tends to lag behind official releases, so this handles the fetch and install automatically."
arch=('any')
url="https://github.com/YOUR_USERNAME/discord-deb2arch"
license=('MIT')
depends=('wget' 'debtap' 'sudo')
source=("${pkgname}-${pkgver}.tar.gz::${url}/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=('SKIP')

package() {
  cd "${srcdir}/discord-deb2arch-${pkgver}"
  install -Dm755 discord-update.sh "${pkgdir}/usr/local/bin/discord-update"
  install -Dm644 README.md "${pkgdir}/usr/share/doc/${pkgname}/README.md"
}
