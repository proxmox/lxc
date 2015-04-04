RELEASE=4.0


SRCDIR=lxc
SRCTAR=${SRCDIR}.tgz

all: ${SRCTAR}


:PHONY: download
download ${SRCTAR}:
	rm -rf ${SRCDIR} ${SRCTAR}
	git clone git://github.com/lxc/lxc
	tar czf ${SRCTAR}.tmp ${SRCDIR}
	mv ${SRCTAR}.tmp ${SRCTAR}

distclean: clean

.PHONY: clean
clean:
	rm -rf ${SRCDIR} ${SRCDIR}.tmp 
	find . -name '*~' -exec rm {} ';'
