PACKAGE=lxc-pve
LXCVER=3.0.0
DEBREL=1

SRCDIR=lxc
BUILDSRC := $(SRCDIR).tmp

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell git rev-parse HEAD)

DEB1=${PACKAGE}_${LXCVER}-${DEBREL}_${ARCH}.deb
DEB2=${PACKAGE}-dev_${LXCVER}-${DEBREL}_${ARCH}.deb \
     ${PACKAGE}-dbgsym_${LXCVER}-${DEBREL}_${ARCH}.deb
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
	mkdir $(BUILDSRC)/debian/config
	for i in config/*.conf.in; do \
	  sed -e 's|@LXCTEMPLATECONFIG@|/usr/share/lxc/config|g' $$i > $(BUILDSRC)/debian/$${i%.in} ; \
	done
	echo "git clone git://git.proxmox.com/git/lxc.git\\ngit checkout $(GITVERSION)" > $(BUILDSRC)/debian/SOURCE
	cd $(BUILDSRC); dpkg-buildpackage -rfakeroot -b -us -uc
	lintian $(DEBS)

.PHONY: update-template-configs
update-template-configs:
	test -d lxc-templates || git clone https://github.com/lxc/lxc-templates lxc-templates
	cd lxc-templates && git pull
	rm -rf config
	cp -R lxc-templates/config config
	rm -f config/*.am config/*.m4
	git add config

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
