ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += flac
FLAC_VERSION := 1.3.3
DEB_FLAC_V   ?= $(FLAC_VERSION)

flac-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.osuosl.org/pub/xiph/releases/flac/flac-$(FLAC_VERSION).tar.xz
	$(call EXTRACT_TAR,flac-$(FLAC_VERSION).tar.xz,flac-$(FLAC_VERSION),flac)

ifneq ($(wildcard $(BUILD_WORK)/flac/.build_complete),)
flac:
	@echo "Using previously built flac."
else
flac: flac-setup libogg
	cd $(BUILD_WORK)/flac && ./configure -C \
		--build=$$($(BUILD_MISC)/config.guess) \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		--disable-debug \
		--enable-shared \
		--disable-silent-rules \
		--disable-xmms-plugin \
		--disable-rpath \
		--with-ogg \
		--with-ogg-includes=$(BUILD_BASE)/usr/include
	+$(MAKE) -C $(BUILD_WORK)/flac
	+$(MAKE) -C $(BUILD_WORK)/flac install \
		DESTDIR=$(BUILD_STAGE)/flac
	+$(MAKE) -C $(BUILD_WORK)/flac install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/flac/.build_complete
endif

flac-package: flac-stage
	# flac.mk Package Structure
	rm -rf $(BUILD_DIST)/flac \
		$(BUILD_DIST)/{libflac{8,-dev},libflac++{6v5,-dev}}
	mkdir -p $(BUILD_DIST)/{libflac8,libflac++6v5}/usr/lib \
		$(BUILD_DIST)/{libflac-dev,libflac++-dev}/usr/{lib/pkgconfig,include,share/aclocal} \
		$(BUILD_DIST)/flac/usr/share
	
	# flac.mk Prep flac
	cp -a $(BUILD_STAGE)/flac/usr/bin $(BUILD_DIST)/flac/usr
	cp -a $(BUILD_STAGE)/flac/usr/share/man $(BUILD_DIST)/flac/usr/share
	
	# flac.mk Prep libflac8
	cp -a $(BUILD_STAGE)/flac/usr/lib/libFLAC.8.dylib $(BUILD_DIST)/libflac8/usr/lib
	
	# flac.mk Prep libflac-dev
	cp -a $(BUILD_STAGE)/flac/usr/lib/libFLAC.dylib $(BUILD_DIST)/libflac-dev/usr/lib
	cp -a $(BUILD_STAGE)/flac/usr/lib/pkgconfig/flac.pc $(BUILD_DIST)/libflac-dev/usr/lib/pkgconfig
	cp -a $(BUILD_STAGE)/flac/usr/share/aclocal/libFLAC.m4 $(BUILD_DIST)/libflac-dev/usr/lib/pkgconfig
	cp -a $(BUILD_STAGE)/flac/usr/include/FLAC $(BUILD_DIST)/libflac-dev/usr/include
	
	# flac.mk Prep libflac++6v5
	cp -a $(BUILD_STAGE)/flac/usr/lib/libFLAC++.6.dylib $(BUILD_DIST)/libflac++6v5/usr/lib
	
	# flac.mk Prep libflac++-dev
	cp -a $(BUILD_STAGE)/flac/usr/lib/libFLAC++.dylib $(BUILD_DIST)/libflac++-dev/usr/lib
	cp -a $(BUILD_STAGE)/flac/usr/lib/pkgconfig/flac++.pc $(BUILD_DIST)/libflac++-dev/usr/lib/pkgconfig
	cp -a $(BUILD_STAGE)/flac/usr/share/aclocal/libFLAC++.m4 $(BUILD_DIST)/libflac++-dev/usr/lib/pkgconfig
	cp -a $(BUILD_STAGE)/flac/usr/include/FLAC++ $(BUILD_DIST)/libflac++-dev/usr/include
	
	# flac.mk Sign
	$(call SIGN,flac,general.xml)
	$(call SIGN,libflac8,general.xml)
	$(call SIGN,libflac++6v5,general.xml)
	
	# flac.mk Make .debs
	$(call PACK,flac,DEB_FLAC_V)
	$(call PACK,libflac8,DEB_FLAC_V)
	$(call PACK,libflac++6v5,DEB_FLAC_V)
	$(call PACK,libflac-dev,DEB_FLAC_V)
	$(call PACK,libflac++-dev,DEB_FLAC_V)
	
	# flac.mk Build cleanup
	rm -rf $(BUILD_DIST)/flac \
		$(BUILD_DIST)/{libflac{8,-dev},libflac++{6v5,-dev}}

.PHONY: flac flac-package
