FROM alpine:latest as build

RUN apk add --no-cache alpine-sdk git perl linux-headers
# Prep the build environment
RUN mkdir -p /build/sources
WORKDIR /build/sources
# Grap the Nginx Deps sources 
RUN wget ftp://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz && \
    wget http://zlib.net/zlib-1.2.11.tar.gz && \
    wget http://www.openssl.org/source/openssl-1.1.1g.tar.gz
# Unpack deps
RUN tar -zxf pcre-8.44.tar.gz && \
    tar -zxf zlib-1.2.11.tar.gz && \
    tar -zxf openssl-1.1.1g.tar.gz
# Build deps
WORKDIR /build/sources/pcre-8.44
RUN ./configure
RUN make
RUN make install
WORKDIR /build/sources/zlib-1.2.11
RUN ./configure
RUN make
RUN make install
WORKDIR /build/sources/openssl-1.1.1g
RUN ./Configure linux-x86_64 --prefix=/usr
RUN make
RUN make install

# Grab the Nginx Source
WORKDIR /build/sources/
RUN wget https://nginx.org/download/nginx-1.18.0.tar.gz
# Grab the VTS plugin source
RUN git clone https://github.com/vozlt/nginx-module-vts.git
# Grab the stickey session plugin
RUN git clone https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng.git
# Grab the resolve upstream plugin
RUN git clone https://github.com/wdaike/ngx_upstream_jdomain.git
# Grab the upstream healthcheck plugin
RUN git clone https://github.com/yaoweibin/nginx_upstream_check_module.git 

# Build with VTS plugin
RUN tar -zxf nginx-1.18.0.tar.gz
WORKDIR /build/sources/nginx-1.18.0
RUN ./configure --prefix=/etc/nginx  \
                --conf-path=/etc/nginx/nginx.conf \
                --with-pcre=../pcre-8.44 \
                --with-zlib=../zlib-1.2.11 \
                --with-http_ssl_module \
                --with-stream \
                --with-stream_ssl_module \
                --with-mail=dynamic \
                --add-module=../nginx-module-vts \
                --add-module=../nginx-sticky-module-ng \
                --add-module=../ngx_upstream_jdomain \
                --add-module=../nginx_upstream_check_module
RUN make
RUN make install

WORKDIR /
RUN rm -rf /build
RUN apk del alpine-sdk git

RUN rm /etc/nginx/nginx.conf
COPY build/nginx.conf /etc/nginx/nginx.conf
COPY build/conf.d /etc/nginx/conf.d
RUN apk add --no-cache ca-certificates
RUN ln -s /etc/nginx/sbin/nginx /sbin/nginx

ENTRYPOINT [ "/sbin/nginx" ]