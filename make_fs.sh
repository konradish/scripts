#!/bin/bash
filename=secrets.dat
megs=20
loop=/dev/loop0
mount_point=./secrets_map

create() {
	losetup -d $loop
	fallocate -l ${megs}M $filename
	losetup $loop $filename
	cryptsetup -y luksFormat $loop
	cryptsetup luksOpen $loop secrets
	mkfs.ext4 /dev/mapper/secrets
	cryptsetup close secrets
	losetup -d $loop
}

mount_lo() {
	losetup $loop $filename && \
	cryptsetup luksOpen $loop secrets && \
	mount /dev/mapper/secrets $mount_point
}

unmount_lo() {
	umount $mount_point
	cryptsetup close secrets
	losetup -d $loop
}

backup() {
	rclone copy $filename GDrive:/security
}

restore() {
	rclone copy GDrive:/security/$filename .
}

echo filename $filename 
echo megs $megs 
echo loop $loop 
echo mount_point $mount_point 
echo command $1

$1
