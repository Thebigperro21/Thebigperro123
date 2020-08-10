ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libpixman
LIBPIXMAN_VERSION := 0.40.0
DEB_LIBPIXMAN_V   ?= $(LIBPIXMAN_VERSION)

libpixman-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://cairographics.org/releases/pixman-$(LIBPIXMAN_VERSION).tar.gz
	$(call EXTRACT_TAR,pixman-$(LIBPIXMAN_VERSION).tar.gz,pixman-$(LIBPIXMAN_VERSION),libpixman)

ifneq ($(wildcard $(BUILD_WORK)/libpixman/.build_complete),)
libpixman:
	@echo "Using previously built libpixman."
else
libpixman: libpixman-setup libpng16
	cd $(BUILD_WORK)/libpixman && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--disable-gtk \
		--disable-silent-rules 
	+$(MAKE) -C $(BUILD_WORK)/libpixman
	+$(MAKE) -C $(BUILD_WORK)/libpixman install \
		DESTDIR=$(BUILD_STAGE)/libpixman
	touch $(BUILD_WORK)/libpixman/.build_complete
endif

libpixman-package: libpixman-stage
	# libpixman.mk Package Structure
	rm -rf $(BUILD_DIST)/libpixman-1-0{-dev}
	mkdir -p $(BUILD_DIST)/libpixman-1-0/usr/lib \
		$(BUILD_DIST)/libpixman-1-dev/usr/{lib,include/pixman-1}
	
	# libpixman.mk Prep libpixman
	cp -a $(BUILD_STAGE)/libpixman/usr/lib/libpixman-1.0.40.0.dylib $(BUILD_DIST)/libpixman-1-0/usr/lib

	# libpixman.mk Prep libpixman-dev
	cp -a $(BUILD_STAGE)/libpixman/usr/lib/{pkgconfig,libpixman-1.{a,dylib}} $(BUILD_DIST)/libpixman-1-dev/usr/lib
	cp -a $(BUILD_STAGE)/libpixman/usr/include/pixman-1/ $(BUILD_DIST)/libpixman-1-dev/usr/include/pixman-1
	
	# libpixman.mk Sign
	$(call SIGN,libpixman-1-0,general.xml)
	$(call SIGN,libpixman-1-dev,general.xml)
	
	# libpixman.mk Make .debs
	$(call PACK,libpixman-1-0,DEB_LIBPIXMAN_V)
	$(call PACK,libpixman-1-dev,DEB_LIBPIXMAN_V)
	
	# libpixman.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpixman-1-0 \
		$(BUILD_DIST)/libpixman-1-dev

.PHONY: libpixman libpixman-package
