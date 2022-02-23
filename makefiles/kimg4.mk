ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += kimg4
KIMG4_VERSION := 0.1.1
DEB_KIMG4_V   ?= $(KIMG4_VERSION)

kimg4-setup: setup
	$(call GITHUB_ARCHIVE,cxnder,kimg4,master,master)
	$(call EXTRACT_TAR,kimg4-master.tar.gz,kimg4-master,kimg4)

ifneq ($(wildcard $(BUILD_WORK)/kimg4/.build_complete),)
kimg4:
	@echo "Using previously built kimg4."
else
kimg4: kimg4-setup pyaes
	cd $(BUILD_WORK)/kimg4 && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--install-layout=deb \
		--root="$(BUILD_STAGE)/kimg4" \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	find $(BUILD_STAGE)/kimg4 -name __pycache__ -prune -exec rm -rf {} \;
	$(call AFTER_BUILD)
endif

kimg4-package: kimg4-stage
	# kimg4.mk Package Structure
	rm -rf $(BUILD_DIST)/kimg4

	# kimg4.mk Prep kimg4
	cp -a $(BUILD_STAGE)/kimg4 $(BUILD_DIST)

	#kimg4.mk Make .debs
	$(call PACK,kimg4,DEB_KIMG4_V)

	# kimg4.mk Build cleanup
	rm -rf $(BUILD_DIST)/kimg4

.PHONY: kimg4 kimg4-package
