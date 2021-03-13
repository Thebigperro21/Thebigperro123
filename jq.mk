ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += jq
JQ_VERSION   := 1.6
DEB_JQ_V     ?= $(JQ_VERSION)

jq-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/stedolan/jq/releases/download/jq-$(JQ_VERSION)/jq-$(JQ_VERSION).tar.gz
	$(call EXTRACT_TAR,jq-$(JQ_VERSION).tar.gz,jq-$(JQ_VERSION),jq)

ifneq ($(wildcard $(BUILD_WORK)/jq/.build_complete),)
jq:
	@echo "Using previously built jq."
else
jq: jq-setup libonig
	cd $(BUILD_WORK)/jq && autoreconf -fi
	cd $(BUILD_WORK)/jq && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		--with-oniguruma=$(BUILD_STAGE)/libonig/$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		--disable-docs \
		--disable-maintainer-mode \
		CFLAGS="$(CFLAGS) -D_REENTRANT"
	+$(MAKE) -C $(BUILD_WORK)/jq \
		DESTDIR=$(BUILD_STAGE)/jq
	+$(MAKE) -C $(BUILD_WORK)/jq install \
		DESTDIR=$(BUILD_STAGE)/jq
	touch $(BUILD_WORK)/jq/.build_complete
endif

jq-package: jq-stage
	# jq.mk Package Structure
	rm -rf $(BUILD_DIST)/{jq,libjq-dev,libjq1}
	mkdir -p $(BUILD_DIST)/jq/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/{bin,share/man/man1} \
			$(BUILD_DIST)/libjq-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/{include,lib} \
			$(BUILD_DIST)/libjq1/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib

	# jq.mk Prep jq
	cp -a $(BUILD_STAGE)/jq/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin/jq $(BUILD_DIST)/jq/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin
	cp -a $(BUILD_STAGE)/jq/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/man/man1/jq.1 $(BUILD_DIST)/jq/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/man/man1

	# jq.mk Prep libjq-dev
	cp -a $(BUILD_STAGE)/jq/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include/{jq.h,jv.h} $(BUILD_DIST)/libjq-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include
	cp -a $(BUILD_STAGE)/jq/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libjq.dylib $(BUILD_DIST)/libjq-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib

	# jq.mk Prep libjq1
	cp -a $(BUILD_STAGE)/jq/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libjq.{a,1.dylib} $(BUILD_DIST)/libjq1/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib

	# jq.mk Sign
	$(call SIGN,jq,general.xml)
	$(call SIGN,libjq1,general.xml)

	# jq.mk Make .debs
	$(call PACK,jq,DEB_JQ_V)
	$(call PACK,libjq-dev,DEB_JQ_V)
	$(call PACK,libjq1,DEB_JQ_V)

	# jq.mk Build cleanup
	rm -rf $(BUILD_DIST)/{jq,libjq-dev,libjq1}

.PHONY: jq jq-package
