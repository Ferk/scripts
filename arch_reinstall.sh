#!/bin/bash
#
# Dirty script I use for doing some rutine setup tasks when
# installing and configuring a new archlinux install.
#
# Note: I still didn't use it much, probably needs some love
#
# Fernando Carmona Varo <ferkiwi@gmail.com>
#

GIT_CONFIG_REPO=git@github.com:Ferk/xdg_config.git


if   hash pac 2>$-;    then PACMAN=pac
elif hash packer 2>$-; then PACMAN=packer
elif hash yaourt 2>$-; then PACMAN=yaourt
elif hash pacman 2>$-; then PACMAN=pacman
fi

######
# Function definitions
msg() {
	echo -e "\e[33m ** \e[36m$@\e[0m"
}

confirm() {
	echo "$@"
	read edit -p "Do you want to edit that? [yN]"
	[ "$edit" = "N" ] && return
}

i() {
    $PACMAN --noconfirm -S $@
}

#######################
msg "Setting up groups for user \"$USER\""

# Group          Affected files      Purpose
G="$G adm"      # /var/log/*     Read access to log files in /var/log
G="$G audio"    # /dev/sound/*, /dev/snd/*, /dev/misc/rtc0   Access to sound hardware.
#G="$G avahi"    # ??
#G="$G bin"      # /usr/bin/*     Right to modify binaries only by root, but right to read or executed by anyone. (Please modify this for better understanding...)
#G="$G daemon"   # ??
G="$G dbus"     # /var/run/dbus
#G="$G disk"     # /dev/sda[1-9], /dev/sdb[1-9], /dev/hda[1-9], etc   Access to block devices not affected by other groups such as optical,floppy,storage.
G="$G floppy"   # /dev/fd[0-9]   Access to floppy drives.
G="$G ftp"      # /srv/ftp
G="$G games"    # /var/games     Access to some game software.
#G="$G gdm"      # ??
G="$G hal"      # /var/run/hald, /var/cache/hald
G="$G http"     # ??
G="$G kmem"     # /dev/port, /dev/mem, /dev/kmem
G="$G locate"   # /usr/bin/locate, /var/lib/locate, /var/lib/slocate, /var/lib/mlocate   Right to use updatedb command.
G="$G log"      # /var/log/*     Access to log files in /var/log,
G="$G lp"       # /etc/cups, /var/log/cups, /var/cache/cups, /var/spool/cups     Access to printer hardware
#G="$G mem"      # ??
G="$G mail"     # /usr/bin/mail
G="$G network"  #    Right to change network settings such as when using a Networkmanager.
#G="$G nobody"   #    Unprivileged group.
G="$G optical"  # /dev/sr[0-9], /dev/sg[0-9]     Access to optical devices such as CD,CD-R,DVD,DVD-R.
G="$G power"    #    Right to use suspend utils.
#G="$G rfkill"   # ??
#G="$G root"     # /* -- ALL FILES!   Complete system administration and control (root, admin)
G="$G scanner"  # /var/lock/sane     Access to scanner hardware.
G="$G smmsp"    #    sendmail group
G="$G storage"  #    Access to removable drives such as USB harddrives,flash/jump drives,mp3 players.
#G="$G stb-admin" # ??
#G="$G sys"      #    Right to admin printers in CUPS.
#G="$G thinkpad" # /dev/misc/nvram    Right for thinkpad users using tools such as tpb.
#G="$G tty"      # /dev/tty, /dev/vcc, /dev/vc, /dev/ptmx
G="$G users"    #    Standard users group.
G="$G uucp"     # /dev/ttyS[0-9] /dev/tts/[0-9]      Serial & USB devices such as modems,handhelds,RS232/serial ports.
G="$G video"    # /dev/fb/0, /dev/misc/agpgart   Access to video capture devices, DRI/3D hardware acceleration.
G="$G wheel"    #    Right to use sudo (setup with visudo), Also affected by PAM

# non-default Groups
G="$G ntp"      #
G="$G policykit"#
G="$G camera"   #    Access to Digital Cameras.
G="$G clamav"   # /var/lib/clamav/*, /var/log/clamav/*
G="$G networkmanager"   #    Requirement for your user to connect wirelessly with Networkmanager.
G="$G vboxusers"# /dev/vboxdrv   Right to use Virtualbox software.
G="$G vmware"   #    Right to use VMware software.

for i in $G
do
    sudo gpasswd -a $USER $i
done

msg "Groups for \"$USER\":"
groups $USER


###################
msg "Syncing configuration files to $GIT_CONFIG_REPO"

$XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config/}"

mkdir $XDG_CONFIG_HOME
cd $XDG_CONFIG_HOME

if [ -d .git/ ]; then
    git pull
else
    git clone $GIT_CONFIG_REPO .
fi

crontab ./crontab
./symlinks.sh

#############
msg "Singing trusted master keys"

for key in 0xFFF979E7 0xCDFD6BB0 0x4C7EA887 0x6AC6A4C2 0x824B18E8; do
    pacman-key --recv-keys $key
    pacman-key --lsign-key $key
    printf 'trust\n3\nquit\n' | gpg --homedir /etc/pacman.d/gnupg/ \
        --no-permission-warning --command-fd 0 --edit-key $key
done

#############
msg "Installing basic packages"

i dict goldendict espeak google-translate
i aspell aspell-es aspell-en aspell-de 
i hunspell-es hunspell-en hunspell-de # for loffice/chromium

i proggyfonts terminus-font bdf-unifont ttf-google-webfonts ttf-freefont ttf-liberation ttf-ms-fonts lohit-fonts ttf-ipa-mona ttf-monapo

i imagemagick sxiv gimp asciiview
i audio-convert mplayer2 vorbis-tools flac lame
i totem pyxdg

i emacs gdb

i tct # http://www.linux-mag.com/id/1889/
i awk ed lsof unp ncdu lesspipe dtach
i stderred rmshit screenfo
i bsd-games
i nmap gnu-netcat aircrack-ng

i xmms2 cmus

i chromium googletalk-plugin

i mimeo xdg-utils-mimeo

i openssh x11-ssh-askpass gpg git bzr subversion

i xorg-xmessage xosd beep xsel

# ebooks
i calibre 

i gettext

i slock swarp dmenu dwm-sprinkles

i inotify-tools

# Latex
i texlive-most


# Downloading
i transmission tucan-hg

# IM
o pidgin finch irssi



[ -f /usr/bin/beep ] && sudo chmod 4755 /usr/bin/beep

###################
msg "Finished."

