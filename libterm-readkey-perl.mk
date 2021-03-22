ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS                  += libterm-readkey-perl
LIBTERM-READKEY-PERL_VERSION := 2.38
DEB_LIBTERM-READKEY-PERL_V   ?= $(LIBTERM-READKEY-PERL_VERSION)

libterm-readkey-perl-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/libterm-readkey-perl-$(LIBTERM-READKEY-PERL_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/libterm-readkey-perl-$(LIBTERM-READKEY-PERL_VERSION).tar.gz \
			https://cpan.metacpan.org/authors/id/J/JS/JSTOWE/TermReadKey-$(LIBTERM-READKEY-PERL_VERSION).tar.gz
	$(call EXTRACT_TAR,libterm-readkey-perl-$(LIBTERM-READKEY-PERL_VERSION).tar.gz,TermReadKey-$(LIBTERM-READKEY-PERL_VERSION),libterm-readkey-perl)

	###
	#
	# Install libterm-readkey-perl from Procursus before building this. (Silly, I know. Sorry!)
	#
	###

ifneq ($(wildcard $(BUILD_WORK)/libterm-readkey-perl/.build_complete),)
libterm-readkey-perl:
	@echo "Using previously built libterm-readkey-perl."
else
libterm-readkey-perl: libterm-readkey-perl-setup perl
	cd $(BUILD_WORK)/libterm-readkey-perl && /opt/procursus/bin/perl Makefile.PL \
		INSTALLSITEARCH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		INSTALLARCHLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		INSTALLVENDORARCH=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		INSTALLPRIVLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
		INSTALLSITELIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
		INSTALLVENDORLIB=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/perl5 \
		PERL_LIB=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		PERL_ARCHLIB=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		PERL_ARCHLIBDEP=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR) \
		PERL_INC=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/CORE \
		PERL_INCDEP=$(BUILD_STAGE)/perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/CORE \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		INSTALLMAN1DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
		INSTALLSITEMAN1DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
		INSTALLVENDORMAN1DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
		INSTALLMAN3DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
		INSTALLSITEMAN3DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
		INSTALLVENDORMAN3DIR=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 \
		PERL="/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/perl" \
		CCFLAGS="$(CFLAGS)" \
		LDDLFLAGS="$(LDFLAGS) -shared"
	+$(MAKE) -C $(BUILD_WORK)/libterm-readkey-perl install \
		FULLPERLRUNINST="/opt/procursus/bin/perl -I/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)" \
		DESTDIR="$(BUILD_STAGE)/libterm-readkey-perl"
	rm -f $(BUILD_STAGE)/libterm-readkey-perl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/perl5/$(PERL_MAJOR)/perllocal.pod
	touch $(BUILD_WORK)/libterm-readkey-perl/.build_complete
endif

libterm-readkey-perl-package: libterm-readkey-perl-stage
	# libterm-readkey-perl.mk Package Structure
	rm -rf $(BUILD_DIST)/libterm-readkey-perl

	# libterm-readkey-perl.mk Prep libterm-readkey-perl
	cp -a $(BUILD_STAGE)/libterm-readkey-perl $(BUILD_DIST)

	# libterm-readkey-perl.mk Make .debs
	$(call PACK,libterm-readkey-perl,DEB_LIBTERM-READKEY-PERL_V)

	# libterm-readkey-perl.mk Build cleanup
	rm -rf $(BUILD_DIST)/libterm-readkey-perl

.PHONY: libterm-readkey-perl libterm-readkey-perl-package
