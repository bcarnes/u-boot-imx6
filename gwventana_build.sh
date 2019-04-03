#!/bin/bash
set -euxo pipefail

check_installed() {
    needed=()
    for pkg; do
	if ! dpkg -s "${pkg}" &>/dev/null; then
	    needed+=("${pkg}")
	fi
    done
    if (( ${#needed[@]} )); then
	echo "Missing dependencies:"
	echo "  apt-get install -y ${needed[@]}"
	return 1
    fi
}
    
prereqs=(
  build-essential
  gcc-arm-linux-gnueabihf
)

check_installed "${prereqs[@]}"

export CROSS_COMPILE=arm-linux-gnueabihf-

make gwventana_config
cat <<EOF | tee -a .config
CONFIG_EFI_PARTITION=y
CONFIG_FS_BTRFS=y
CONFIG_CMD_BTRFS=y
EOF
make olddefconfig
make -j$(nproc)

mkdir -p install/{boot,etc}

./mkimage_jtag SPL u-boot.img > install/boot/u-boot_spl.bin

cp SPL u-boot.img install/boot/

cat <<EOF > install/etc/fw_env.config
# device  offset size erasesize
/dev/mmcblk0 0xb1400 0x20000 0x20000
/dev/mmcblk0 0xd1400 0x20000 0x20000
EOF
