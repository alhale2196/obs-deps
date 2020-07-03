#!/usr/bin/env bash

set -eE

PRODUCT_NAME="OBS Pre-Built Dependencies"

COLOR_RED=$(tput setaf 1)
COLOR_GREEN=$(tput setaf 2)
COLOR_BLUE=$(tput setaf 4)
COLOR_ORANGE=$(tput setaf 3)
COLOR_RESET=$(tput sgr0)

export MAC_QT_VERSION="5.14.1"
export WIN_QT_VERSION="5.10"
export LIBPNG_VERSION="1.6.37"
export LIBOPUS_VERSION="1.3.1"
export LIBOGG_VERSION="68ca3841567247ac1f7850801a164f58738d8df9"
export LIBVORBIS_VERSION="1.3.6"
export LIBVPX_VERSION="1.8.2"
export LIBJANSSON_VERSION="2.12"
export LIBX264_VERSION="origin/stable"
export LIBMBEDTLS_VERSION="2.16.5"
export LIBSRT_VERSION="1.4.1"
export FFMPEG_VERSION="4.2.2"
export LIBLUAJIT_VERSION="2.1.0-beta3"
export LIBFREETYPE_VERSION="2.10.1"
export SWIG_VERSION="3.0.12"
export MACOSX_DEPLOYMENT_TARGET="10.13"
export PATH="/usr/local/opt/ccache/libexec:${PATH}"
export CURRENT_DATE="$(date +"%Y-%m-%d")"
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:/tmp/obsdeps/lib/pkgconfig"
export PARALLELISM="$(sysctl -n hw.ncpu)"

hr() {
     echo -e "${COLOR_BLUE}[${PRODUCT_NAME}] ${1}${COLOR_RESET}"
}

step() {
    echo -e "${COLOR_GREEN}  + ${1}${COLOR_RESET}"
}

info() {
    echo -e "${COLOR_ORANGE}  + ${1}${COLOR_RESET}"
}

error() {
     echo -e "${COLOR_RED}  + ${1}${COLOR_RESET}"
}

exists() {
    command -v "${1}" >/dev/null 2>&1
}

ensure_dir() {
    [[ -n ${1} ]] && /bin/mkdir -p ${1} && builtin cd ${1}
}

cleanup() {
    :
}

mkdir() {
    /bin/mkdir -p $*
}

trap cleanup EXIT

caught_error() {
    error "ERROR during build step: ${1}"
    cleanup $/home/runner/work/obs-deps/obs-deps
    exit 1
}

build_bff8b464-21b7-4ce8-b19c-c41ff8e84acd() {
    step "Install Homebrew dependencies"
    trap "caught_error 'Install Homebrew dependencies'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps

    brew bundle
}


build_245d62f1-377d-47fd-a7d4-1a6f0fd23998() {
    step "Get Current Date"
    trap "caught_error 'Get Current Date'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps


}


build_1297205c-3650-4b7e-bd25-b78992d7bcce() {
    step "Build environment setup"
    trap "caught_error 'Build environment setup'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps

    mkdir -p CI_BUILD/obsdeps/bin
    mkdir -p CI_BUILD/obsdeps/include
    mkdir -p CI_BUILD/obsdeps/lib
    
    
}


build_15e31178-ba46-4371-a5da-d11df0935f3b() {
    step "Build dependency Qt"
    trap "caught_error 'Build dependency Qt'" ERR
    ensure_dir /home/runner/work/obs-deps/obs-deps/CI_BUILD

    if [ -d /usr/local/opt/zstd ]; then
      brew unlink zstd
    fi
    
    curl --retry 5 -L -C - -O "https://download.qt.io/official_releases/qt/$(echo "${MAC_QT_VERSION}" | cut -d "." -f -2)/${MAC_QT_VERSION}/single/qt-everywhere-src-${MAC_QT_VERSION}.tar.xz"
    tar -xf qt-everywhere-src-${MAC_QT_VERSION}.tar.xz
    if [ "${MAC_QT_VERSION}" = "5.14.1" ]; then
        cd qt-everywhere-src-${MAC_QT_VERSION}/qtbase
        git apply /home/runner/work/obs-deps/obs-deps/patch/qt/qtbase.patch
        cd ..
    fi
    mkdir build
    cd build
    if [ ! -n "${CI}" ]; then
      WITH_CCACHE=" -ccache"
    fi
    ../configure ${WITH_CCACHE} --prefix="/tmp/obsdeps" -release -opensource -confirm-license -system-zlib \
      -qt-libpng -qt-libjpeg -qt-freetype -qt-pcre -nomake examples -nomake tests -no-rpath -pkg-config -dbus-runtime \
      -skip qt3d -skip qtactiveqt -skip qtandroidextras -skip qtcharts -skip qtconnectivity -skip qtdatavis3d \
      -skip qtdeclarative -skip qtdoc -skip qtgamepad -skip qtgraphicaleffects -skip qtlocation \
      -skip qtlottie -skip qtmultimedia -skip qtnetworkauth -skip qtpurchasing -skip qtquick3d \
      -skip qtquickcontrols -skip qtquickcontrols2 -skip qtquicktimeline -skip qtremoteobjects \
      -skip qtscript -skip qtscxml -skip qtsensors -skip qtserialbus -skip qtspeech \
      -skip qttranslations -skip qtwayland -skip qtwebchannel -skip qtwebengine -skip qtwebglplugin \
      -skip qtwebsockets -skip qtwebview -skip qtwinextras -skip qtx11extras -skip qtxmlpatterns
    make -j${PARALLELISM}
    make install
}


build_005161ca-4d4e-4fe0-a117-c8b8ec45515c() {
    step "Package dependencies"
    trap "caught_error 'Package dependencies'" ERR
    ensure_dir /tmp

    tar -czf macos-qt-${MAC_QT_VERSION}-${CURRENT_DATE}.tar.gz obsdeps
    if [ ! -d "/home/runner/work/obs-deps/obs-deps/macos" ]; then
      mkdir /home/runner/work/obs-deps/obs-deps/macos
    fi
    mv macos-qt-${MAC_QT_VERSION}-${CURRENT_DATE}.tar.gz /home/runner/work/obs-deps/obs-deps/macos
}


obs-deps-build-main() {
    ensure_dir /home/runner/work/obs-deps/obs-deps

    build_bff8b464-21b7-4ce8-b19c-c41ff8e84acd
    build_245d62f1-377d-47fd-a7d4-1a6f0fd23998
    build_1297205c-3650-4b7e-bd25-b78992d7bcce
    build_15e31178-ba46-4371-a5da-d11df0935f3b
    build_005161ca-4d4e-4fe0-a117-c8b8ec45515c

    hr "All Done"
}

obs-deps-build-main $*