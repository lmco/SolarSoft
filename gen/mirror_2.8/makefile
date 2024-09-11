FILES=README CHANGES-since-2.3 TODO \
	lchat.pl dateconv.pl do_unlinks ftp.pl lsparse.pl makefile \
	mirror mirror.cam mirror.defaults mirror.man mirror.nightly \
	mirror.pl mirror.weather socket.ph socket.ph-solaris\
	mm mm.man pkgs_to_mmin mmin \
	support/cyber-patches support/lstest.pl new-patches-by

all:
	echo try make mirror.tar

mirror.tar: $(FILES)
	rev=`./mirror -v | perl -ane 'print "$$F[2]\n";'`; echo $rev; \
		tar cvf mirror-$$rev.tar $(FILES)

mirror.shar: $(FILES)
	rev=`./mirror -v | perl -ane 'print "$$F[2]\n";'`; echo $rev; \
		shar $(FILES) > mirror-$$rev.shar

ci:
	checkin $(FILES)

#  install, clean ...
# mode to install .pl files
PLMODE = 644
# mode to install executables
EXMODE = 755
# group to own all the files
GRP = gnu
# directory to install .pl (perl library) files
PLDIR = /usr/local/perl5/lib/perl5
# directory to install public executables
BINDIR = /usr/local/sbin
# directory to install man pages
MANDIR = /usr/local/man/man1

install:
	install -m $(PLMODE) -g $(GRP) lchat.pl $(PLDIR)
	install -m $(PLMODE) -g $(GRP) chat2.pl $(PLDIR)
	install -m $(PLMODE) -g $(GRP) dateconv.pl $(PLDIR)
	install -m $(PLMODE) -g $(GRP) ftp.pl $(PLDIR)
	install -m $(PLMODE) -g $(GRP) lsparse.pl $(PLDIR)
	install -m $(EXMODE) -g $(GRP) mirror.pl $(PLDIR)
	install -m $(EXMODE) -g $(GRP) do_unlinks $(BINDIR)
	install -m $(EXMODE) -g $(GRP) pkgs_to_mmin $(BINDIR)
	install -m $(EXMODE) -g $(GRP) mm $(BINDIR)/mirror-master
	install -m $(PLMODE) -g $(GRP) mirror.man $(MANDIR)/mirror.1
	install -m $(PLMODE) -g $(GRP) mm.man $(MANDIR)/mirror-master.1

# directory to install .pl (perl library) files for rperl
RPLDIR = /usr/local/rperl5/lib/perl5

rinstall:
	sed 's/^\#!\/bin\/perl5/\#!\/bin\/rperl5/g' < mirror.pl > rmirror.pl
	install -m $(PLMODE) -g $(GRP) lchat.pl $(RPLDIR)
	install -m $(PLMODE) -g $(GRP) chat2.pl $(RPLDIR)
	install -m $(PLMODE) -g $(GRP) dateconv.pl $(RPLDIR)
	install -m $(PLMODE) -g $(GRP) ftp.pl $(RPLDIR)
	install -m $(PLMODE) -g $(GRP) lsparse.pl $(RPLDIR)
	install -m $(EXMODE) -g $(GRP) rmirror.pl $(RPLDIR)/mirror.pl
	install -m $(EXMODE) -g $(GRP) do_unlinks $(BINDIR)
	install -m $(EXMODE) -g $(GRP) pkgs_to_mmin $(BINDIR)
	install -m $(EXMODE) -g $(GRP) mm $(BINDIR)/mirror-master
	install -m $(PLMODE) -g $(GRP) mirror.man $(MANDIR)/mirror.1
	install -m $(PLMODE) -g $(GRP) mm.man $(MANDIR)/mirror-master.1
