FROM openresty/openresty:alpine-fat

# Usamos el árbol por defecto del sistema
ENV TREE=/usr/local

# Configurar rutas explícitamente (aunque OpenResty ya las conoce)
ENV LUA_PATH="$TREE/share/lua/5.1/?.lua;$TREE/share/lua/5.1/?/init.lua;;"
ENV LUA_CPATH="$TREE/lib/lua/5.1/?.so;;"

RUN apk add --no-cache \
    build-base \
    openssl \
    git \
    luarocks

# Instalar módulos Lua
RUN luarocks --tree=$TREE install lua-resty-http && \
    luarocks --tree=$TREE install lua-resty-jwt && \
    luarocks --tree=$TREE install lua-resty-openssl

# Carpeta para scripts propios
RUN mkdir -p /etc/openresty/lua

EXPOSE 80 443

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]