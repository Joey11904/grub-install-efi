#! /bin/bash

# Parsing long command-line arguments with getopt
# https://www.shellscript.sh/tips/getopt/index.html

# TODO: add other EFI arches like arm, arm64, riscv, etc
#		use `case` argument when implementing it 

help_msg() {
	echo "
Usage: grub-install-efi [options]
	
	Options:
	[ -p | --partition </dev/sdXY> ]      Specifies EFI partition to install GRUB
	[ -d | --directory </path/to/dir> ]   Specifies path to mount EFI partition
	[ -a | --architecture <type> ]        Specifies the system architecture; <type> can be:

	                                      <x32>	Intel/AMD 32-bit
	                                      <x64>	Intel/AMD 64-bit
	                                      <a32>	ARM 32-bit
	                                      <a64>	ARM 64-bit

	                                      Will try to autodetect if not specified

	[ -r | --removable ]                  Allows swapping disks between systems
	[ -h | --help ]                       Show this help message
	
Example:             grub-install-efi --partition /dev/sda1 --directory /boot/efi --architecture x64 --removable
Short version:       grub-install-efi -p sda1 -d /boot/efi -a x64 -r
Supershort version:  grub-install-efi -rp sda1
	"
	exit
}

if [[ $@ == '' ]]; then
	echo ""
	echo "No arguments given. Aborting."
	help_msg
fi

ARGS=$(getopt -n grub-install-efi -l architecture:,removable,partition:,directory:,help -o a:d:rhp: -- "$@")
VALID_ARGS=$?

if [[ "$VALID_ARGS" != 0 ]]; then
	help_msg
fi

eval set -- "$ARGS"

while :
do
	case "$1" in

		'-p' | '--partition')
		
			if [[ "$2" == '/dev/'* ]]; then
				partition="$2"
			else
				partition="/dev/$2"
			fi;
			
			shift 2
			;;
			
		'-d' | '--directory')
			installdir="$2"
			shift 2
			;;
			
		'-a' | '--architecture')
			case "$2" in
				'x32')
					arch='i386-efi'
					shift
					;;
					
				'x64')
					arch='x86_64-efi'
					shift
					;;
					
				'a32')
					arch='arm-efi'
					shift
					;;
					
				'a64')
					arch='arm64-efi'
					shift
					;;
					
				--)
					shift 2
					break
					;;
			esac
			;;
			
		'-r' | '--removable')
			extras='--removable'
			shift
			;;
			
		'-h' | '--help')
			help_msg
			;;
			
		--)
			shift
			break
			;;
			
	esac
done

if [[ -z $partition ]]; then
	echo -e "\nError: No partition was specified. Aborting"
	exit
	
	elif [[ -z $arch ]]; then
		case "$(uname -m)" in
			
			'i386' | 'i586' | 'i686')
				arch='i386-efi'
				;;
				
			'x86_64' | 'amd64')
				arch='x86_64-efi'
				;;
				
			'arm' | 'armhf' | 'armv5'* | 'armv6'* | 'armv7'*)
				arch='arm-efi'
				;;
				
			'armv8'* |'arm64' | 'aarch64')
				arch='arm64-efi'
				;;
				
			--)
				break
				;;
		esac
		echo -e "\nWarning: No architecture was specified. Autodetcted as ${arch}."
fi

if [[ -z $installdir ]]; then
	installdir="/boot/efi"
	echo -e "\nWarning: No install directory was specified. Defaulting to ${installdir}"
fi

echo ""

mkdir -p $installdir
mount $partition $installdir
grub-install --target=$arch --efi-directory=$installdir --bootloader-id=GRUB $extras
umount $partition
