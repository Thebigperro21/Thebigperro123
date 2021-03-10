ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libinsn
LIBINSN_VERSION := 35
LIBINSN_COMMIT  := 64124fd2b1b57d7b76a0e2b0c06434a7048758d2
DEB_LIBINSN_V   ?= $(LIBINSN_VERSION)-1

libinsn-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/libinsn-$(LIBINSN_COMMIT).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/libinsn-$(LIBINSN_COMMIT).tar.gz \
			https://github.com/tihmstar/libinsn/archive/$(LIBINSN_COMMIT).tar.gz
	$(call EXTRACT_TAR,libinsn-$(LIBINSN_COMMIT).tar.gz,libinsn-$(LIBINSN_COMMIT),libinsn)

ifneq ($(wildcard $(BUILD_WORK)/libinsn/.build_complete),)
libinsn:
	@echo "Using previously built libinsn."
else
libinsn: libinsn-setup libgeneral
	cd $(BUILD_WORK)/libinsn && ./autogen.sh \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) 
	+$(MAKE) -C $(BUILD_WORK)/libinsn
	+$(MAKE) -C $(BUILD_WORK)/libinsn install \
		DESTDIR="$(BUILD_STAGE)/libinsn"
	+$(MAKE) -C $(BUILD_WORK)/libinsn install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libinsn/.build_complete
endif

libinsn-package: libinsn-stage
	# libinsn.mk Package Structure
	rm -rf $(BUILD_DIST)/libinsn{0,-dev}
	mkdir -p $(BUILD_DIST)/libinsn{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libinsn.mk Prep libinsn0
	cp -a $(BUILD_STAGE)/libinsn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libinsn.0.dylib $(BUILD_DIST)/libinsn0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# libinsn.mk Prep libinsn-dev
	cp -a $(BUILD_STAGE)/libinsn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libinsn.0.dylib) $(BUILD_DIST)/libinsn-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libinsn/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libinsn-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# libinsn.mk Sign
	$(call SIGN,libinsn0,general.xml)
	
	# libinsn.mk Make .debs
	$(call PACK,libinsn0,DEB_LIBINSN_V)
	$(call PACK,libinsn-dev,DEB_LIBINSN_V)
	
	# libinsn.mk Build cleanup
	rm -rf $(BUILD_DIST)/libinsn{0,-dev}

.PHONY: libinsn libinsn-package
