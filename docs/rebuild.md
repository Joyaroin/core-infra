# Rebuilding the homelab

The order to bring everything back, and the steps that are still manual.
Each step assumes the ones above it are done.

**Two repos.** This one owns joseph, its guests and everything inside them
up to Kubernetes. The cluster's contents (Argo CD, Vault, the apps) live in
the gitops repo, `Joyaroin/morioh-cho-gitops` on GitHub.

**Where the secrets are:**

| Secret | Where |
|---|---|
| Proxmox API token | `terraform/terraform.tfvars`, on the Mac only |
| Vault unseal key and root token | Bitwarden |
| Pi-hole web password | Yours to keep. A rebuild can also just use a new one |
| Forgejo registry password (for hermit) | In hermit's `/etc/rancher/k3s/registries.yaml` today. Keep a copy, or make a new Forgejo token |
| Tailscale auth keys | Make a new one-off key each time: admin console → Settings → Keys |

## 1. Proxmox host (manual)

1. Install Proxmox VE on joseph. Keep the default disk layout: `local` and `local-lvm`.
2. Install Tailscale and run `tailscale up` (no extra flags).
3. Add the Mac's SSH key to `/root/.ssh/authorized_keys`.
4. Set up the host's storage, plus the Terraform role and user:

   ```sh
   cd ansible
   ansible-playbook playbooks/proxmox-host.yml
   ```

5. Create the API token by hand. The playbook doesn't create it, so the
   secret never passes through Ansible:

   ```sh
   pveum user token add terraform@pve provider --privsep 0
   ```

   `--privsep 0` makes the token use the user's role. Put
   `terraform@pve!provider=<secret>` in `terraform/terraform.tfvars` (see
   `terraform.tfvars.example`).

## 2. Forgejo: restore, don't rebuild

Forgejo is the one guest whose value is its data, so it comes back from a backup.
Do this **before** `terraform apply`, or Terraform creates an empty container
in its place:

```sh
pct restore 203 /var/lib/vz/dump/vzdump-lxc-203-<newest>.tar.zst --storage local-lvm
pct start 203
```

Backups are on joseph's own disk for now, so this only works if that disk
survived. Until there's a NAS, losing the disk means losing Forgejo.

## 3. Terraform

```sh
cd terraform
terraform init
terraform apply
```

This downloads the Ubuntu images and creates heavens-door, echoes and
hermit. It also sets up the backup jobs.

## 4. Inside the guests

From `ansible/`:

```sh
ansible-playbook playbooks/pihole.yml -e tailscale_authkey=tskey-... -e pihole_password=...
ansible-playbook playbooks/runner.yml -e tailscale_authkey=tskey-...   # tag:ci key
ansible-playbook playbooks/hermit.yml -e tailscale_authkey=tskey-... -e registry_password=...
```

The first run on a new host stops at SSH host key verification. Accept the
key once:
`ssh -o StrictHostKeyChecking=accept-new -J root@joseph.tailf69bc5.ts.net <user>@<ip>`.

After the first run, the extra `-e` values aren't needed. Re-running any
playbook should report `changed=0`.

## 5. Tailscale admin console (manual)

- **DNS → Nameservers:** heavens-door's Tailscale IP.
- **hermit's machine page → Edit IP:** set it back to `100.80.32.26`. The k3s
  certificate and the kubeconfig name that IP.
- Remove the dead machines, and rename any new one that came back with a `-1`
  suffix.

## 6. The cluster

In the gitops repo, follow "Bootstrapping a cluster" in its README:
1. Fetch the kubeconfig.
2. Run `bootstrap/install` to install Argo CD.
3. Wait for Vault to come up.
4. Bring Vault back:
   - **hermit's disk survived:** run `bootstrap/vault-unseal`. The data is
     still in `/mnt/vault-data`.
   - **new disk:** restore the newest R2 snapshot by the procedure in
     `bootstrap/vault-restore-drill`, then unseal.

## 7. Router (manual)

Home DNS points at `192.168.2.13` (heavens-door). Terraform keeps that IP and
the old MAC address, so nothing should need changing.

## After any power cut

Vault comes back sealed. Run `bootstrap/vault-unseal` from the gitops repo.
Apps keep serving on their last secrets until then, but nothing refreshes,
and the nightly Vault snapshot to R2 fails.
