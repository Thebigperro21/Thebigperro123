ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += unibilium
UNIBILIUM_VERSION := 2.1.0
DEB_UNIBILIUM_V   ?= $(UNIBILIUM_VERSION)

unibilium-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/unibilium-$(UNIBILIUM_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/unibilium-$(UNIBILIUM_VERSION).tar.gz \
			https://github.com/neovim/unibilium/archive/v$(UNIBILIUM_VERSION).tar.gz
	$(call EXTRACT_TAR,unibilium-$(UNIBILIUM_VERSION).tar.gz,unibilium-$(UNIBILIUM_VERSION),unibilium)
	$(call DO_PATCH,unibilium,unibilium)
	mkdir -p $(BUILD_WORK)/unibilium/libtool
	echo -e "AC_INIT([dummy],[1.0])\n\
LT_INIT\n\
AC_PROG_LIBTOOL\n\
AC_OUTPUT" > $(BUILD_WORK)/unibilium/libtool/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/unibilium/.build_complete),)
unibilium:
	@echo "Using previously built unibilium."
else
unibilium: unibilium-setup
	cd $(BUILD_WORK)/unibilium/libtool && LIBTOOLIZE="$(LIBTOOLIZE) -i" autoreconf -fi
	cd $(BUILD_WORK)/unibilium/libtool && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE)
	+$(MAKE) -C $(BUILD_WORK)/unibilium \
		PREFIX=/$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		LIBTOOL="$(BUILD_WORK)/unibilium/libtool/libtool" \
		TERMINFO_DIRS='"/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/share/terminfo"'
	+$(MAKE) -C $(BUILD_WORK)/unibilium install PREFIX=/$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		DESTDIR="$(BUILD_STAGE)/unibilium"
	+$(MAKE) -C $(BUILD_WORK)/unibilium install PREFIX=/$(MEMO_PREFIX)$(MEMO_SUBPREFIX) \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/unibilium/.build_complete
endif

unibilium-package: unibilium-stage
	# unibilium.mk Package Structure
	rm -rf $(BUILD_DIST)/{libunibilium-dev,libunibilium4}
	mkdir -p $(BUILD_DIST)/libunibilium{4,-dev}/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# unibilium.mk Prep libunibilium-dev
	cp -a $(BUILD_STAGE)/unibilium/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/{include,share} $(BUILD_DIST)/libunibilium-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)
	cp -a $(BUILD_STAGE)/unibilium/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/{pkgconfig,libunibilium.{a,dylib}} $(BUILD_DIST)/libunibilium-dev/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# unibilium.mk Prep libunibilium4
	cp -a $(BUILD_STAGE)/unibilium/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib/libunibilium.4.dylib $(BUILD_DIST)/libunibilium4/$(MEMO_PREFIX)$(MEMO_SUBPREFIX)/lib
	
	# unibilium.mk Sign
	$(call SIGN,libunibilium4,general.xml)
	
	# unibilium.mk Make .debs
	$(call PACK,libunibilium-dev,DEB_UNIBILIUM_V)
	$(call PACK,libunibilium4,DEB_UNIBILIUM_V)
	
	# unibilium.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libunibilium-dev,libunibilium4}
	
.PHONY: unibilium unibilium-package
