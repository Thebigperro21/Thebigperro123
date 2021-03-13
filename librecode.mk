ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += librecode
LIBRECODE_VERSION := 3.7.8
DEB_LIBRECODE_V   ?= $(LIBRECODE_VERSION)

librecode-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/rrthomas/recode/releases/download/v$(LIBRECODE_VERSION)/recode-$(LIBRECODE_VERSION).tar.gz
	$(call EXTRACT_TAR,recode-$(LIBRECODE_VERSION).tar.gz,recode-$(LIBRECODE_VERSION),librecode)

ifneq ($(wildcard $(BUILD_WORK)/librecode/.build_complete),)
librecode:
	@echo "Using previously built librecode."
else
librecode: librecode-setup gettext
	cd $(BUILD_WORK)/librecode && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		--without-included-gettext
	+$(MAKE) -C $(BUILD_WORK)/librecode
	+$(MAKE) -C $(BUILD_WORK)/librecode install \
		DESTDIR=$(BUILD_STAGE)/librecode
	+$(MAKE) -C $(BUILD_WORK)/librecode install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/librecode/.build_complete
endif

librecode-package: librecode-stage
	# librecode.mk Package Structure
	rm -rf $(BUILD_DIST)/librecode{3,-dev} $(BUILD_DIST)/recode
	mkdir -p $(BUILD_DIST)/librecode{3,-dev}/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib $(BUILD_DIST)/recode/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	
	# librecode.mk Prep recode
	cp -a $(BUILD_STAGE)/librecode/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin $(BUILD_DIST)/recode/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/bin
	cp -a $(BUILD_STAGE)/librecode/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share $(BUILD_DIST)/recode/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	
	# librecode.mk Prep librecode3
	cp -a $(BUILD_STAGE)/librecode/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/librecode.3.dylib $(BUILD_DIST)/librecode3/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# librecode.mk Prep librecode-dev
	cp -a $(BUILD_STAGE)/librecode/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/include $(BUILD_DIST)/librecode-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	cp -a $(BUILD_STAGE)/librecode/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/{librecode.a,librecode.dylib} $(BUILD_DIST)/librecode-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# librecode.mk Sign
	$(call SIGN,recode,general.xml)
	$(call SIGN,librecode3,general.xml)
	
	# librecode.mk Make .debs
	$(call PACK,recode,DEB_LIBRECODE_V)
	$(call PACK,librecode3,DEB_LIBRECODE_V)
	$(call PACK,librecode-dev,DEB_LIBRECODE_V)
	
	# librecode.mk Build cleanup
	rm -rf $(BUILD_DIST)/librecode{3,-dev} $(BUILD_DIST)/recode

.PHONY: librecode librecode-package
