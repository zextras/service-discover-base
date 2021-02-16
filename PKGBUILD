## to run the project inside the container:
#  pacur build <target>

targets=(
  "centos"
  "ubuntu"
)
pkgname="service-discover-base"
pkgver="1.9.3"
pkgrel="1"
pkgdesc="Service discover binary, based on HashiCorp Consul"
pkgdesclong=(
  "Service discover binary, based on HashiCorp Consul"
)
maintainer="Zextras srl <packages@zextras.com>"
arch="amd64"
license=("MPL-2.0")
section="meta-package"
priority="optional"
url="https://www.zextras.com/"
conflicts=("consul")
sources=(
  "https://releases.hashicorp.com/consul/${pkgver}/consul_${pkgver}_linux_amd64.zip"
)

# manually update hashs from https://releases.hashicorp.com/consul/${pkgver}/consul_${pkgver}_SHA256SUMS
hashsums=(
  "2ec9203bf370ae332f6584f4decc2f25097ec9ef63852cd4ef58fdd27a313577"
)

package() {
  cd "${srcdir}"
  install -D consul -m 0755 "${pkgdir}/usr/bin/consul"
}
