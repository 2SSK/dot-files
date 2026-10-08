# Virtual machines

VMs run on libvirt's system connection (`qemu:///system`), so every one shows up in
**virt-manager**. They boot from official cloud images and set themselves up on first boot
(cloud-init): your user with a password, the packages, the shared folders.

## Once per laptop

```sh
sudo systemctl enable --now virtqemud.socket virtstoraged.socket virtnodedevd.socket virtnetworkd.socket
sudo virsh net-start default && sudo virsh net-autostart default
```

## vm

```sh
vm create rice --desktop --share ~/dev/dot-files-rewrite:dot-files   # the Quickshell test VM
vm create srv --image debian:13 --mem 2G                             # a server, serial console
vm list                     # every VM and its state
vm start rice               # start it and open its window
vm console srv              # window (display VMs) or serial console (Ctrl+] leaves)
vm stop rice                # shut down; --force pulls the plug
vm snap rice clean          # snapshot (shut it down first)
vm revert rice clean        # back to that snapshot
vm rm rice                  # delete the VM and its disk
vm snapshot-list rice       # anything else goes to virsh on the system connection
```

`create` asks for the password of your user in the VM (with passwordless sudo); only its hash
reaches the VM. First boot upgrades and installs packages, so give it a few minutes.

| Option | Default | Meaning |
| --- | --- | --- |
| `--image` | `arch` | `arch`, `debian[:13]`, `ubuntu[:26.04]`, `fedora[:44]`, or any cloud-image URL or file |
| `--cpus`, `--mem`, `--disk` | 2, 4G, 30G | Size |
| `--share <dir>[:tag[:rw]]` | | Laptop folder mounted at `~/<tag>` over virtiofs (tag defaults to the folder's name); read-only unless `:rw`. Repeatable |
| `--gui` | off | Spice display with 3D acceleration on the Intel GPU (virgl); without it, a serial console |
| `--desktop` | off | `--gui` plus i3, sway, sddm, kitty, foot (and quickshell on Arch); pick the session at the login screen |
| `--pkgs "a b"` | | More packages, in the distro's names |
| `--force` | | Start even if the laptop would keep under 2 GiB free |

Each distro's image is downloaded once into the `default` pool (`/var/lib/libvirt/images`,
`vm-base-*`); a VM's disk is a thin copy on top, so `create` is quick after the first time.
To pick up a newer image, delete its base volume once no VM uses it:
`vm vol-delete --pool default vm-base-<file>`.

Snapshots need the VM shut down: libvirt can't snapshot a running VM with shared folders.

## Testing the dotfiles

`vm create rice --desktop --share ~/dev/dot-files-rewrite:dot-files` gives an Arch VM with GRUB,
i3 and sway, and the worktree mounted read-only at `~/dot-files`, the same path as on the laptop.
Edit on the laptop; the VM sees each change at once. In the VM, `cd ~/dot-files && stow .` links
the configs. Take `vm snap rice clean` after the first boot, and revert to it whenever an
experiment goes wrong.

## virt-manager

- **Full window**: View → Scale Display → *Auto resize VM with window*.
- **Keyboard**: click into the VM to type; every key, Super included, then goes to the VM.
  **Ctrl_L + Alt_L** gives it back to the laptop.
- **Black screen with `--gui`**: the VM's 3D path failed. In its details, turn off OpenGL under
  *Display Spice* and 3D acceleration under *Video*; it falls back to software rendering.
