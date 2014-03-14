#!/sbin/busybox sh
#Civic-boot script
set +x
_PATH="$PATH"
export PATH=/sbin
busybox cd /
busybox rm /init

# include device specific vars
source /sbin/bootrec-device

# create directories
busybox mkdir -m 755 -p /cache
busybox mkdir -m 755 -p /dev/block
busybox mkdir -m 755 -p /dev/input
busybox mkdir -m 555 -p /proc
busybox mkdir -m 755 -p /sys

# create device nodes
busybox mknod -m 600 /dev/block/mmcblk0 b 179 0
busybox mknod -m 600 ${BOOTREC_CACHE_NODE}
busybox mknod -m 600 ${BOOTREC_EVENT_NODE}
busybox mknod -m 666 /dev/null c 1 3

# mount filesystems
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys
busybox mount -t ext4 ${BOOTREC_CACHE} /cache

# trigger amber LED
busybox echo 255 > ${BOOTREC_LED_RED}
busybox echo 0 > ${BOOTREC_LED_GREEN}
busybox echo 255 > ${BOOTREC_LED_BLUE}

# keycheck
busybox cat ${BOOTREC_EVENT} > /dev/keycheck&
busybox sleep 2

# Turn off LED
busybox echo 0 > ${BOOTREC_LED_RED}
busybox echo 0 > ${BOOTREC_LED_GREEN}
busybox echo 0 > ${BOOTREC_LED_BLUE}

# Load ramdisk
load_image=/sbin/ramdisk.cpio.xz

# boot decision
if [ -s /dev/keycheck -o -e /cache/recovery/boot ]
then
	busybox rm -f /cache/recovery/boot
	# Cyan led for TWRP boot
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
	busybox echo 0 > ${BOOTREC_LED_RED}
	busybox echo 255 > ${BOOTREC_LED_GREEN}
	busybox echo 255 > ${BOOTREC_LED_BLUE}
        busybox echo 100 > ${BOOTREC_VIBRATOR}
	# TWRP ramdisk
	load_image=/sbin/twrp.cpio.xz
fi

# kill the keycheck processes first
busybox pkill -f "busybox cat ${BOOTREC_EVENT}"

#Red led for booting into CWM
busybox echo 255 > ${BOOTREC_LED_RED}
busybox echo 0 > ${BOOTREC_LED_GREEN}
busybox echo 0 > ${BOOTREC_LED_BLUE}

#keycheck for cwm
busybox cat ${BOOTREC_EVENT} > /dev/keycheck&
busybox sleep 2

if [ -s /dev/keycheck -o -e /cache/recovery/boot ]
then
	busybox rm -f /cache/recovery/boot
    	# Blue led for CWM boot
        busybox echo 0 > /sys/module/msm_fb/parameters/align_buffer
	busybox echo 0 > ${BOOTREC_LED_RED}
	busybox echo 0 > ${BOOTREC_LED_GREEN}
	busybox echo 255 > ${BOOTREC_LED_BLUE}
        busybox echo 100 > ${BOOTREC_VIBRATOR}
	# CWM ramdisk
	load_image=/sbin/cwm.cpio.xz
fi

busybox sleep 2	
# poweroff LED
busybox echo 0 > ${BOOTREC_LED_RED}
busybox echo 0 > ${BOOTREC_LED_GREEN}
busybox echo 0 > ${BOOTREC_LED_BLUE}


# kill the keycheck processes
busybox pkill -f "busybox cat ${BOOTREC_EVENT}"

# unpack the ramdisk image
busybox xzcat ${load_image} | busybox cpio -i

busybox umount /cache
busybox umount /proc
busybox umount /sys

busybox rm -fr /dev/*
export PATH="${_PATH}"
exec /init
