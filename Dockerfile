################################################################################
###   base                                                                   ###


FROM  debian:10.6-slim  as  base

RUN  echo "deb http://deb.debian.org/debian buster-backports main" >>/etc/apt/sources.list  \
  &&  apt-get  update       \
  &&  apt-get  upgrade  -y  \
;


###   base                                                                   ###
################################################################################
################################################################################
###   build                                                                  ###


FROM  base  as  build

# software needed to build the application
RUN  apt-get  install  -y       \
    checkinstall                \
    git                         \
    gnome-common                \
    gnome-icon-theme            \
    libgconf2-dev               \
    libgio2.0-cil-dev           \
    libgstreamer1.0-dev         \
    libgtk2.0-dev               \
    libnotify-dev               \
    libunique-dev               \
    libxml2-dev                 \
  && apt-get  clean  autoclean  \
  && apt-get  autoremove  -y    \
  && rm  -rf  /var/lib/{apt,dpkg,cache,log}  \
;

WORKDIR  /build/

ARG  ORIGIN=https://github.com/joh/alarm-clock.git
ARG  COMMIT=7b876a1b688dc2da17220cc23d193aadaf0437d1
ARG  REQS="dbus-x11,gstreamer1.0-plugins-good,libgstreamer1.0-0,libgconf-2-4,libgtk2.0-0,libnotify4,libunique-1.0-0"
ARG  VERSION
ARG  RELEASE

# git clone specific commit, build .deb file
RUN  git  init                               \
  && git  remote  add  origin  $ORIGIN       \
  && git  fetch  --depth 1  origin  $COMMIT  \
  && git  reset  --hard  FETCH_HEAD          \
  && rm  -rf  ./.git/                        \
  && ./autogen.sh                            \
  && mkdir  -p /usr/local/etc/gconf/         \
  && checkinstall                            \
    --default                                \
    --install=no                             \
    --nodoc                                  \
    --pkgname=alarm-clock-applet             \
    --pkgversion="$VERSION"                  \
    --pkgrelease="$RELEASE"                  \
    --type=debian                            \
    --requires="$REQS"                       \
    make  install                            \
  && mv  $(ls /build/alarm-clock-applet_${VERSION}-${RELEASE}_*.deb)  /install.deb  \
  && rm  -rf  /build/                        \
;


###   build                                                                  ###
################################################################################
################################################################################
###   runtime                                                                ###


FROM  base  as  runtime

# install dependencies
RUN  apt-get  install  -y       \
    dbus-x11                    \
    gnome-audio                 \
    gstreamer1.0-plugins-good   \
    gstreamer1.0-pulseaudio     \
    libgstreamer1.0-0           \
    pulseaudio-utils            \
    sound-icons                 \
    libgconf-2-4                \
    libgtk2.0-0                 \
    libnotify4                  \
    libunique-1.0-0             \
  && apt-get  clean  autoclean  \
  && apt-get  autoremove  -y    \
  && rm  -rf  /var/lib/{apt,dpkg,cache,log}  \
;

# create some default directories the app wants
RUN  mkdir  -p  /usr/share/sounds/gnome/default    \
  && mkdir  -p  -m 0777  /home/user/.local/share/  \
  && ln  -s  /usr/share/sounds  /usr/share/sounds/gnome/default/alerts  \
;

# install app
COPY --from=build  /install.deb  /install.deb
RUN  apt-get  install -y  /install.deb  \
  && rm  -f  /install.deb               \
;

# runtime config
ARG      VERSION
ARG      RELEASE
ENV      ALARM_CLOCK_APPLET_VERSION=$VERSION-$RELEASE
ENV      HOME=/home/user
VOLUME   $HOME/.local/share/
WORKDIR  $HOME
CMD      /usr/local/bin/alarm-clock-applet
COPY     ./etc/pulse/client.conf  /etc/pulse/client.conf


###   runtime                                                                ###
################################################################################
