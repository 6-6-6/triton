# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="MoltenVK is a Vulkan Portability implementation. (binary)"
SRC_URI="https://github.com/KhronosGroup/${PN}/releases/download/v${PV}/${PN}-macos.tar -> ${P}.tar"
HOMEPAGE="https://github.com/KhronosGroup/MoltenVK"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64-macos ~arm64-macos"

IUSE=""

DEPENDSSS="
	dev-libs/cereal
	dev-util/glslang
	dev-util/spirv-headers
	dev-util/spirv-tools
	dev-util/vulkan-headers
"

S="${WORKDIR}/${PN}"

src_compile() {
	sed -i "s#./libMoltenVK.dylib#${EPREFIX}/usr/lib/libMoltenVK.dylib#" MoltenVK/dylib/macOS/MoltenVK_icd.json
	/usr/bin/install_name_tool -change \
		/usr/lib/libc++.1.dylib \
		${EREFIX}/usr/lib/libc++.1.dylib \
		MoltenVK/dylib/macOS/libMoltenVK.dylib || die
	/usr/bin/lipo -thin ${ARCH/-macos/} \
		MoltenVK/dylib/macOS/libMoltenVK.dylib \
		-o MoltenVK/dylib/macOS/libMoltenVK.dylib || die
}

src_install() {
	dodir /usr/share/vulkan/icd.d/
	dosym ../../MoltenVK/icd/MoltenVK_icd.json /usr/share/vulkan/icd.d/MoltenVK_icd.json

	dodir /usr/share/MoltenVK/icd/
	insinto /usr/share/MoltenVK/icd/
	doins MoltenVK/dylib/macOS/MoltenVK_icd.json
	
	dodir /usr/lib
	dolib.so MoltenVK/dylib/macOS/libMoltenVK.dylib

	dodir /usr/include
	insinto /usr/include
	doins -r MoltenVK/include/MoltenVK
}
