;; This is an operating system configuration generated
;; by the graphical installer.
;;
;; Once installation is complete, you can learn and modify
;; this file to tweak the system configuration, and pass it
;; to the 'guix system reconfigure' command to effect your
;; changes.


;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu) (nongnu packages linux))
(use-service-modules cups desktop networking ssh xorg nix)

(operating-system
  (kernel linux)
  (firmware (list linux-firmware))
  (locale "en_AG.utf8")
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
          "video"))   ;; control video devices
      )
      %base-user-accounts
    )
  )


  ;; Add the 'realtime' group
  (groups 
    (cons 
      (user-group 
        (system? #t) 
        (name "realtime")
      )
      %base-groups
    )
  )

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
      %base-packages
    )
  )

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
    (append 
      (list 
        (service xfce-desktop-service-type)
        (set-xorg-configuration
          (xorg-configuration (keyboard-layout keyboard-layout))
        )
      )

      ;; This is the default list of services we
      ;; are appending to.
      %desktop-services
    )
  )
  (bootloader 
    (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (targets (list "/boot/efi"))
      (keyboard-layout keyboard-layout)
    )
  )
  (swap-devices 
    (list (swap-space
        (target (uuid "e68a025f-bdbb-42a5-b6e6-5d0c04a9fedb"))
    ))
  )
  (mapped-devices 
    (list (mapped-device
      (source (uuid "62c8186f-0692-41cd-9006-461c7dc2434f"))
      (target "guix")
      (type luks-device-mapping)
    ))
  )

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems 
    (cons* 
      (file-system
        (mount-point "/")
        (device "/dev/mapper/guix")
        (type "btrfs")
        (dependencies mapped-devices)
      )
      (file-system
        (mount-point "/store")
        (device (uuid "b0723ef0-4df8-4c5e-8b1c-171cb24f66dc" 'ext4))
        (type "ext4")
      )
      (file-system
        (mount-point "/boot/efi")
        (device (uuid "51BD-00C1" 'fat32))
        (type "vfat")
      ) 
        %base-file-systems
    )
  )
)
