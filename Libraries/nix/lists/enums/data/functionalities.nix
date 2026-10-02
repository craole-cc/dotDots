# Libraries/nix/lists/enums/data/functionalities.nix
#
# The canonical host functionality vocabulary.
#
# This file is a pure data leaf: it takes no arguments and imports nothing.
# That is deliberate. `Libraries/nix/lists/enums/hardware.nix` is a `{_, ...}`
# module and cannot be evaluated without bootstrapping the entire `_` module
# system, so nothing outside that tree can read its enums. The `Preci` host
# schema must validate against the same vocabulary, so the names live here,
# where both trees can import them directly.
#
# `hardware.nix` wraps this list in `mkEnum` to add the validator, the alias
# resolution and the case-insensitive lookup. Consumers that only need the raw
# names should import this file and skip the enum machinery.
#
# `Libraries/nix/lists/enums/user.nix` follows the same pattern for
# capabilities.
[
  #~@ Input devices
  "keyboard"
  "touchpad"
  "touchscreen"

  #~@ Storage
  "storage"
  "nvme"
  "ssd"
  "hdd"

  #~@ Network
  "network"
  "wired"
  "wireless"
  "vpn"
  "bluetooth"

  #~@ Display
  "video"
  "gpu"
  "amdgpu"
  "nvidiagpu"
  "intelgpu"

  #~@ Audio
  "audio"
  "speakers"
  "microphone"

  #~@ Security
  "tpm"
  "fingerprint"
  "smartcard"
  "secureboot"

  #~@ Power
  "battery"
  "power-management"

  #~@ Virtualization
  "virtualization"
  "kvm"

  #~@ Boot
  "efi"
  "bios"
  "dualboot-windows"
  "dualboot-macos"

  #~@ Peripherals
  "webcam"
  "printer"
  "scanner"

  #~@ Control plane
  #? A host that provisions and reaches other machines, rather than only being
  #? used. TheOracle is the reference implementation; the desktop commander
  #? remote service is gated on this name.
  "control-plane"
]
