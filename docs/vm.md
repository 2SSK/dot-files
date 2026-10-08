# Virtual machines

VMs run on libvirt's system connection (`qemu:///system`): each gets an address on the
`default` NAT network, folders can be shared with virtiofs, and every VM shows up in
**virt-manager**. `setup.sh` installs the tools (the `vm` layer) and enables the service.

## vm

`vm` is a thin wrapper around `virt-install` and `virsh`. VMs are defined in
`~/.config/vm/vms.json`; `vm up <name>` creates one from there (or starts it).

```sh
vm list                 # every VM: state and IP
vm up rice              # create from the config, or start
vm ssh rice [command]   # log in as the VM's user
vm console rice         # virt-manager window (GUI) or serial console (server)
vm down rice            # shut down
vm rm rice              # delete the VM and its disk
vm images               # image names and versions
vm config               # edit vms.json
vm snapshot-list rice   # anything else is passed to virsh on the system connection
```

### vms.json

```json
{
  "defaults": { "image": "ubuntu:26.04", "cpus": 2, "memory": "2G", "disk": "20G", "gui": false,
                "user": null, "password": null, "ssh_keys": ["~/.ssh/*.pub"] },
  "vms": {
    "rice":   { "image": "arch", "gui": true, "memory": "4G", "disk": "30G",
                "shares": [{ "source": "~/Dotfiles", "tag": "dotfiles", "readonly": true }] },
    "server": { "image": "debian:13" },
    "web":    { "image": "ubuntu:24.04", "cpus": 4, "memory": "4G", "user": "dev", "password": "dev" },
    "try":    { "iso": "~/Downloads/installer.iso", "disk": "30G" }
  }
}
```

Each VM's keys override `defaults`.

| Key | Meaning |
| --- | --- |
| `image` | `ubuntu[:version]` (26.04), `debian[:version]` (13), `fedora[:version]` (44), `arch`, or any cloud-image URL or file |
| `iso` | An installer ISO instead of `image`; you install it by hand in the console |
| `cpus`, `memory`, `disk` | Size (`2G`, `512M`, …) |
| `gui` | `true`: Spice display with auto-resize, sound and the agents; `false`: SSH and serial console only |
| `user` | Login name in the VM (default: yours), with passwordless sudo |
| `password` | Optional; hashed before it reaches the VM, and enables password login. Keys are safer |
| `ssh_keys` | Public keys (globs allowed) installed for `user` |
| `shares` | Laptop folders mounted at `~/<tag>` in the VM over virtiofs; `readonly` optional |

Cloud images are downloaded once to `~/.cache/vm/images`; each VM's disk is a thin copy on
top. A VM is only created or started when the laptop keeps at least 2 GiB free (`--force`
overrides).

## virt-manager

- **Full window**: View → Scale Display → *Auto resize VM with window* (needs the Spice
  agent, which `"gui": true` installs); View → Fullscreen for the whole screen.
- **Mouse and keyboard**: the pointer moves in and out freely. Click into the VM to type;
  every key, Super included, then goes to the VM. **Ctrl_L + Alt_L** (or clicking outside)
  gives the keyboard back to the laptop. Change it under Edit → Preferences → Console.
- **Sharing a folder by hand**: shut the VM down → details (💡) → Memory: *Enable shared
  memory* → Add Hardware → Filesystem: driver **virtiofs**, source = laptop folder, target =
  a tag → start it, then in the VM:

  ```sh
  sudo mount -t virtiofs <tag> ~/<tag>
  # at every boot, in /etc/fstab:  <tag>  /home/<you>/<tag>  virtiofs  defaults,nofail  0 0
  ```

## Testing the dotfiles (rice-vm)

`rice-vm` is the main test VM: Arch with i3 and SwayFX, in libvirt's **user session**
(`qemu:///session`), which virt-manager connects to automatically under *QEMU/KVM User
session*. Start, stop and open it there.

- The laptop's `~/Dotfiles` is shared read-only and mounted at `~/Dotfiles` in the VM, so
  edits appear there immediately.
- Apply them inside the VM: `~/Dotfiles/setup.sh -y --no-packages` (re-links and re-renders
  the theme), then reload i3 / sway or restart the app.
- Its disks are `~/.local/share/dotfiles-vm/work.qcow2` on top of `provisioned.qcow2`. Take a
  snapshot before risky changes: virt-manager → *Manage VM snapshots*, or
  `virsh -c qemu:///session snapshot-create-as rice-vm clean`.

New VMs from `vms.json` go to the system connection; `LIBVIRT_DEFAULT_URI=qemu:///session vm …`
targets the user session instead.
