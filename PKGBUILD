## to run the project inside the container:
#  pacur build <target>

targets=(
  "centos"
  "ubuntu"
)
pkgname="service-discover-base"
pkgver="1.9.2"
pkgrel="1"
pkgdesc="Service discover binary, based on HashiCorp Consul"
pkgdesclong=(
  "Service discover binary, based on HashiCorp Consul"
)
maintainer="New Bacon Monster <newbaconmonster@zextras.com>"
arch="amd64"
license=("MPL-2.0")
section="meta-package"
priority="optional"
url="https://www.zextras.com/"
sources=(
  "https://releases.hashicorp.com/consul/${pkgver}/consul_${pkgver}_linux_amd64.zip"
)
hashsums=(
  "SKIP"
)

package() {
  cd "${srcdir}"
  install -D consul -m 0755 "${pkgdir}/usr/bin/consul"
}
