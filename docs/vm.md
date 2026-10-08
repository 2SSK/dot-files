# Virtual machines

VMs run on libvirt's system connection (`qemu:///system`): each gets an address on the
`default` NAT network, folders can be shared with virtiofs, and every VM shows up in
**virt-manager**. `setup.sh` installs the tools (the `vm` layer) and enables the service.

## desktop-vm

```sh
desktop-vm create web  --image debian --server --cpus 2 --mem 2G --disk 20G
desktop-vm create rice --image arch --gui --mem 4G --share ~/Dotfiles:dotfiles:ro
desktop-vm create try  --image https://example.org/some-cloud-image.qcow2
desktop-vm create inst --iso ~/Downloads/installer.iso --disk 30G

desktop-vm list                 # name, state, IP
desktop-vm ssh web [command]    # log in (or run a command) as you
desktop-vm console rice         # virt-manager window (GUI) or serial console (server)
desktop-vm start | stop | delete <name>
```

| Option | Meaning |
| --- | --- |
| `--image` | `ubuntu` (26.04), `debian` (13), `fedora` (44), `arch`, or any cloud-image URL or file |
| `--iso` | An installer ISO instead; you install it by hand in the console |
| `--server` / `--gui` | No display (SSH and serial console) / Spice display with auto-resize, sound and the guest agent |
| `--cpus`, `--mem`, `--disk` | Size; defaults 2, 2G, 20G |
| `--share dir[:tag][:ro]` | Mount a laptop folder at `~/<tag>` in the VM (virtiofs), read-only with `:ro` |
| `--force` | Start even when it would leave the laptop under 2 GiB of free memory |

Cloud images are prepared by cloud-init on first boot: a user named like yours with
passwordless sudo, your `~/.ssh/*.pub` keys, password login off, the guest agent (and the
Spice agent for `--gui`). Images are downloaded once to `~/.cache/desktop-vm/images` and
each VM's disk is a thin copy on top of them.

## virt-manager

- **Full window**: View → Scale Display → *Auto resize VM with window* (needs the Spice
  agent in the guest, which `--gui` installs); View → Fullscreen for the whole screen.
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

## Memory

A VM is only created or started when the laptop keeps at least 2 GiB free. The memory
safety net from `setup.sh` (zram swap and systemd-oomd) is the second line of defence.
