# Qemu examples

#### create image
	qemu-img create win7.raw 50G

#### install windows 7
	qemu-system-x86_64 -enable-kvm -m 2048 -cdrom win7_dell.iso -boot d win7.raw 

#### run qemu
	qemu-system-x86_64 -enable-kvm win7.raw -boot c -net nic -net user -m 2048 -localtime
