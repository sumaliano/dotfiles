
#### Change linux LTS kernel

    1. basicly just install `pacman -S linux-lts`

    3. (optional) check if kernel, ramdisk and fallback are available in `ls -lsha /boot`

	4. remove the standard kernel `pacman -R linux`

	5. update the grub config `grub-mkconfig -o /boot/grub/grub.cfg`
	
	6. `reboot`

