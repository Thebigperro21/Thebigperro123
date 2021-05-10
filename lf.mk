ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += lf
LF_VERSION  := r22
DEB_LF_V    ?= 1.0-$(LF_VERSION)

lf-setup: setup
	$(call GITHUB_ARCHIVE,gokcehan,lf,$(LF_VERSION),$(LF_VERSION))
	$(call EXTRACT_TAR,lf-$(LF_VERSION).tar.gz,lf-$(LF_VERSION),lf)
	mkdir -p $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

ifneq ($(wildcard $(BUILD_WORK)/lf/.build_complete),)
lf:
	@echo "Using previously built lf."
else
lf: lf-setup
	# Compile lf and move binaries
	cd $(BUILD_WORK)/lf && $(DEFAULT_GOLANG_FLAGS) \
		go build --ldflags="-s -w" .
	cp -a $(BUILD_WORK)/lf/lf $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/lf/lf.1 $(BUILD_STAGE)/lf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	touch $(BUILD_WORK)/lf/.build_complete
endif

lf-package: lf-stage
	# lf.mk Package Structure
	mkdir -p $(BUILD_DIST)/lf
	cp -a $(BUILD_STAGE)/lf $(BUILD_DIST)

	# lf.mk Sign
	$(call SIGN,lf,general.xml)

	# lf.mk Make .debs
	$(call PACK,lf,DEB_LF_V)

	# lf.mk Build Cleanup
	rm -rf $(BUILD_DIST)/lf

.PHONY: lf lf-package
