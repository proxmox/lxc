PACKAGE=lxc-pve
LXCVER=3.0.2+pve1
DEBREL=5

SRCDIR=lxc
BUILDSRC := $(PACKAGE)-$(LXCVER)

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)

DEB_BASE=$(PACKAGE)_$(LXCVER)-$(DEBREL)
DEB1=$(DEB_BASE)_$(ARCH).deb
DEB2=$(PACKAGE)-dev_$(LXCVER)-$(DEBREL)_$(ARCH).deb \
     $(PACKAGE)-dbgsym_$(LXCVER)-$(DEBREL)_$(ARCH).deb
DEBS=$(DEB1) $(DEB2)
DSC=$(DEB_BASE).dsc
TARGZ=$(DEB_BASE).tar.gz

all: $(DEBS)
	echo $(DEBS)

.PHONY: submodule
submodule:
	test -f "$(SRCDIR)/debian/changelog" || git submodule update --init

$(BUILDSRC): lxc debian config | submodule
	rm -rf $(BUILDSRC)
	cp -a $(SRCDIR) $(BUILDSRC)
	cp -a debian $(BUILDSRC)/debian
	mkdir $(BUILDSRC)/debian/config
	for i in config/*.conf.in; do \
	  sed -e 's|@LXCTEMPLATECONFIG@|/usr/share/lxc/config|g' $$i > $(BUILDSRC)/debian/$${i%.in} ; \
	done
	echo "git clone git://git.proxmox.com/git/lxc.git\\ngit checkout $(shell git rev-parse HEAD)" > $(BUILDSRC)/debian/SOURCE

.PHONY: deb
deb: $(DEBS)
$(DEB2): $(DEB1)
$(DEB1): $(BUILDSRC)
	rm -f *.deb
	cd $(BUILDSRC); dpkg-buildpackage -b -us -uc
	lintian $(DEBS)

.PHONY: dsc
dsc $(TARGZ): $(DSC)
$(DSC): $(BUILDSRC)
	rm -f *.dsc
	cd $(BUILDSRC); dpkg-buildpackage -S -us -uc -d -nc
	lintian $(DSC)

.PHONY: upload
upload: $(DEBS)
	tar cf - $(DEBS) | ssh repoman@repo.proxmox.com upload --product pve --dist stretch

distclean: clean

.PHONY: clean
clean:
	rm -rf $(BUILDSRC) *_$(ARCH).deb  *_$(ARCH).dsc *.tar.gz *.changes *.dsc *.buildinfo

.PHONY: dinstall
dinstall: $(DEBS)
	dpkg -i $(DEBS)
