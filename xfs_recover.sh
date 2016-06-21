#!/bin/bash

dir_name=$1
xfsdevice=$2
tmp_file=$3

# Get the agblock size as we will need this for all files we recover.
agblocks=$(xfs_db -r $xfsdevice -c sb -c p | grep ^agblocks | sed 's/.* = //')
blksize=$(xfs_db -r $xfsdevice -c sb -c p | grep ^blocksize | sed 's/.* = //')

files=$(find $dir_name -size 0)

for f in $files
do
	echo $f

	# Getting the inode of the file we want to recover
	inode=$(ls -i $f | cut -f1 -d ' ')

	user=$(ls -l $f | cut -f3 -d ' ')
	group=$(ls -l $f | cut -f4 -d ' ')
	perm=$(stat -c "%a" $f)

	# Getting info on this inode
	dbinfo=$(xfs_db -r $xfsdevice -c "inode $inode" -c "bmap")

	# Grabbing field 6
	agoffset=$(echo $dbinfo | cut -f6 -d ' ')

	if [[ ! -z $agoffset ]];
	then

		# Removing head and tail parentheses
		agoffset=${agoffset//(}
		agoffset=${agoffset//)}
	
		agnumber=$(echo $agoffset | cut -f1 -d '/')
		offset=$(echo $agoffset | cut -f2 -d '/')
	
		#Grabbing field 8 which is the count.
		count=$(echo $dbinfo | cut -f8 -d ' ')
	
		# Copy file off of disk to a temp file.
		dd if=$xfsdevice bs=$blksize skip=$(($agblocks * $agnumber + $offset)) count=$count of=$tmp_file
	
		# Copy over permissions
		echo chown $user:$group $tmp_file
		echo chmod $perm $tmp_file
	
		# Copy file back.
		echo mv -f $tmp_file $f
	fi
done
