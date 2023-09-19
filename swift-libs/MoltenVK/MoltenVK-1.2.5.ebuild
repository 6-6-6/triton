# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="MoltenVK is a Vulkan Portability implementation. (binary)"
SRC_URI="https://github.com/KhronosGroup/${PN}/releases/download/v${PV}/${PN}-macos.tar -> ${P}.tar"
HOMEPAGE="https://github.com/KhronosGroup/MoltenVK"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64-macos ~arm64-macos"

IUSE="only-vulkan"

DEPEND="
	only-vulkan? (
		!media-libs/vulkan-loader
	)
	dev-util/vulkan-headers
"

S="${WORKDIR}/${PN}"

src_compile() {
	# adjust icd
	sed -i "s#./libMoltenVK.dylib#${EPREFIX}/usr/lib/libMoltenVK.dylib#" MoltenVK/dylib/macOS/MoltenVK_icd.json || die
	sed -i "s#portability_driver\" : true#portability_driver\" : false#" MoltenVK/dylib/macOS/MoltenVK_icd.json || die
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
	dolib.so "${FILESDIR}"/libMoltenVK.dylib
	#dolib.so MoltenVK/dylib/macOS/libMoltenVK.dylib

	dodir /usr/include
	insinto /usr/include
	doins -r MoltenVK/include/MoltenVK

	if use only-vulkan; then
		dodir /usr/lib/pkgconfig/
		insinto /usr/lib/pkgconfig/
		doins "${FILESDIR}"/vulkan.pc
	fi
}
