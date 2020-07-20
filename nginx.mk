ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += nginx
NGINX_VERSION := 1.19.1
DEB_NGINX_V   ?= $(NGINX_VERSION)

nginx-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
	$(call EXTRACT_TAR,nginx-$(NGINX_VERSION).tar.gz,nginx-$(NGINX_VERSION),nginx)
	$(call DO_PATCH,nginx,nginx,-p0)
	awk -i inplace '!found && /NGX_PLATFORM/ { print "NGX_PLATFORM=Darwin:19.5.0:iPhone10,1"; found=1 } 1' \
		$(BUILD_WORK)/nginx/configure


ifneq ($(wildcard $(BUILD_WORK)/nginx/.build_complete),)
nginx:
	@echo "Using previously built nginx."
else
nginx: nginx-setup openssl pcre libgeoip
	cd $(BUILD_WORK)/nginx && ./configure \
		--with-cc-opt="$(CFLAGS) $(CPPFLAGS)" \
		--with-ld-opt="$(LDFLAGS)" \
		--sbin-path=/usr/bin/nginx \
		--prefix=/etc/nginx \
		--conf-path=/etc/nginx/nginx.conf \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-log-path=/var/log/nginx/access.log \
    --error-log-path=stderr \
    --http-client-body-temp-path=/var/lib/nginx/client-body \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-scgi-temp-path=/var/lib/nginx/scgi \
    --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
		--with-compat \
		--with-debug \
		--with-http_addition_module \
		--with-http_auth_request_module \
		--with-http_dav_module \
		--with-http_degradation_module \
		--with-http_flv_module \
		--with-http_geoip_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_mp4_module \
		--with-http_realip_module \
		--with-http_secure_link_module \
		--with-http_slice_module \
		--with-http_ssl_module \
		--with-http_stub_status_module \
		--with-http_sub_module \
		--with-http_v2_module \
		--with-mail \
		--with-mail_ssl_module \
		--with-pcre-jit \
		--with-stream \
		--with-stream_geoip_module \
		--with-stream_realip_module \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-threads


	# Post configure patch. ngx_auto_config.h is generated by ./configure
	# Huge thanks to https://programmer.help/blogs/cross-compiling-nginx-used-on-hi3536.html
	echo "#ifndef NGX_SYS_NERR" >> $(BUILD_WORK)/nginx/objs/ngx_auto_config.h
	echo "#define NGX_SYS_NERR  132" >> $(BUILD_WORK)/nginx/objs/ngx_auto_config.h
	echo "#endif" >> $(BUILD_WORK)/nginx/objs/ngx_auto_config.h

	echo "#ifndef NGX_HAVE_SYSVSHM" >> $(BUILD_WORK)/nginx/objs/ngx_auto_config.h
	echo "#define NGX_HAVE_SYSVSHM 1" >> $(BUILD_WORK)/nginx/objs/ngx_auto_config.h
	echo "#endif" >> $(BUILD_WORK)/nginx/objs/ngx_auto_config.h

	+$(MAKE) -C $(BUILD_WORK)/nginx
	+$(MAKE) -C $(BUILD_WORK)/nginx install \
		DESTDIR="$(BUILD_STAGE)/nginx"
	touch $(BUILD_WORK)/nginx/.build_complete
endif
	
nginx-package: nginx-stage
	# nginx.mk Package Structure
	rm -rf $(BUILD_DIST)/nginx
	mkdir -p $(BUILD_DIST)/nginx

	# nginx.mk Prep nginx
	cp -a $(BUILD_STAGE)/nginx $(BUILD_DIST)/nginx

	# nginx.mk Sign
	$(call SIGN,nginx,general.xml)

	# nginx.mk Make .debs
	$(call PACK,nginx,DEB_NGINX_V)

	# nginx.mk Build cleanup
	rm -rf $(BUILD_DIST)/nginx

.PHONY: nginx nginx-package
