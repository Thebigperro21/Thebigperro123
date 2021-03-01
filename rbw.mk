# This is literally just a search and replace of ripgrep.mk, thank you rust

ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += rbw
RBW_VERSION := 1.0.0
DEB_RBW_V   ?= $(RBW_VERSION)

rbw-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/rbw-$(RBW_VERSION).tar.gz" ] && wget -q -nc -O $(BUILD_SOURCE)/rbw-$(RBW_VERSION).tar.gz https://github.com/doy/rbw/archive/$(RBW_VERSION).tar.gz
	$(call EXTRACT_TAR,rbw-$(RBW_VERSION).tar.gz,rbw-$(RBW_VERSION),rbw)

ifneq ($(wildcard $(BUILD_WORK)/rbw/.build_complete),)
rbw:
	@echo "Using previously built rbw."
else
rbw: rbw-setup pinentry
	$(call DO_PATCH,rbw,rbw,-p1)
	cd $(BUILD_WORK)/rbw && SDKROOT="$(TARGET_SYSROOT)" cargo \
		build \
		--release \
		--target=$(RUST_TARGET)
	$(GINSTALL) -Dm755 $(BUILD_WORK)/rbw/target/$(RUST_TARGET)/release/rbw $(BUILD_STAGE)/rbw/usr/bin/rbw
	$(GINSTALL) -Dm755 $(BUILD_WORK)/rbw/target/$(RUST_TARGET)/release/rbw-agent $(BUILD_STAGE)/rbw/usr/bin/rbw-agent
	$(GINSTALL) -Dm755 $(BUILD_WORK)/rbw/bin/rbw-fzf $(BUILD_STAGE)/rbw/usr/bin/rbw-fzf
	$(GINSTALL) -Dm755 $(BUILD_WORK)/rbw/bin/pass-import $(BUILD_STAGE)/rbw/usr/bin/pass-import

	touch $(BUILD_WORK)/rbw/.build_complete
endif

rbw-package: rbw-stage
	# rbw.mk Package Structure
	rm -rf $(BUILD_DIST)/rbw
	
	# rbw.mk Prep rbw
	cp -a $(BUILD_STAGE)/rbw $(BUILD_DIST)
	
	# rbw.mk Sign
	$(call SIGN,rbw,general.xml)
	
	# rbw.mk Make .debs
	$(call PACK,rbw,DEB_RBW_V)
	
	# rbw.mk Build cleanup
	rm -rf $(BUILD_DIST)/rbw

.PHONY: rbw rbw-package
