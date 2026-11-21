"""Mount phone volumes when they appear or become available after unlocking."""

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib


pending = set()


def mounted(volume, result):
    pending.discard(volume)
    try:
        volume.mount_finish(result)
    except GLib.Error as error:
        print(f"Could not mount {volume.get_name()}: {error.message}", flush=True)


def mount_phone(monitor, volume):
    root = volume.get_activation_root()
    if (
        root is None
        or root.get_uri_scheme() not in {"mtp", "afc"}
        or volume.get_mount() is not None
        or not volume.can_mount()
        or volume in pending
    ):
        return
    pending.add(volume)
    volume.mount(Gio.MountMountFlags.NONE, Gio.MountOperation(), None, mounted)


monitor = Gio.VolumeMonitor.get()
monitor.connect("volume-added", mount_phone)
monitor.connect("volume-changed", mount_phone)
for volume in monitor.get_volumes():
    mount_phone(monitor, volume)
GLib.MainLoop().run()
