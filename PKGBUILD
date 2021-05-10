## to run the project inside the container:
#  pacur build <target>

targets=(
  "centos"
  "ubuntu"
)
pkgname="service-discover-base"
pkgver="1.10.0"
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
  "https://releases.hashicorp.com/consul/1.10.0-beta2/consul_1.10.0-beta2_linux_amd64.zip"
)

# manually update hash from https://releases.hashicorp.com/consul/${pkgver}/consul_${pkgver}_SHA256SUMS
hashsums=(
  "8ef29f52d95b08d9cd4557d534cb5c035bc91b7dc69ba4324baff21024465470"
)

package() {
  cd "${srcdir}"
  install -D consul -m 0755 "${pkgdir}/usr/bin/consul"
}
