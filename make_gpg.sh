#!/bin/bash
filename=secrets.tar.gz.gpg
dir_to_encrypt=secrets
GPG_TTY=$(tty)

create_secrets() {
	tar -czvf - $dir_to_encrypt | gpg -c > $filename
}

expand_secrets() {
	gpg -d $filename | tar -xvzf -
}

backup_secrets() {
	rclone copy $filename GDrive:/security
}

restore_secrets() {
	rclone copy GDrive:/security/$filename .
}

echo filename: $filename 
echo dir_to_encrypt: $dir_to_encrypt 
echo command: $1

$1
