#!/bin/bash

variables() {
	clear
	echo "Warning: This is currently configured for UEFI systems only. Please quit if using legacy boot (CTRL+C). Press enter to continue..."
	read
	echo "Hostname?: "
	read hostname
	export hostname
	clear
	fdisk -l | grep "Disk /dev"
	echo "Boot disk? (Ex. /dev/sda): "
	read bootDisk
	export bootDisk
	clear
	echo "User name?: "
	read userName
	export userName
	clear
	echo "Do you already have your file system mounted? (y/N)"
	read mountBool
	if [ "$mountBool" != Y -o "$mountBool" != y ]
		then
		echo "Do you need to format your boot disk? (y/N)"
		read formatBool
		if [ "$formatBool" == Y -o "$formatBool" == y ]
			then
			fdisk $bootDisk
		fi
		echo "(1) Root only"
		echo "(2) Root and boot"
		echo "(3) Root, boot, and home"
		echo "(4) Root and home"
		echo " "
		echo "Enter: "
		read mountChoice
		clear
		echo "Enter your directories for mounting"
		if [ "$mountChoice" = "1" ]
			then
			echo "Root partition: "
			read rootPart
		elif [ "$mountChoice" = "2" ]
			then
			echo "Root partition: "
			read rootPart
			export rootPart
			echo " "
			echo "Boot partition: "
			read bootPart
		elif [ "$mountChoice" = "3" ]
			then
			echo "Root partition: "
			read rootPart
			export rootPart
			echo " "
			echo "Boot partition: "
			read bootPart
			export bootPart
			echo " "
			echo "Home partition: "
			read homePart
		elif [ "$mountChoice" = "4" ]
			then
			echo "Root partition: "
			read rootPart
			export rootPart
			echo " "
			echo "Home partition: "
			read homePart
		fi
	fi
	clear
	echo "Intel Graphics Drivers? (y/N): "
	read intelGfx
	export intelGfx
	echo "AMD Graphics Drivers? (y/N): "
	read amdGfx
	export amdGfx
	echo "Nvidia Graphics Drivers? (y/N): "
	read nvidiaGfx
	export nvidiaGfx
	clear
	echo "Create swapfile? (Y/n): "
	read swapfileChoice
	export swapfileChoice
	if [ "$swapfileChoice" == Y -o "$swapfileChoice" == y ]
		then
		echo "Where? (Ex. /swapfile or /home/swapfile): "
		read swapfile
		export swapfile
		echo "How big? (Ex. 512M or 4G): "
		read swapsize
		export swapsize
	fi
	clear
	echo "Pick a WM:"
	echo "(1) Budgie"
	echo "(2) KDE"
	echo "(3) Gnome"
	echo "(4) i3"
	echo "(5) XFCE"
	echo "(N) None"
	echo " "
	echo "Choice?: "
	read wmChoice
	export wmChoice
}

mounting() {
	clear
	echo "Mounting all directories..."
	if [ "$mountChoice" = "1" ]
		then
		mount $rootPart /mnt
	elif [ "$mountChoice" = "2" ]
		then
		mount $rootPart /mnt
		mkdir -p /mnt/boot/efi
		mount $bootPart /mnt/boot/efi
	elif [ "$mountChoice" = "3" ]
		then
		mount $rootPart /mnt
		mkdir -p /mnt/boot/efi
		mkdir /mnt/home
		mount $bootPart /mnt/boot/efi
		mount $homePart /mnt/home
	elif [ "$mountChoice" = "4" ]
		then
		mount $rootPart /mnt
		mkdir /mnt/home
		mount $homePart /mnt/home
	fi	
}


mirrors() {
	clear
	echo "Optimizing mirror list"	
	sed -i '1iServer = https://mirrors.kernel.org/archlinux/$repo/os/$arch' /etc/pacman.d/mirrorlist
	pacman -Syy reflector --noconfirm
	echo "Updating mirrors"
	reflector --protocol https --sort rate --save /etc/pacman.d/mirrorlist --verbose
}

install() {
	pacstrap /mnt base base-devel
	genfstab -U /mnt >> /mnt/etc/fstab
	if [ "$(uname -m)" = x86_64 ]
		then
		echo "[multilib]" >> /mnt/etc/pacman.conf
		echo "Include = /etc/pacman.d/mirrorlist" >> /mnt/etc/pacman.conf
	fi
	sed -i '37iILoveCandy' /mnt/etc/pacman.conf
	sed -i '33Color' /mnt/etc/pacman.conf
}

passtochroot() {
	cd /mnt/root
	wget https://raw.githubusercontent.com/soripants/arch/master/chroot.sh --no-cache
	chmod +x chroot.sh
	arch-chroot /mnt /bin/bash /root/chroot.sh
}

end() {
	echo "Reboot now? (y/N): "
	read rebchoice
	if [ "$rebchoice" == Y -o "$rebchoice" == y ]
		then
		reboot now
	fi
}

main() {
	variables	#Get information needed from user in the very beginning
	mounting	#Set up mounts
	mirrors		#Set up fastest mirrors for install process
	install 	#Perform the install process
	passtochroot 	#Run what is needed in chroot
	end		#Ask to reboot
}

main

