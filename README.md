# xfs_recover.sh

Bash script for recovering zero size files due to kernel panic and XFS corruption.

## Description

This script is designed to recover zero size files caused by XFS corruption due to kernel panic.  Technical details about the kernel bug can be found here:

http://oss.sgi.com/archives/xfs/2012-02/msg00517.html

Basically the symptoms of the problem are that after a system crash you have files on a XFS filesystem that show up under file `stat` or `ls` that have metadata but no size.  However if you do a `du` you find that they actually do have size.  If you look at the file itself it shows up as empty.  This shows that the metadata for the XFS file is corrupt as the system did not flush the data to disk before it crashed.

The bug is fixed in newer versions of the kernel so it is advised you upgrade to avoid this bug in the future.  However, running `xfs_repair` or other built in automatic utilities will not fix the already corrupted files.  All hope is not lost though.  The data is still on the disk, its only the metadata that is corrupt.  Following the results of this discussion:

http://oss.sgi.com/archives/xfs/2012-02/msg00561.html

I've written a script which will search the filesystem, find these files, and then pull the data off of disk to recover the file.  Please be sure to read the script before you run it.  If you have improvements please feel free to contribute.

## Usage

You can run the script as follows:

`xfs_recover.sh dir_name xfsdevice tmp_file`

Where:

`dir_name`: Is the directory you wish to recover.
`xfsdevice`: Is the device name of the XFS device your directory lives on (this is not the mount point but the actual `/dev`)
`tmp_file`: Is the temporary file that the data for the file to be recovered is dumped to.  It is recommended that you have this location be on a disk that is large enough to handle the largest file you wish to recover.  This is only a temporary file.  It will be destroyed once the file is recovered.

The script itself takes the inputs and looks up the info on the XFS filsystem.  It then runs `find` to find all the files of zero size.  It is assumed that all files with zero size need to be recovered.  It then walks each file, grabbing its inode number and permissions.  It then uses `xfs_db` to get essential data about the physical location of the file on the disk.  If it is recoverable it will `dd` the data to the `tmp_file` and once complete set the permissions.  It will then move that file back to its original location.  Note this will overwrite the original file, thus there will be no further recovery attempts possible.  Thus it is best to try a few test files first, or modify the script to not copy back the file.

Use this script at your own peril.  It does not have many safety measures in it.  I am not responsible if the script goes haywire or data being lost.  Backup whatever data you can prior to running this script.  That said this script has worked well in my own usage and it should save time in trying to write one yourself.

## Other Resources

PHP Version of Script: https://github.com/odoucet/xfsrepair

