include /usr/share/dpkg/pkg-info.mk
include /usr/share/dpkg/architecture.mk

PACKAGE=lxc-pve

SRCDIR=lxc
BUILDSRC := $(PACKAGE)-$(DEB_VERSION_UPSTREAM)

DEB_BASE=$(PACKAGE)_$(DEB_VERSION_UPSTREAM_REVISION)
DEB1=$(DEB_BASE)_$(DEB_BUILD_ARCH).deb
DEB2=$(PACKAGE)-dev_$(DEB_VERSION_UPSTREAM_REVISION)_$(DEB_BUILD_ARCH).deb \
     $(PACKAGE)-dbgsym_$(DEB_VERSION_UPSTREAM_REVISION)_$(DEB_BUILD_ARCH).deb
DEBS=$(DEB1) $(DEB2)
DSC=$(DEB_BASE).dsc
ORIG_SRC_TAR=$(PACKAGE)_$(DEB_VERSION_UPSTREAM).orig.tar.gz

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

$(ORIG_SRC_TAR): $(BUILDSRC)
	tar czf $(ORIG_SRC_TAR) --exclude="$(BUILDSRC)/debian" $(BUILDSRC)

.PHONY: dsc
dsc: $(DSC)
$(DSC): $(ORIG_SRC_TAR)
	rm -f *.dsc
	cd $(BUILDSRC); dpkg-buildpackage -S -us -uc -d
	lintian $(DSC)

.PHONY: upload
upload: $(DEBS)
	tar cf - $(DEBS) | ssh repoman@repo.proxmox.com upload --product pve --dist bookworm

distclean: clean

.PHONY: clean
clean:
	rm -rf $(BUILDSRC) $(PACKAGE)-[0-9]*/ $(ORIG_SRC_TAR) *.deb *.dsc $(PACKAGE)*.debian.tar.[gx]z *.changes *.dsc *.buildinfo *.build

.PHONY: dinstall
dinstall: $(DEBS)
	dpkg -i $(DEBS)
