ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif


SUBPROJECTS += ipatool
IPATOOL_VERSION := 1.0.8
DEB_IPATOOL_V   ?= $(IPATOOL_VERSION)

ipatool-setup: setup
	$(call GITHUB_ARCHIVE,majd,ipatool,$(IPATOOL_VERSION),v$(IPATOOL_VERSION))
	$(call EXTRACT_TAR,ipatool-$(IPATOOL_VERSION).tar.gz,ipatool-$(IPATOOL_VERSION),ipatool)
	mkdir -p $(BUILD_STAGE)/ipatool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/ipatool/.build_complete),)
ipatool:
	@echo "Using previously built ipatool."
else
ipatool: ipatool-setup
	sed -e 's|@IPATOOL_VERSION@|$(IPATOOL_VERSION)|g' < $(BUILD_MISC)/ipatool/Package.swift > $(BUILD_WORK)/ipatool/Sources/CLI/Package.swift
	
	cd $(BUILD_WORK)/ipatool; \
		swift build -c release -Xswiftc -sdk -Xswiftc $(TARGET_SYSROOT) -Xswiftc -target -Xswiftc $(LLVM_TARGET)
	cp $(BUILD_WORK)/ipatool/.build/release/ipatool $(BUILD_STAGE)/ipatool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/
		
	$(call AFTER_BUILD)
endif

ipatool-package: ipatool-stage
	# ipatool.mk Package Structure
	rm -rf $(BUILD_DIST)/ipatool

	# ipatool.mk Prep ipatool
	cp -a $(BUILD_STAGE)/ipatool $(BUILD_DIST)

	# ipatool.mk Sign
	$(call SIGN,ipatool,general.xml)

	# ipatool.mk Make .debs
	$(call PACK,ipatool,DEB_IPATOOL_V)

	# ipatool.mk Build cleanup
	rm -rf $(BUILD_DIST)/ipatool

.PHONY: ipatool ipatool-package
