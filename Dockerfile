ARG DEBIAN_VERSION=13.7-slim
FROM debian:$DEBIAN_VERSION
LABEL org.opencontainers.image.authors="drpsychick@drsick.net"
LABEL org.opencontainers.image.description="SteamCMD with steam user (prerequisite for game servers)"
LABEL org.opencontainers.image.source="https://github.com/HomeLabHD/SteamCMD"

ARG DEBIAN_VERSION=13.7-slim
# Debian-slim base: keeps glibc (steamcmd + game servers are glibc/i386 binaries) but drops the
# heavier Ubuntu surface — notably Ubuntu 26.04's bundled /usr/bin/pebble (a Go binary that carried
# every HIGH CVE and which game-server containers never use).
# i386 is required until steamcmd is amd64 and games no longer need i386 libs.
# steamcmd lives in Debian non-free (installer in contrib); enable those components in the deb822
# sources, then upgrade + install.
RUN dpkg --add-architecture i386 \
    && sed -i 's/^Components: main$/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources \
    && apt-get update && apt-get upgrade -y \
    && echo steam steam/question select "I AGREE" | debconf-set-selections \
    && echo steam steam/license note '' | debconf-set-selections \
    && apt-get install -y --no-install-recommends ca-certificates steamcmd locales lib32gcc-s1 \
    && sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

RUN ln -sf /usr/games/steamcmd /usr/local/bin/steamcmd
RUN useradd -m steam

WORKDIR /home/steam
USER steam

# install steamcmd and remove downloaded packages to reduce image size
RUN steamcmd +quit \
    && rm -rf /home/steam/.local/share/Steam/steamcmd/package/*.zip.*
