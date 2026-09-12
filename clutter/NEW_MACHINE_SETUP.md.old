# Setting Up a New Machine

Steps to bring a brand new machine (physical box or cloud instance) onto Tailscale and under this repo's Ansible management.

## 1. Get initial access

- **Physical/local machine:** install the OS, create your user, confirm you can log in locally or over SSH on the LAN.
- **Cloud instance:** SSH in using whatever the provider gives you initially (root password, provider-injected SSH key, etc.). Treat this as a temporary bootstrap credential — it gets locked down in [step 4](#4-cloud-instances-lock-down-public-access).

## 2. Install and configure Tailscale

Run these on the **new machine** itself (over its initial SSH access).

Install Tailscale:
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

Bring the machine up on the tailnet with Tailscale SSH enabled:
```bash
sudo tailscale up --ssh
```
This opens the auth URL — follow it to approve the device on your tailnet. (If the machine is already `up` and you just need to turn on Tailscale SSH afterwards, use `sudo tailscale set --ssh` instead.)

Confirm it registered and note the machine's Tailscale/MagicDNS name:
```bash
tailscale status
```

## 3. Add it to your SSH config

On your **control machine** (the one running Ansible), add an entry to `~/.ssh/config` following the pattern already used for the other tailnet hosts:
```
Host <short-name>
   HostName <tailscale-machine-name>
   User root
```
e.g.
```
Host new-host
   HostName new-host
   User root
```

Verify you can reach it over Tailscale SSH (no port-forwarding or public IP needed):
```bash
ssh <short-name>
```

## 4. Cloud instances: lock down public access

For a cloud instance, once Tailscale SSH is confirmed working, cut off the public internet path entirely — from then on the machine should only be reachable over the tailnet.

Tailscale itself doesn't need any inbound ports open publicly (it dials out to the coordination server and relays over DERP if a direct path isn't available), so it's safe to close everything on the public interface.

Drop all public inbound at the cloud provider's firewall/security group, in front of the VM's NIC. Hetzner Cloud firewalls default-deny anything not explicitly allowed, so creating one with zero inbound rules and applying it is enough (`hcloud` CLI):
```bash
hcloud firewall create --name tailnet-only
hcloud firewall apply-to-resource tailnet-only --type server --server new-host
```
No `add-rule` call is needed — an empty firewall already blocks all inbound while leaving outbound untouched. Equivalent steps apply in AWS (empty inbound security group), DigitalOcean, etc. — the goal is simply: no inbound rules on the public interface, Tailscale doesn't need any.

After this, the only way onto the box is `ssh <short-name>` over Tailscale.

## 5. Add the host to the Ansible inventory

Edit `inventory/hosts.ini` and add a line under `[debian]` (or `[nixos]` if applicable):
```ini
[debian]
new-host ansible_host=new-host ansible_user=root
```
`ansible_host` should match the `Host`/`HostName` you set up in `~/.ssh/config`.

## 6. Run the bootstrap playbooks against it

```bash
ansible-playbook playbooks/local-bootstrap.yml --limit new-host
ansible-playbook playbooks/debian-packages.yml --limit new-host
ansible-playbook playbooks/debian-ssh.yml --limit new-host
```
Add `--ask-become-pass` to any of these if `ansible_user` isn't root.

`debian-packages.yml` installs the base package set (git, Docker, AWS CLI, Node/npm, Claude Code CLI) and makes sure `tailscaled` is enabled/started; `debian-ssh.yml` enables systemd linger so the user's `ssh-agent` survives between sessions.

GUI apps are opt-in and only relevant for desktop machines:
```bash
ansible-playbook playbooks/debian-gui-packages.yml --limit new-host
```

## 7. Verify

```bash
ssh new-host
type ll        # dotfiles applied
docker ps      # docker installed and usable
tailscale status   # machine shows up, ssh enabled
```
