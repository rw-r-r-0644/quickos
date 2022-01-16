#!/bin/sh
set -e
. ./iso.sh

qemu-system-$(./target-triplet-to-arch.sh $HOST) -s -S -cdrom quickos.iso &
$GDB \
	-ex "target remote localhost:1234" \
	-ex "symbol-file isodir/boot/quickos.kernel"
trap 'kill $(jobs -p)' EXIT
