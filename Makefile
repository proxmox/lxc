PACKAGE=lxc-pve
LXCVER=2.1.1
DEBREL=1

SRCDIR=lxc
BUILDSRC := $(SRCDIR).tmp

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEB1=${PACKAGE}_${LXCVER}-${DEBREL}_${ARCH}.deb
DEB2=${PACKAGE}-dev_${LXCVER}-${DEBREL}_${ARCH}.deb \
     ${PACKAGE}-dbg_${LXCVER}-${DEBREL}_${ARCH}.deb
DEBS=$(DEB1) $(DEB2)

all: ${DEBS}
	echo ${DEBS}

.PHONY: submodule
submodule:
	test -f "${SRCDIR}/debian/changelog" || git submodule update --init

.PHONY: deb
deb: ${DEBS}
$(DEB2): $(DEB1)
$(DEB1): | submodule
	rm -f *.deb
	rm -rf $(BUILDSRC)
	mkdir $(BUILDSRC)
	cp -a $(SRCDIR)/* $(BUILDSRC)/
	cp -a debian $(BUILDSRC)/debian
	echo "git clone git://git.proxmox.com/git/lxc.git\\ngit checkout $(GITVERSION)" > $(BUILDSRC)/debian/SOURCE
	cd $(BUILDSRC); dpkg-buildpackage -rfakeroot -b -us -uc
	lintian $(DEBS)

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com upload --product pve --dist stretch

distclean: clean

.PHONY: clean
clean:
	rm -rf $(BUILDSRC) *_${ARCH}.deb *.changes *.dsc *.buildinfo

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
