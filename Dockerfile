FROM alpine:3.12

RUN apk --update add pcre libbz2 ca-certificates libressl git && rm /var/cache/apk/*

RUN adduser -h /etc/nginx -D -s /bin/sh nginx
WORKDIR /tmp

ARG NGINX_VERSION=1.18.0
ENV NGINX_VERSION=$NGINX_VERSION

# fetch extra modules, add compilation env, build required C based gems and cleanup
RUN git clone https://github.com/vozlt/nginx-module-vts.git \
  && git clone https://github.com/Refinitiv/nginx-sticky-module-ng.git \
  && git clone https://github.com/wdaike/ngx_upstream_jdomain.git \
  && git clone https://github.com/yaoweibin/nginx_upstream_check_module.git \
  && apk --update add --virtual build_deps build-base zlib-dev pcre-dev libressl-dev \
  && wget -O - https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | tar xzf - \
  && cd nginx-$NGINX_VERSION && ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=stderr \
    --http-log-path=/dev/stdout \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-mail=dynamic \
    --add-module=../nginx-module-vts \
    --add-module=../nginx-sticky-module-ng \
    --add-module=../ngx_upstream_jdomain \
    --add-module=../nginx_upstream_check_module \
    --with-pcre-jit \
    --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security' \
    --with-ld-opt='-Wl,-z,relro -Wl,--as-needed' \
  && make install \
  && cd .. && rm -rf nginx-$NGINX_VERSION \
  && mkdir /var/cache/nginx \
  && rm /etc/nginx/*.default \
  && apk del build_deps && rm /var/cache/apk/* \
  && rm -rf nginx-module-vts \
  && rm -rf nginx-sticky-module-ng \
  && rm -rf ngx_upstream_jdomain \
  && rm -rf nginx_upstream_check_module

COPY build/nginx.conf /etc/nginx/nginx.conf
COPY build/conf.d /etc/nginx/conf.d

ENTRYPOINT ["/usr/sbin/nginx"]
