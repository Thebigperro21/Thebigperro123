ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += fd
FD_VERSION := 8.2.1
DEB_FD_V   ?= $(FD_VERSION)

fd-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/fd-v$(FD_VERSION).tar.gz" ] && wget -q -nc -O$(BUILD_SOURCE)/fd-$(FD_VERSION).tar.gz https://github.com/sharkdp/fd/archive/v$(FD_VERSION).tar.gz
	$(call EXTRACT_TAR,fd-$(FD_VERSION).tar.gz,fd-$(FD_VERSION),fd)
	$(call DO_PATCH,fd,fd,-p0)

ifneq ($(wildcard $(BUILD_WORK)/fd/.build_complete),)
fd:
	@echo "Using previously built fd."
else
fd: fd-setup
	cd $(BUILD_WORK)/fd && SDKROOT="$(TARGET_SYSROOT)" cargo \
		build \
		--release \
		--target=$(RUST_TARGET)
	$(GINSTALL) -Dm755 $(BUILD_WORK)/fd/target/$(RUST_TARGET)/release/fd $(BUILD_STAGE)/fd/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/bin/fd
	echo $(BUILD_WORK)/fd/target/$(RUST_TARGET)/release/build/fd-find
	$(GINSTALL) -Dm644 $(BUILD_WORK)/fd/target/$(RUST_TARGET)/release/build/fd-find-*/out/fd.bash $(BUILD_STAGE)/fd/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/bash-completion/completions/fd
	$(GINSTALL) -Dm644 $(BUILD_WORK)/fd/target/$(RUST_TARGET)/release/build/fd-find-*/out/fd.fish $(BUILD_STAGE)/fd/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/fish/vendor_completions.d/fd.fish
	$(GINSTALL) -Dm644 $(BUILD_WORK)/fd/contrib/completion/_fd $(BUILD_STAGE)/fd/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/zsh/site-functions/_fd
	$(GINSTALL) -Dm644 $(BUILD_WORK)/fd/doc/fd.1 $(BUILD_STAGE)/fd/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/share/man/man1/fd.1

	touch $(BUILD_WORK)/fd/.build_complete
endif

fd-package: fd-stage
	# fd.mk Package Structure
	rm -rf $(BUILD_DIST)/fd
	
	# fd.mk Prep fd
	cp -a $(BUILD_STAGE)/fd $(BUILD_DIST)
	
	# fd.mk Sign
	$(call SIGN,fd,general.xml)
	
	# fd.mk Make .debs
	$(call PACK,fd,DEB_FD_V)
	
	# fd.mk Build cleanup
	rm -rf $(BUILD_DIST)/fd

.PHONY: fd fd-package
