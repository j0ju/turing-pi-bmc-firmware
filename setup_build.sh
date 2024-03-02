#!/bin/sh
# This script downloads, unpacks and installs the buildroot system to a given
# location. The default install location will be used when no install dir is
# passed, this is the root directory of this repository.
#
# Usage:
#
#   ./setup_build.sh <install dir> (optional)
#
set -e
set -x

download_dir=$(mktemp -d)
install_dir="$1"
buildroot_url='https://buildroot.org/downloads/buildroot-2024.02.tar.gz'
buildroot=$(basename "$buildroot_url")
buildroot_folder="${buildroot%.tar.gz}"
project_root="$(cd "$(dirname "$0")"; pwd)"

(   cd "$download_dir"
    wget -c "$buildroot_url" -O "${buildroot_url##*/}"
    sha256sum -c "${project_root}/${buildroot_url##*/}".sha256sum
    tar -xvf "$buildroot"
)

if [ -z "$install_dir" ]; then
    # try to install it into the base-dir of the git repo
    install_dir="$project_root"
fi

if [ -e "$install_dir/buildroot" ]; then
    rm -rf "$install_dir/buildroot"
fi

mv "$download_dir/$buildroot_folder" "$install_dir/buildroot"

(   cd "$install_dir/buildroot"
    for patchfile in "$project_root"/buildroot_patches/*; do
        if [ -f "$patchfile" ]; then
            patch -p1 < "$patchfile"
        fi
    done
    make BR2_EXTERNAL=../tp2bmc tp2bmc_defconfig
)
