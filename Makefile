RELEASE=4.4

PACKAGE=lxc-pve
LXCVER=2.0.7
DEBREL=2

SRCDIR=lxc
SRCTAR=${SRCDIR}.tgz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEBS=					\
${PACKAGE}_${LXCVER}-${DEBREL}_${ARCH}.deb  			\
${PACKAGE}-dev_${LXCVER}-${DEBREL}_${ARCH}.deb  			\
${PACKAGE}-dbg_${LXCVER}-${DEBREL}_${ARCH}.deb

all: ${DEBS}
	echo ${DEBS}

.PHONY: deb
deb: ${DEBS}
${DEBS}: ${SRCTAR}
	rm -rf ${SRCDIR}
	tar xf ${SRCTAR}
	cp -a debian ${SRCDIR}/debian
	echo "git clone git://git.proxmox.com/git/lxc.git\\ngit checkout ${GITVERSION}" >  ${SRCDIR}/debian/SOURCE
	cd ${SRCDIR}; dpkg-buildpackage -rfakeroot -b -us -uc
	lintian ${DEBS}


.PHONY: download
download ${SRCTAR}:
	rm -rf ${SRCDIR} ${SRCTAR}
	git clone -b lxc-${LXCVER} git://github.com/lxc/lxc
	tar czf ${SRCTAR}.tmp ${SRCDIR}
	mv ${SRCTAR}.tmp ${SRCTAR}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com upload

distclean: clean

.PHONY: clean
clean:
	rm -rf ${SRCDIR} ${SRCDIR}.tmp *_${ARCH}.deb *.changes *.dsc 
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
