#!/bin/sh

#---
# Activates some options for reducing the power consumption.
#---



#sudo cpufreq-selector -g powersave -c 0
#sudo cpufreq-selector -g powersave -c 1
sudo cpufreq-set  -g powersave -c 0
sudo cpufreq-set  -g powersave -c 1


# increase the VM dirty writeback time from 0.29 to 15 seconds
sudo echo 1500 > /proc/sys/vm/dirty_writeback_centisecs
# This wakes the disk up less frequenty for background VM activity

# Enable SATA ALPM link power management via:
sudo echo min_power > /sys/class/scsi_host/host0/link_power_management_policy


# Disable 'hal' from polling your cdrom
sudo hal-disable-polling --device /dev/cdrom
# 'hal' is the component that auto-opens a window if you plug in a CD but disables SATA power saving from kicking in.


# enable HD audio powersave mode
sudo echo 1 > /sys/module/snd_hda_intel/parameters/power_save
# or by passing power_save=1 as module parameter.


#Suggestion: Enable wireless power saving mode by executing the following command
sudo iwconfig wlan0 power timeout 500ms


    # * Cambiar la opción de montaje del disco relatime por noatime:
    #       o Editar el fichero /etc/fstab ...

    #         Código: Seleccionar todo
    #             $ sudo gedit /etc/fstab

    #       o ... y cambiar el valor relatime por noatime en la línea de montaje de la partición raíz:

    #         Código: Seleccionar todo
    #             UUID=f0ae2c59-83d2-42e7-81c4-2e870b6b255d / ext2 noatime,errors=remount-ro 0 1

    #       o Para activar el cambio sin reiniciar:

    #         Código: Seleccionar todo
    #             $ sudo mount -o remount /dev/sda2

    # * Utilizar el planificador de E/S "noop":
    #       o Editar el fichero /boot/grub/menu.lst ...

    #         Código: Seleccionar todo
    #             sudo gedit /boot/grub/menu.lst

    #       o ... y añadir la opción elevator=noop en la línea de arranque del kernel:

    #         Código: Seleccionar todo
    #             ...
    #             title Ubuntu 8.04.1, kernel 2.6.24-19-generic
    #             root (hd0,1)
    #             kernel /boot/vmlinuz-2.6.24-19-generic root=UUID=f0ae2c59-83d2-42e7-81c4-2e870b6b255d ro quiet splash elevator=noop
    #             initrd /boot/initrd.img-2.6.24-19-generic
    #             quiet
    #             ...

    #       o Además, para que el cambio se mantenga tras una futura actualización del kernel, buscar la línea:

    #         Código: Seleccionar todo
    #             # defoptions=quiet splash

    #       o Y cambiarla por:

    #         Código: Seleccionar todo
    #             # defoptions=quiet splash elevator=noop

    #       o Para activar estos cambios necesitaremos reiniciar el sistema.
    # * Reducir las escrituras en el disco SSD
    #   Las frecuentes escrituras en los discos SSD acortan la vida del dispositivo y pueden provocar fallos ocasionales. Para evitar esto, podemos mover todos los directorios temporales a memoria RAM:
    #       o Editamos /etc/fstab ...

    #         Código: Seleccionar todo
    #             $ sudo gedit /etc/fstab

    #       o ... y añadimos las siguientes líneas al final del fichero:

    #         Código: Seleccionar todo
    #             tmpfs /tmp tmpfs defaults 0 0
    #             tmpfs /var/tmp tmpfs defaults 0 0
    #             tmpfs /var/log/apt tmpfs defaults 0 0
    #             tmpfs /var/log tmpfs defaults 0 0


    #         De esta forma, se destruirán todos estos datos con cada reinicio, lo que podría no ser deseable en caso de necesitar depurar algún error.
    #         Si necesitamos acceder a los logs entre reinicios del sistema, podemos comentar la última línea con una almohadilla (#):

    #         Código: Seleccionar todo
    #             #tmpfs /var/log tmpfs defaults 0 0


    #         Además, si vamos a instalar aplicaciones usando apt-get, debemos comentar también la penúltima línea:

    #         Código: Seleccionar todo
    #             #tmpfs /var/log/apt tmpfs defaults 0 0

    #       o Para activar estos cambios debemos reiniciar el sistema.


#####################3
# Ahorro de energía

#     * Editar el fichero /etc/rc.local ...
#     * ... y añadir las siguientes líneas antes de la última (exit 0):


#           # Reducir los accesos al SSD
#           sysctl -w vm.swappiness=1 # Reduce enormemente el "swapping"
#           sysctl -w vm.vfs_cache_pressure=50 # No reduce el cache de inodos de forma agresiva

#           # Como aparece en el fichero rc.last.ctrl de Linupus
#           echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
#           echo ondemand > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
#           cat /sys/devices/system/cpu/cpu0/cpufreq/ondemand/sampling_rate_max > /sys/devices/system/cpu/cpu0/cpufreq/ondemand/sampling_rate

#           echo 3000 > /proc/sys/vm/dirty_writeback_centisecs
#           echo 20 > /proc/sys/vm/dirty_ratio
#           echo 10 > /proc/sys/vm/dirty_background_ratio

#           echo 1 > /sys/devices/system/cpu/sched_smt_power_savings
#           echo 10 > /sys/module/snd_hda_intel/parameters/power_save
#           echo 5 > /proc/sys/vm/laptop_mode

#           # Reduce el consumo de energía del USB mientras no tiene actividad
#           [ -L /sys/bus/usb/devices/1-5/power/level ] && echo auto > /sys/bus/usb/devices/1-5/power/level
#           [ -L /sys/bus/usb/devices/5-5/power/level ] && echo auto > /sys/bus/usb/devices/5-5/power/level

