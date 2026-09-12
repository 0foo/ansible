## Building a Golden Image

How to (re)build the `golden-host` Proxmox container/VM and cut new hosts from it.

### 1. Converge `golden-host`

From this repo, run the standard bootstrap/package playbooks against `golden-host`:
```bash
ansible-playbook playbooks/local-bootstrap.yml --limit golden-host
ansible-playbook playbooks/debian-packages.yml --limit golden-host --ask-become-pass
```
This leaves `golden-host` with dotfiles, CLI tooling, and whatever else the golden image should ship with. Do any other one-off customization to `golden-host` now, before sanitizing/snapshotting.

### 2. Snapshot from the Proxmox host

SSH into `proxmox` and run the promotion script:
```bash
ssh proxmox
~/promote-golden.sh
```
This is a bash script living on `proxmox` itself (not part of this repo) that sanitizes `golden-host` (strips machine-id, SSH host keys, Tailscale state, DHCP leases, logs) and takes a Proxmox snapshot, printing the snapshot ID/name to use in the next step.

### 3. Clone a new host

In the Proxmox web console, clone `golden-host` using the snapshot ID from step 2. Give the clone its own hostname/ID — a clone that keeps `golden-host`'s hostname will collide with it on the local DNS.

### 4. Reach the new host

Networking is already configured on the clone, so from `borg-host` you can jump straight to it by name:
```bash
ssh borg-host
ssh <hostname>.lan
```
The `.lan` suffix matters — it's what resolves through the local Proxmox DNS server. Without it, the name won't resolve.
