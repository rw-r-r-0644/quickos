#!/bin/sh
set -e
. ./build.sh

mkdir -p isodir
mkdir -p isodir/boot
mkdir -p isodir/boot/grub

cp sysroot/boot/quickos.kernel isodir/boot/quickos.kernel
cat > isodir/boot/grub/grub.cfg << EOF
menuentry "quickos" {
	multiboot /boot/quickos.kernel
}
EOF
grub-mkrescue -o quickos.iso isodir
