FROM alpine:latest as build

RUN apk add --no-cache alpine-sdk git perl go musl binutils gcc 
# Prep the build environment
RUN mkdir -p /build/sources
WORKDIR /build/sources
# Grap the Nginx Deps sources 
RUN wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.42.tar.gz && \
    wget http://zlib.net/zlib-1.2.11.tar.gz && \
    wget http://www.openssl.org/source/openssl-1.0.2p.tar.gz
# Unpack deps
RUN tar -zxf pcre-8.42.tar.gz && \
    tar -zxf zlib-1.2.11.tar.gz && \
    tar -zxf openssl-1.0.2p.tar.gz
# Build deps
WORKDIR /build/sources/pcre-8.42
RUN ./configure
RUN make
RUN make install
WORKDIR /build/sources/zlib-1.2.11
RUN ./configure
RUN make
RUN make install
WORKDIR /build/sources/openssl-1.0.2p
RUN ./Configure linux-x86_64 --prefix=/usr
RUN make
RUN make install

# Grab the Nginx Source
WORKDIR /build/sources/
RUN wget https://nginx.org/download/nginx-1.14.0.tar.gz
# Grab the VTS plugin source
RUN git clone https://github.com/vozlt/nginx-module-vts.git

# Build with VTS plugin
RUN tar -zxf nginx-1.14.0.tar.gz
WORKDIR /build/sources/nginx-1.14.0
RUN ./configure --prefix=/etc/nginx  \
                --conf-path=/etc/nginx/nginx.conf \
                --with-pcre=../pcre-8.42 \
                --with-zlib=../zlib-1.2.11 \
                --with-http_ssl_module \
                --with-stream \
                --with-mail=dynamic \
                --add-module=../nginx-module-vts
RUN make
RUN make install

RUN mkdir -p /go/src/github.com/hnlq715
WORKDIR /go/src/github.com/hnlq715
RUN git clone https://github.com/hnlq715/nginx-vts-exporter.git
ENV GOPATH=/go
ENV GOROOT=/usr/lib/go
WORKDIR /go/src/github.com/hnlq715/nginx-vts-exporter
RUN go build

FROM alpine:latest
COPY --from=build /etc/nginx /etc/nginx
COPY --from=build /go/src/github.com/hnlq715/nginx-vts-exporter/nginx-vts-exporter /nginx-vts-exporter
RUN rm /etc/nginx/nginx.conf
COPY build/nginx.conf /etc/nginx/nginx.conf
COPY build/conf.d /etc/nginx/conf.d
RUN ln -s /etc/nginx/sbin/nginx /sbin/nginx
RUN apk add --no-cache openssl ca-certificates pcre zlib perl

ENV METRICS_NS=nginx

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]