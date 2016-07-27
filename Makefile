RELEASE=4.1

PACKAGE=lxc-pve
LXCVER=2.0.3
DEBREL=3

SRCDIR=lxc
SRCTAR=${SRCDIR}.tgz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEBS=					\
${PACKAGE}_${LXCVER}-${DEBREL}_amd64.deb  			\
${PACKAGE}-dev_${LXCVER}-${DEBREL}_amd64.deb  			\
${PACKAGE}-dbg_${LXCVER}-${DEBREL}_amd64.deb

all: ${DEBS}
	echo ${DEBS}

deb ${DEBS}: ${SRCTAR}
	rm -rf ${SRCDIR}
	tar xf ${SRCTAR}
	cp -a debian ${SRCDIR}/debian
	echo "git clone git://git.proxmox.com/git/lxc.git\\ngit checkout ${GITVERSION}" >  ${SRCDIR}/debian/SOURCE
	cd ${SRCDIR}; dpkg-buildpackage -rfakeroot -b -us -uc
	lintian ${DEBS}


.PHONY: download
download ${SRCTAR}:
	rm -rf ${SRCDIR} ${SRCTAR}
	git clone -b stable-2.0 git://github.com/lxc/lxc
	tar czf ${SRCTAR}.tmp ${SRCDIR}
	mv ${SRCTAR}.tmp ${SRCTAR}

.PHONY: upload
upload: ${DEBS}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/${PACKAGE}_*.deb
	rm -f /pve/${RELEASE}/extra/${PACKAGE}-dev_*.deb
	rm -f /pve/${RELEASE}/extra/${PACKAGE}-dbg_*.deb
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEBS} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

distclean: clean

.PHONY: clean
clean:
	rm -rf ${SRCDIR} ${SRCDIR}.tmp *_${ARCH}.deb *.changes *.dsc 
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
