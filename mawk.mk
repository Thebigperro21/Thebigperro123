ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif
SUBPROJECTS   += mawk
MAWK_VERSION := 1.3.4
MAWK_COMMIT := 20200120
DEB_MAWK_V ?= $(MAWK_VERSION)

mawk-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/m/mawk/mawk_$(MAWK_VERSION).$(MAWK_COMMIT).orig.tar.gz
	$(call EXTRACT_TAR,mawk_$(MAWK_VERSION).$(MAWK_COMMIT).orig.tar.gz,mawk-$(MAWK_VERSION)-$(MAWK_COMMIT),mawk)

ifneq ($(wildcard $(BUILD_WORK)/mawk/.build_complete),)
mawk:
	@echo "Using previously built mawk."
else
mawk: mawk-setup
	cd $(BUILD_WORK)/mawk && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/mawk
	+$(MAKE) -C $(BUILD_WORK)/mawk install \
		DESTDIR=$(BUILD_STAGE)/mawk
	touch $(BUILD_WORK)/mawk/.build_complete
endif

mawk-package: mawk-stage
	
	# mawk.mk Package Structure
	rm -rf $(BUILD_DIST)/mawk
	mkdir -p $(BUILD_DIST)/mawk
	
	# mawk.mk Prep mawk
	cp -a $(BUILD_STAGE)/mawk $(BUILD_DIST)
	
	# mawk.mk Sign
	$(call SIGN,mawk,general.xml)
	
	# mawk.mk Make .debs
	$(call PACK,mawk,DEB_MAWK_V)
	
	# mawk.mk Build cleanup
	rm -rf $(BUILD_DIST)/mawk
	.PHONY: mawk mawk-package
