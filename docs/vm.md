# Virtual machines

VMs run on libvirt's system connection (`qemu:///system`), so every one shows up in
**virt-manager**. They boot from official cloud images and set themselves up on first boot
(cloud-init): your user with a password, the packages, the shared folders.

## Once per laptop

`setup.sh` does this when you pick the `vm` layer; on its own it's `packages/system.sh libvirt`
(sudo, safe to re-run). It enables libvirt's daemons, starts the `default` NAT network and sets it
to start at boot, adds you to the `libvirt` group, and, when firewalld runs, puts the network's
bridge `virbr0` into firewalld's `libvirt` zone. Without that zone a VM gets no address: it waits
at boot for a network that never comes (firewalld drops its DHCP request).

## vm

```sh
vm create rice --desktop --share ~/dot-files:dot-files   # the Quickshell test VM
vm create srv --image debian:13 --mem 2G                             # a server, serial console
vm list                     # every VM: state, and IP while running
vm start rice               # start it and open its window
vm open srv                 # window (display VMs) or serial console (Ctrl+] leaves)
vm console rice             # log in on its serial console, even with a window (Ctrl+] leaves)
vm stop rice                # shut down; --force pulls the plug
vm snap rice clean          # snapshot (shut it down first)
vm snaps rice               # its snapshots
vm revert rice clean        # back to that snapshot
vm rm rice                  # delete the VM and its disk
vm help create              # every option of a command; plain `vm` lists the commands
vm guide                    # this page
```

For anything else, use virsh on the same connection: `virsh -c qemu:///system <command>`.

`create` asks for the password of your user in the VM (with passwordless sudo); only its hash
reaches the VM. First boot upgrades and installs packages, so give it a few minutes.

| Option | Default | Meaning |
| --- | --- | --- |
| `--image` | `arch` | `arch`, `debian[:13]`, `ubuntu[:26.04]`, `fedora[:44]`, or any cloud-image URL or file |
| `--cpus`, `--mem`, `--disk` | 2, 4G, 30G | Size |
| `--share <dir>[:tag[:rw]]` | | Laptop folder mounted at `~/<tag>` over virtiofs (tag defaults to the folder's name); read-only unless `:rw`. Repeatable |
| `--gui` | off | Spice display with 3D acceleration on the Intel GPU (virgl), sized to the window; without it, a serial console |
| `--desktop` | off | `--gui` plus i3, sway, sddm, kitty, foot (and quickshell on Arch); the login screen preselects i3 |
| `--pkgs "a b"` | | More packages, in the distro's names |
| `--force` | | Start even if the laptop would keep under 2 GiB free |

Each distro's image is downloaded once into the `default` pool (`/var/lib/libvirt/images`,
`vm-base-*`); a VM's disk is a thin copy on top, so `create` is quick after the first time.
To pick up a newer image, delete its base volume once no VM uses it:
`virsh -c qemu:///system vol-delete --pool default vm-base-<file>`.

Snapshots need the VM shut down: libvirt can't snapshot a running VM with shared folders.

## Testing the dotfiles

`vm create rice --desktop --share ~/dot-files:dot-files` gives an Arch VM with GRUB,
i3 and sway, and the worktree mounted read-only at `~/dot-files`, the same path as on the laptop.
Edit on the laptop; the VM sees each change at once. In the VM, `cd ~/dot-files && stow .` links
the configs. Take `vm snap rice clean` after the first boot, and revert to it whenever an
experiment goes wrong.

## virt-manager

- **Full window**: View → Scale Display → *Auto resize VM with window*. The window size reaches the
  VM as a display change; sway follows it by itself, and in an X session (i3) a udev rule that
  `vm create --gui` installs runs `xrandr --auto` on every change, plus once at login, and redraws
  the wallpaper. Black bars beside the picture mean the VM was created without them.
- **Keyboard**: click into the VM to type; every key, Super included, then goes to the VM.
  **Ctrl_L + Alt_L** gives it back to the laptop.
- **Black screen with `--gui`**: the VM's 3D path failed. In its details, turn off OpenGL under
  *Display Spice* and 3D acceleration under *Video*; it falls back to software rendering.
