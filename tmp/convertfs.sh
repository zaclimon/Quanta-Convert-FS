#!/sbin/sh
#
#
# Ext4/F2FS converter script for Quanta Kernel
# Detects the current filesystem and convert /cache and /data to their filesystem counterpart
# Made by Isaac Pateau (zaclimon)
#
# Version 1.0
#

DATA_FS_TYPE=`grep /data /etc/mtab | cut -d " " -f3`
DATA_PARTITION=`grep /data /etc/mtab | cut -d " " -f1`
CACHE_PARTITION=`grep /cache /etc/mtab | cut -d " " -f1`

# Preparing...
cd /tmp
chmod 0755 mkfs.f2fs
chmod 0755 make_ext4fs

# Safety first
if grep -q "/data" /etc/mtab ; then
umount $DATA_PARTITION
fi

# Same as above
if grep -q "/cache" /etc/mtab ; then
umount $CACHE_PARTITION
fi

# Convert the partition based mostly on the /data filesystem type­.
if [ $DATA_FS_TYPE = "ext4" ] ; then
./mkfs.f2fs $DATA_PARTITION
./mkfs.f2fs $CACHE_PARTITION
NEW_FS_TYPE="f2fs"
elif [ $DATA_FS_TYPE = "f2fs" ] ; then
./make_ext4fs $DATA_PARTITION
./make_ext4fs $CACHE_PARTITION
NEW_FS_TYPE="ext4"
fi

# Output the new fs into a file so it can be read by the fstab modifier after.
echo $NEW_FS_TYPE > /tmp/newfstype

# Exit when everything looks fine.
exit 0
