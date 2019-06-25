```sh
# /etc/fstab: static file system information.
#
# Use 'blkid -o value -s UUID' to print the universally unique identifier
# for a device; this may be used with UUID= as a more robust way to name
# devices that works even if disks are added and removed. See fstab(5).
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
proc            /proc           proc    nodev,noexec,nosuid 0       0
# / was on /dev/md3 during installation
UUID=07ff3477-49eb-4ea2-aafc-c24e36483f3b /               ext4    errors=remount-ro 0       1
# /boot was on /dev/md0 during installation
UUID=8497c10a-8aac-4487-9fe9-9a08643a1f25 /boot           ext2    defaults        0       2
# /data was on /dev/md4 during installation
UUID=1d651234-09a9-42f3-b56f-763a347656db /data           ext4    defaults,noatime,nodiratime        0       2
# /home was on /dev/md1 during installation
UUID=e048d8e4-24d8-4ad3-8425-b4ab44130c70 /home           ext4    defaults        0       2
# /var was on /dev/md2 during installation
UUID=ddee357b-ecd7-4729-8ca6-4590a6393751 /var            ext4    defaults,noatime,nodiratime        0       2
# swap was on /dev/md5 during installation
UUID=f12863b0-88a5-4639-a575-fbcaa54b34c9 none            swap    sw              0       0

# /data2 is on /dev/md6
UUID=200bcbd9-4cbd-4b22-81dc-4db335179411 /data2	ext4	defaults,noatime,nodiratime,data=writeback,errors=remount-ro

# Data directory remote mount from lx-pool.gsi.de
sshfs#land@lx-pool.gsi.de:/d  /d fuse allow_other,_netdev,noauto,user,noatime 0 0
# Lustre file system mount from lxg0899.gsi.de
sshfs#land@lxg0897.gsi.de:/lustre /lustre.sshfs fuse allow_other,_netdev,noauto,user,noatime  0 0
# Hera file system mount from lxldatamover02 (via ssh)
sshfs#land@lxldatamover02.gsi.de:/hera /hera fuse idmap=user,allow_other,_netdev,noauto,user,gid=1119,noatime  0 0
# Lustre file system mount via NFS
lxnfsl01.gsi.de:/lustre /lustre nfs soft,intr,user 0 0
# Haakan's home mount from lx-pool.gsi.de as land
sshfs#land@lx-pool.gsi.de:/u/johansso /u.johansso fuse allow_other,_netdev,noauto,user,noatime  0 0
# Land home mount from lx-pool.gsi.de as land
sshfs#land@lx-pool.gsi.de:/u/land /u.land fuse allow_other,_netdev,noauto,user,noatime  0 0

# /data.esata on external drive
UUID="3E04-830D" /data.esata vfat defaults,exec,noatime,user,noauto 0 0

# /data.simulation on external drive
UUID="5531955F65B0D556" /data.simulation ntfs defaults,user,permissions,exec,noatime,noauto 0 0

# /data.usb on external drive
UUID="1C6D-58FC" /data.usb vfat defaults,exec,noatime,user,noauto 0 0

# /data.munich110707 on external drive
UUID="1F5D56F1436AD0FE" /data.munich110707 ntfs defaults,exec,noatime,user,noauto 0 0

UUID="1C6D-58FC"  /data.ikp2011 vfat  defaults,exec,noatime,user,noauto,ro  0 0
UUID="B3D5-7A14" /data.duke2012 vfat defaults,exec,noatime,user,noauto,ro 0 0
UUID="32D7-6501" /data.duke2012_2 vfat defaults,exec,noatime,user,noauto,ro 0 0
UUID="3860205260201960" /data.duke2013 ntfs defauts,exec,noatime,user,noauto,ro  0 0
UUID="145a032d-9108-4f46-ac24-4d2f36578682" /data.duke2013_2 ext3 defaults,exec,noatime,user,noauto,ro 0 0
```
