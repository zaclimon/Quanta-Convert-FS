#!/sbin/sh
#
#
# Fstab Ext4/F2FS modifier for Quanta Kernel
# Modifies an fstab according to a new filesystem conversion
# Made by Isaac Pateau (zaclimon)
#
# Version 1.2
#

# Define the attributes now
DEVICE=`find fstab.* | cut -d . -f2`
FSTAB=`find fstab.*`
FS_TYPE=`cat /tmp/newfstype`
BOOT_PARTITION=`grep /boot $FSTAB | cut -d " " -f1`

# Preparing...
cd /tmp
chmod 0755 unpackbootimg
chmod 0755 mkbootimg

# Unpack the kernel.
dd if=$BOOT_PARTITION of=boot.img
./unpackbootimg -i boot.img

# Define the kernel's attributes for the repacking.
KERNEL_CMDLINE=`cat boot.img-cmdline | sed 's/.*/"&"/'`
KERNEL_BASE=`cat boot.img-base`
KERNEL_PAGESIZE=`cat boot.img-pagesize`
KERNEL_OFFSET=`cat boot.img-kerneloff`
RAMDISK_OFFSET=`cat boot.img-ramdiskoff`

# Continue with the unpacking...
mkdir ramdisk
cd ramdisk
gzip -dc ../boot.img-ramdisk.gz | cpio -i

# Let's change the values. Don't bother checking /cache as the purpose of this script is converting both /data and /cache.
if [ $FS_TYPE = "f2fs" ] ; then
sed '/userdata/ s/ext4.*/f2fs    noatime,nosuid,nodev,discard,nodiratime,inline_xattr,inline_data,nobarrier,active_logs=4       wait,check,encryptable=\/dev\/block\/platform\/msm_sdcc.1\/by-name\/metadata/' -i $FSTAB
sed '/cache/ s/ext4.*/f2fs noatime,nosuid,nodev,discard,nodiratime,inline_xattr,inline_data,nobarrier,active_logs=4       wait,check/' -i $FSTAB
elif [ $FS_TYPE = "ext4" ] ; then
sed '/userdata/ s/f2fs.*/ext4    noatime,nosuid,nodev,barrier=1,data=ordered,noauto_da_alloc    wait,check,encryptable=\/dev\/block\/platform\/msm_sdcc.1\/by-name\/metadata/' -i $FSTAB
sed '/cache/ s/f2fs.*/ext4    noatime,nosuid,nodev,barrier=1,data=ordered    wait,check/' -i $FSTAB
fi

# Repack the kernel. Looks like we have to put the mkbootimg command in a separate script because it doesn't look like it is possible to parse the cmdline into the "raw command".
find . | cpio --create --format='newc' | gzip > ../ramdisk.gz
cd ..
echo "#!/sbin/sh" > /tmp/modifiedquanta.sh
echo "./mkbootimg --kernel boot.img-zImage --ramdisk ramdisk.gz --cmdline $KERNEL_CMDLINE --base $KERNEL_BASE --pagesize $KERNEL_PAGESIZE --kernel_offset $KERNEL_OFFSET --ramdisk_offset $RAMDISK_OFFSET -o quantaboot.img" >> modifiedquanta.sh
. /tmp/modifiedquanta.sh

# Flash the new kernel
dd if=/tmp/quantaboot.img of=$BOOT_PARTITION

# Finish when everything is done.
exit 0
