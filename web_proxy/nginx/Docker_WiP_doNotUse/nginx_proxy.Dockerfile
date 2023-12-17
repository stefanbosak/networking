#
# NGINX builder
#
FROM debian:testing-slim as _nginx_proxy_builder

# Predefined NGINX version
#
# for HTTP3 support required version >=1.25
#
ARG version=1.25.3

# skip terminal requests
ARG DEBIAN_FRONTEND=noninteractive

# prepare sandbox
WORKDIR /tmp

RUN mkdir /app /tmp/nginx /var/log/nginx /usr/share/nginx /run/nginx /var/lock/nginx /var/lib/nginx /usr/lib/nginx && \
    addgroup --system --gid 1000 nginxuser && \
    adduser --system --disabled-login --ingroup nginxuser --no-create-home --gecos "nginxuser" --shell /bin/false --uid 1000 nginxuser && \
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
    wget https://nginx.org/download/nginx-${version}.tar.gz -O nginx.tar.gz && \
    tar -xzvf nginx.tar.gz -C /tmp/nginx --strip-components=1

# Build NGINX
WORKDIR /tmp/nginx

RUN ./configure \
      --user=nginxuser \
      --group=nginxuser \
      --build="TFO custom build $(date +%d-%b-%Y)" \
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
      --with-stream \
      --with-stream_ssl_module \
      --with-pcre \
      --with-pcre-jit \
      --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -flto -funsafe-math-optimizations --param=ssp-buffer-size=4 -Wp,-D_FORTIFY_SOURCE=2 -DTCP_FASTOPEN=23' \
      --with-ld-opt='-Wl,-z,relro -Wl,-z,now -fPIC' \
      --with-http_slice_module \
      --without-http_browser_module \
      --without-http_geo_module \
      #--without-http_limit_req_module \
      #--without-http_limit_conn_module \
      --without-http_memcached_module \
      --without-http_referer_module \
      --without-http_split_clients_module \
      --without-http_userid_module && \
    make -j$(nproc) && \
    make install && \
    # change ownerskips to nginxuser (access for nginxuser)
    chown -R nginxuser:nginxuser /var/log/nginx \
                                 /usr/share/nginx \
                                 /run/nginx \
                                 /var/lock/nginx \
                                 /var/lib/nginx \
                                 /usr/lib/nginx \
                                 /etc/nginx && \
    # recursive copy installation to /app directory (required by NGINX server container)
    # using cp instead of COPY or mv is required due to design limitation of Dockerfile
    cp --parents -R /etc/nginx /var/lib/nginx /usr/lib/nginx /usr/sbin/nginx /app/ && \
    # cleanup
    apt-get autoremove -y && \
    apt-get autoclean && \
    rm -rf /tmp/*


#
# NGINX server based on NGINX builder
#
FROM debian:testing-slim as _nginx_proxy

WORKDIR /

# skip terminal requests
ARG DEBIAN_FRONTEND=noninteractive

# prepare sandbox
RUN set -x && \
    mkdir /app /var/log/nginx /usr/share/nginx /run/nginx /var/lock/nginx /var/lib/nginx /usr/lib/nginx && \
    addgroup --system --gid 1000 nginxuser && \
    adduser --system --disabled-login --ingroup nginxuser --no-create-home --gecos "nginxuser" --shell /bin/false --uid 1000 nginxuser && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
            ca-certificates \
            libc6 \
            libssl1.1 \
            libpcre3 \
            lsb-base \
            libgd3 \
            libgeoip1 \
            libxml2 \
            libxslt1.1 \
            zlib1g \
            file psmisc procps iproute2 net-tools less iputils-ping libcap2-bin nano bind9-dnsutils

# copy NGINX installation structure from NGINX builder
COPY --from=_nginx_proxy_builder /app /

# Cleanup after Nginx build
RUN apt-get autoremove -y && \
    apt-get autoclean && \
    apt-get clean && \
    rm -rf /tmp/* && \
    # gain ability to allocate ports <1024 for nginxuser
    setcap cap_net_bind_service=ep /usr/sbin/nginx && \
    # symboliclink to be capable with cloud docker wrappers
    ln -s /usr/sbin/nginx /app/_nginx_proxy && \
    # change ownerskips to nginxuser (access for nginxuser)
    chown -R nginxuser:nginxuser /var/log/nginx \
                                 /usr/share/nginx \
                                 /run/nginx \
                                 /var/lock/nginx \
                                 /var/lib/nginx \
                                 /usr/lib/nginx \
                                 /etc/nginx \
                                 /etc/ssl \
                                 /app/_nginx_proxy

# ports
EXPOSE 80
EXPOSE 443

USER nginxuser

STOPSIGNAL SIGQUIT

# entrypoint with ability to pass argument directly to nginx
ENTRYPOINT ["/usr/sbin/nginx"]
