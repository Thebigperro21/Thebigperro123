ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += redis
REDIS_VERSION := 6.0.8
DEB_REDIS_V   ?= $(REDIS_VERSION)

redis-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/redis/redis/archive/$(REDIS_VERSION).tar.gz
	$(call EXTRACT_TAR,$(REDIS_VERSION).tar.gz,redis-$(REDIS_VERSION),redis)
	$(call DO_PATCH,redis,redis,-p1)
	# Please don't ask why
	sed -i 's/$$.AR./$(AR)/g' $(BUILD_WORK)/redis/deps/hiredis/Makefile

	sed -i 's/PLAT= none/PLAT= macosx/' $(BUILD_WORK)/redis/deps/lua/Makefile
	sed -i 's/RANLIB=.*/RANLIB=$(RANLIB)/' $(BUILD_WORK)/redis/deps/lua/Makefile
	sed -i 's/AR=.*/AR=$(AR)/g' $(BUILD_WORK)/redis/deps/lua/src/Makefile
	sed -i 's/RANLIB=.*/RANLIB=$(RANLIB)/g' $(BUILD_WORK)/redis/deps/lua/src/Makefile



ifneq ($(wildcard $(BUILD_WORK)/redis/.build_complete),)
redis:
	@echo "Using previously built redis."
else
redis: redis-setup
	+$(MAKE) -C $(BUILD_WORK)/redis \
		MALLOC=libc \
		BUILD_TLS=yes \
		USE_SYSTEMD=no \
		uname_S=Darwin \
		PREFIX=$(BUILD_STAGE)/redis/usr \
		install
	$(GINSTALL) -Dm644 $(BUILD_WORK)/redis/redis.conf $(BUILD_STAGE)/redis/etc/redis/redis.conf
	$(GINSTALL) -Dm644 $(BUILD_WORK)/redis/sentinel.conf $(BUILD_STAGE)/redis/etc/redis/sentinel.conf

	mkdir -p $(BUILD_STAGE)/redis/Library/LaunchDaemons
	cp -a $(BUILD_INFO)/io.redis.redis-sentinel.plist $(BUILD_STAGE)/redis/Library/LaunchDaemons
	cp -a $(BUILD_INFO)/io.redis.redis-server.plist $(BUILD_STAGE)/redis/Library/LaunchDaemons

	touch $(BUILD_WORK)/redis/.build_complete
endif

redis-package: redis-stage
	# redis.mk Package Structure
	rm -rf $(BUILD_DIST)/redis-{server,tools,sentinel}
	mkdir -p $(BUILD_DIST)/redis-{sentinel,server,tools}/usr/bin \
		$(BUILD_DIST)/redis-{server,sentinel}/{etc/redis,Library/LaunchDaemons}

	# redis.mk Prep redis-sentinel
	cp -a $(BUILD_STAGE)/redis/usr/bin/redis-sentinel $(BUILD_DIST)/redis-sentinel/usr/bin
	cp -a $(BUILD_STAGE)/redis/etc/redis/sentinel.conf $(BUILD_DIST)/redis-sentinel/etc/redis
	cp -a $(BUILD_STAGE)/redis/Library/LaunchDaemons/io.redis.redis-sentinel.plist $(BUILD_DIST)/redis-sentinel/Library/LaunchDaemons

	# redis.mk Prep redis-server
	cp -a $(BUILD_STAGE)/redis/usr/bin/redis-server $(BUILD_DIST)/redis-server/usr/bin
	cp -a $(BUILD_STAGE)/redis/etc/redis/redis.conf $(BUILD_DIST)/redis-server/etc/redis
	cp -a $(BUILD_STAGE)/redis/Library/LaunchDaemons/io.redis.redis-server.plist $(BUILD_DIST)/redis-server/Library/LaunchDaemons

	# redis.mk Prep redis-tools
	cp -a $(BUILD_STAGE)/redis/usr/bin/redis-{benchmark,check-aof,check-rdb,cli} $(BUILD_DIST)/redis-tools/usr/bin

	# redis.mk Sign
	$(call SIGN,redis-sentinel,general.xml)
	$(call SIGN,redis-server,general.xml)
	$(call SIGN,redis-tools,general.xml)

	# redis.mk Make .debs
	$(call PACK,redis-sentinel,DEB_REDIS_V)
	$(call PACK,redis-server,DEB_REDIS_V)
	$(call PACK,redis-tools,DEB_REDIS_V)

	# redis.mk Build cleanup
	rm -rf $(BUILD_DIST)/redis-{sentinel,server,tools}

.PHONY: redis redis-package
