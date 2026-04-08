PROG = xmenu
OBJS = ${PROG:=.o} ctrlfnt.o
SRCS = ${OBJS:.o=.c}
MAN = ${PROG:=.1}
DOC = README.md

PREFIX ?= /usr/local
MANPREFIX ?= ${PREFIX}/share/man

#
# Cross-compile friendliness:
# - If STAGING_SYSROOT is set, prefer headers/libs from that sysroot.
# - Allow disabling Xinerama (multi-monitor support) when headers/libs
#   are not available (NO_XINERAMA=1).
#
STAGING_SYSROOT ?=

ifeq ($(strip $(STAGING_SYSROOT)),)
X11INC ?= /usr/include
X11LIB ?= /usr/lib
FTINC  ?= /usr/include/freetype2
else
X11INC ?= $(STAGING_SYSROOT)/usr/include
X11LIB ?= $(STAGING_SYSROOT)/usr/lib
FTINC  ?= $(STAGING_SYSROOT)/usr/include/freetype2
endif

NO_XINERAMA ?= 0

DEFS = -D_POSIX_C_SOURCE=200809L -DGNU_SOURCE -D_BSD_SOURCE
INCS = -I${X11INC} -I${FTINC}
LIBS = -L${X11LIB} -lfontconfig -lXft -lX11 -lXrender -lImlib2

ifneq ($(strip $(NO_XINERAMA)),0)
DEFS += -DNO_XINERAMA
else
LIBS += -lXinerama
endif

bindir = ${DESTDIR}${PREFIX}/bin
mandir = ${DESTDIR}${MANPREFIX}/man1

all: ${PROG}

# update README.md with manual; you do not need to run this
${DOC}: ${MAN} ${DOC}
	printf "/## Manual/\n\
	;d\n\
	a\n## Manual\n\n.\n\
	r !mandoc -I os=UNIX -T ascii ${MAN} | col -b | expand -t 8 | sed -E 's,^.+,\t&,'\n\
	w\n" | ed -s README.md

${PROG}: ${OBJS}
	${CC} -o $@ ${OBJS} ${LIBS} ${LDFLAGS}

.c.o:
	${CC} -std=c99 -pedantic ${DEFS} ${INCS} ${CFLAGS} ${CPPFLAGS} -o $@ -c $<

${OBJS}: ctrlfnt.h

tags: ${SRCS}
	ctags ${SRCS}

lint: ${SRCS}
	-mandoc -T lint -W warning ${MAN}
	-clang-tidy ${SRCS} -- -std=c99 ${DEFS} ${INCS} ${CPPFLAGS}

clean:
	rm -f ${OBJS} ${PROG} ${PROG:=.core} tags

install: all
	mkdir -p ${bindir}
	mkdir -p ${mandir}
	install -m 755 ${PROG} ${bindir}/${PROG}
	install -m 644 ${MAN} ${mandir}/${MAN}

uninstall:
	-rm ${bindir}/${PROG}
	-rm ${mandir}/${MAN}

.PHONY: all tags clean install uninstall lint
