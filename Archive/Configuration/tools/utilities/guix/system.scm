;; This is an operating system configuration generated
;; by the graphical installer.
;;
;; Once installation is complete, you can learn and modify
;; this file to tweak the system configuration, and pass it
;; to the 'guix system reconfigure' command to effect your
;; changes.


(use-modules 
  ;; Indicate which modules to import to access the variables
  ;; used in this configuration.
  (gnu) 
  (srfi srfi-1)
  (gnu system nss)
  (gnu services pm)
  (gnu services cups)
  (gnu services desktop)
  (gnu services docker)
  (gnu services networking)
  (gnu services virtualization)
  (gnu packages wm)
  (gnu packages cups)
  (gnu packages vim)
  (gnu packages gtk)
  (gnu packages xorg)
  (gnu packages emacs)
  (gnu packages file-systems)
  (gnu packages gnome)
  (gnu packages mtools)
  (gnu packages linux)
  (gnu packages audio)
  (gnu packages certs)
  (gnu packages shells)
  (gnu packages gnuzilla)
  (gnu packages pulseaudio)
  (gnu packages web-browsers)
  (gnu packages version-control)
  (gnu packages package-management)
  (nongnu packages linux)
  (nongnu system linux-initrd)
  ) 

(use-service-modules 
  cups 
  desktop 
  networking 
  ssh 
  xorg
  nix
  )

(define %backlight-udev-rule
  ;; Allow members of the "video" group to change the screen brightness.
  (udev-rule
   "90-backlight.rules"
   (string-append 
    "ACTION==\"add\", SUBSYSTEM==\"backlight\", "
    "RUN+=\"/run/current-system/profile/bin/chgrp video /sys/class/backlight/%k/brightness\""
    "\n"
    "ACTION==\"add\", SUBSYSTEM==\"backlight\", "
    "RUN+=\"/run/current-system/profile/bin/chmod g+w /sys/class/backlight/%k/brightness\""
    )))


(define %extended-desktop-services
  (modify-services %desktop-services
    (elogind-service-type config => 
      (elogind-configuration 
        (inherit config)
        (handle-lid-switch-external-power 'suspend)))
    (udev-service-type config => (udev-configuration 
        (inherit config)
        (rules 
          (cons %backlight-udev-rule
            (udev-configuration-rules config)))))
    (network-manager-service-type config => (network-manager-configuration 
        (inherit config)
        (vpn-plugins (list network-manager-openvpn))))))


(define %xorg-libinput-config
"Section \"InputClass\"
  Identifier \"Touchpads\"
  Driver \"libinput\"
  MatchDevicePath \"/dev/input/event*\"
  MatchIsTouchpad \"on\"

  Option \"Tapping\" \"on\"
  Option \"TappingDrag\" \"on\"
  Option \"DisableWhileTyping\" \"on\"
  Option \"MiddleEmulation\" \"on\"
  Option \"ScrollMethod\" \"twofinger\"
EndSection
Section \"InputClass\"
  Identifier \"Keyboards\"
  Driver \"libinput\"
  MatchDevicePath \"/dev/input/event*\"
  MatchIsKeyboard \"on\"
EndSection
")

(operating-system
  (kernel linux)
  (firmware (list linux-firmware))
  (initrd microcode-initrd)
  (locale "en_US.utf8")
  (timezone "America/Jamaica")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "guix")
  (users 
    (cons* 
      (user-account
        (name "craole")
        (comment "Craig 'Craole' Cole")
        (group "users")
        (home-directory "/home/craole")
        (supplementary-groups '(
          "wheel"     ;; sudo
          "netdev"    ;; network devices
          "kvm"
          "tty"
          "input"
          "docker"
          "realtime"  ;; Enable realtime scheduling
          "lp"        ;; control bluetooth devices
          "audio"     ;; control audio devices
          "video"     ;; control video devices
          )))
        %base-user-accounts))

  (groups 
    ;; Add the 'realtime' group
    (cons 
      (user-group 
        (system? #t) 
        (name "realtime")
        )
        %base-groups))

  (packages 
    (append 
      (list 
        git
        ntfs-3g
        exfat-utils
        fuse-exfat
        stow
        neovim
        emacs
        xterm
        bluez
        bluez-alsa
        pulseaudio
        tlp
        xf86-input-libinput
        nss-certs     ;; for HTTPS access
        gvfs         ;; for user mounts

        ;; (specification->package "emacs")
        ;; (specification->package "emacs-exwm")
        ;; (specification->package "emacs-desktop-environment")
        ;; (specification->package "nss-certs")
        )
        %base-packages))

  (services 
    ;; Below is the list of system services.  To search for available
    ;; services, run 'guix system search KEYWORD' in a terminal.
    (cons* 
      (service slim-service-type
        (slim-configuration
          (xorg-configuration
            (xorg-configuration
              (keyboard-layout keyboard-layout)
              (extra-config (list %xorg-libinput-config))
              ))))
      (service tlp-service-type
        (tlp-configuration
          (cpu-boost-on-ac? #t)
          (wifi-pwr-on-bat? #t)
          ))
      (pam-limits-service ;; This enables JACK to enter realtime mode
        (list
          (pam-limits-entry "@realtime" 'both 'rtprio 99)
          (pam-limits-entry "@realtime" 'both 'memlock 'unlimited)
          ))
      (extra-special-file "/usr/bin/env"
        (file-append coreutils "/bin/env")
        )
      (service thermald-service-type)
      (service docker-service-type)
      (service libvirt-service-type
        (libvirt-configuration
          (unix-sock-group "libvirt")
          (tls-port "16555")
          ))
      (service cups-service-type
        (cups-configuration
          (web-interface? #t)
          (extensions
            (list cups-filters)
            )))
      (service nix-service-type)
      (bluetooth-service #:auto-enable? #t)
      (remove (lambda (service)
          (eq? (service-kind service) gdm-service-type))
      %extended-desktop-services)))
  (name-service-switch 
    ;; Allow resolution of '.local' host names with mDNS
    %mdns-host-lookup-nss)
  (bootloader 
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (targets (list "/boot/efi"))
      (keyboard-layout keyboard-layout)
    ))
  (swap-devices 
    (list (swap-space
        (target (uuid "e68a025f-bdbb-42a5-b6e6-5d0c04a9fedb"))
    )))
  (mapped-devices 
    (list (mapped-device
      (source (uuid "62c8186f-0692-41cd-9006-461c7dc2434f"))
      (target "guix")
      (type luks-device-mapping)
      )))

  (file-systems 
    ;; The list of file systems that get "mounted".  The unique
    ;; file system identifiers there ("UUIDs") can be obtained
    ;; by running 'blkid' in a terminal.
    (cons* 
      (file-system (mount-point "/")
        (device "/dev/mapper/guix")
        (type "btrfs")
        (dependencies mapped-devices))
      (file-system (mount-point "/store")
        (device (uuid "b0723ef0-4df8-4c5e-8b1c-171cb24f66dc" 'ext4))
        (type "ext4"))
      (file-system (mount-point "/boot/efi")
        (device (uuid "51BD-00C1" 'fat32))
        (type "vfat")) 
      %base-file-systems))
  )
