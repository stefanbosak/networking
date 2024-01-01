# Predefined NGINX version
#
# for HTTP3 support required version >=1.25
#
ARG NGINX_VERSION=1.25.3

# Debian release and options
ARG DEBIAN_FRONTEND=noninteractive
ARG DEBIAN_RELEASE=testing-slim

# user in container
ARG CONTAINER_USER=user
ARG CONTAINER_GROUP=user

#
# NGINX container builder
#
FROM debian:${DEBIAN_RELEASE} as nginx-builder

LABEL stage="nginx-builder" \
      description="Debian-based container for preparing NGINX"

ARG NGINX_VERSION

ARG DEBIAN_FRONTEND

# prepare sandbox
WORKDIR /workspace

RUN mkdir -v /var/log/nginx /usr/share/nginx /run/nginx /var/lock/nginx /var/lib/nginx /usr/lib/nginx && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
            ca-certificates \
            tar wget \
            gcc g++ make \
            libc6 \
            libkrb5-dev \
            libssl-dev \
            libpcre3-dev \
            libxml2-dev libxslt1-dev \
            libgd-dev \
            libgeoip-dev \
            zlib1g-dev && \
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O nginx.tar.gz && \
    tar -xzvf nginx.tar.gz -C /workspace --strip-components=1 && \
    ./configure \
      --user="${CONTAINER_USER}" \
      --group="${CONTAINER_GROUP}" \
      --build="custom build $(date +%d-%b-%Y)" \
      --prefix=/usr/share/nginx \
      --sbin-path=/usr/sbin/nginx \
      --conf-path=/etc/nginx/nginx.conf \
      --http-log-path=/var/log/nginx/access.log \
      --error-log-path=/var/log/nginx/error.log \
      --lock-path=/var/lock/nginx/nginx.lock \
      --pid-path=/run/nginx/nginx.pid \
      --modules-path=/usr/lib/nginx/modules \
      --http-client-body-temp-path=/var/lib/nginx/body \
      --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
      --http-proxy-temp-path=/var/lib/nginx/proxy \
      --http-scgi-temp-path=/var/lib/nginx/scgi \
      --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
      --with-compat \
      --with-debug \
      --with-threads \
      --with-file-aio \
      --with-http_gzip_static_module \
      --with-http_stub_status_module \
      --with-http_ssl_module \
      --with-http_image_filter_module \
      --with-http_dav_module \
      --with-http_gunzip_module \
      --with-http_v2_module \
      --with-http_v3_module \
      --with-http_realip_module \
      --with-http_addition_module \
      --with-http_xslt_module \
      --with-http_image_filter_module \
      --with-http_geoip_module \
      --with-http_sub_module \
      --with-http_gunzip_module \
      --with-http_auth_request_module \
      --with-http_random_index_module \
      --with-http_secure_link_module \
      --with-http_degradation_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-pcre \
      --with-pcre-jit \
      --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -flto -funsafe-math-optimizations --param=ssp-buffer-size=4 -Wp,-D_FORTIFY_SOURCE=2 -DTCP_FASTOPEN=23' \
      --with-ld-opt='-Wl,-z,relro -Wl,-z,now -fPIC' \
      --with-http_slice_module \
      --with-http_flv_module \
      --with-http_mp4_module \
      --with-stream \
      --with-stream_realip_module \
      --with-stream_ssl_module \
      --with-stream_ssl_preread_module \
      --without-http_browser_module \
      --without-http_memcached_module \
      --without-http_split_clients_module \
      --without-http_userid_module && \
    make -j$(nproc) && \
    make install

#
# NGINX container based on NGINX builder
#
FROM debian:${DEBIAN_RELEASE} as nginx-image

LABEL stage="nginx-image" \
      description="Debian-based container with NGINX"

ARG CONTAINER_USER
ARG CONTAINER_GROUP

# copy NGINX installation structure from NGINX builder
# loops are still not supported in Dockerfile and any wrappers
# might eventually add unwanted layer of complexity,
# using sequence of copy instructions instead
# for simplicity in general
COPY --from=nginx-builder "/etc/nginx/" "/etc/nginx/"
COPY --from=nginx-builder "/run/nginx/" "/run/nginx/"
COPY --from=nginx-builder "/usr/lib/nginx/" "/usr/lib/nginx/"
COPY --from=nginx-builder "/usr/sbin/nginx" "/usr/sbin/nginx"
COPY --from=nginx-builder "/usr/share/nginx/" "/usr/share/nginx/"
COPY --from=nginx-builder "/var/lib/nginx/" "/var/lib/nginx/"
COPY --from=nginx-builder "/var/lock/nginx/" "/var/lock/nginx/"
COPY --from=nginx-builder "/var/log/nginx/" "/var/log/nginx/"

RUN groupadd --system --gid 1000 ${CONTAINER_USER} && \
    useradd --system --no-create-home --uid 1000 --gid ${CONTAINER_GROUP} ${CONTAINER_USER} && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
            ca-certificates \
            libc6 \
            libssl3 \
            libpcre3 \
            lsb-base \
            libgd3 \
            libgeoip1 \
            libxml2 \
            libxslt1.1 \
            zlib1g \
            file psmisc procps iproute2 net-tools less iputils-ping libcap2-bin nano bind9-dnsutils && \
    # cleanup
    apt-get autoremove -y && \
    apt-get autoclean && \
    apt-get clean && \
    rm -rf "/var/lib/apt/lists/*" && \
    # gain ability to allocate ports <1024 for container user
    setcap cap_net_bind_service=ep /usr/sbin/nginx && \
    # change ownerships to container user
    chown -vR ${CONTAINER_USER}:${CONTAINER_GROUP} /etc/nginx \
                                                   /etc/ssl \
                                                   /run/nginx \
                                                   /usr/lib/nginx \
                                                   /usr/sbin/nginx \
                                                   /usr/share/nginx \
                                                   /var/lib/nginx \
                                                   /var/log/nginx \
                                                   /var/lock/nginx

# ports
EXPOSE 80
EXPOSE 443

# container user
USER ${CONTAINER_USER}:${CONTAINER_GROUP}

# terminate by obtaining SIGQUIT signal
STOPSIGNAL SIGQUIT

# entrypoint with ability to pass argument(s) directly to nginx
ENTRYPOINT ["/usr/sbin/nginx"]
