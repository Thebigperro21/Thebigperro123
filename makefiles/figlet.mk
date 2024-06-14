ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += figlet
FIGLET_VERSION := 2.2.5
DEB_FIGLET_V   ?= $(FIGLET_VERSION)-1

figlet-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),ftp://ftp.figlet.org/pub/figlet/program/unix/figlet-$(FIGLET_VERSION).tar.gz)
	$(call EXTRACT_TAR,figlet-$(FIGLET_VERSION).tar.gz,figlet-$(FIGLET_VERSION),figlet)
	sed -i '/#include <stdio.h>/a #include <getopt.h>' $(BUILD_WORK)/figlet/figlet.c
	sed -e "38s|man|share/man|" -e "s|prefix|PREFIX|g" -i $(BUILD_WORK)/figlet/Makefile

ifneq ($(wildcard $(BUILD_WORK)/figlet/.build_complete),)
figlet:
	@echo "Using previously built figlet."
else
figlet: figlet-setup
	+$(MAKE) -C $(BUILD_WORK)/figlet \
		CC="$(CC)" \
		CFLAGS="$(CFLAGS)" \
		LD="$(CC)" \
		LDFLAGS="$(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/figlet install \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/figlet"
	$(call AFTER_BUILD)
endif

figlet-package: figlet-stage
	# figlet.mk Package Structure
	rm -rf $(BUILD_DIST)/figlet

	# figlet.mk Prep figlet
	cp -a $(BUILD_STAGE)/figlet $(BUILD_DIST)

	# figlet.mk Sign
	$(call SIGN,figlet,general.xml)

	# figlet.mk Make .debs
	$(call PACK,figlet,DEB_FIGLET_V)

	# figlet.mk Build cleanup
	rm -rf $(BUILD_DIST)/figlet

.PHONY: figlet figlet-package
