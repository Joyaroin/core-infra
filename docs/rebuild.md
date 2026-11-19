# Rebuilding the homelab

The order to bring everything back, and the steps that are still manual.
Each step assumes the ones above it are done.

**Two repos.** This one owns the two Proxmox hosts, joseph and jotaro, their guests and everything inside them
up to Kubernetes. The cluster's contents (Argo CD, Vault, the apps) live in
the gitops repo, `Joyaroin/morioh-cho-gitops` on GitHub.

**Where the secrets are:**

| Secret | Where |
|---|---|
| Proxmox API tokens (one per host) | `terraform/terraform.tfvars`, on the Mac only |
| Vault unseal key and root token | Bitwarden |
| Pi-hole web password | Yours to keep. A rebuild can also just use a new one |
| Forgejo registry token (for hermit) | Bitwarden. hermit needs it to pull lab images before Vault exists, so it can't live in Vault |
| Tailscale auth keys | Make a new one-off key each time: admin console → Settings → Keys |
| Tailscale OAuth client (for Terraform) | Bitwarden, and `terraform/terraform.tfvars` |
| Gmail app password (the hosts' notifications) | Bitwarden. Pass it to `proxmox-host.yml` once, without spaces: `-e gmail_app_password=...` |
| R2 key for the Terraform state | Bitwarden (`mediasafe/r2-terraform-state`), and `terraform/backend.credentials.hcl` |

## 1. Proxmox hosts (manual)

joseph runs everything except the CI runner; jotaro runs echoes. They are
separate hosts, not a Proxmox cluster. Do these steps on each one.

1. Install Proxmox VE. Keep the default disk layout: `local` and `local-lvm`.
2. Install Tailscale and run `tailscale up` (no extra flags).
3. Add the Mac's SSH key to `/root/.ssh/authorized_keys`.
4. Set up the host's storage, plus the Terraform role and user:

   ```sh
   cd ansible
   ansible-playbook playbooks/proxmox-host.yml -e gmail_app_password=...
   ```

5. Create the API token by hand. The playbook doesn't create it, so the
   secret never passes through Ansible:

   ```sh
   pveum user token add terraform@pve provider --privsep 0
   ```

   `--privsep 0` makes the token use the user's role. Put
   `terraform@pve!provider=<secret>` in `terraform/terraform.tfvars` (see
   `terraform.tfvars.example`): joseph's as `proxmox_api_token`, jotaro's
   as `proxmox_jotaro_api_token`.

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

The state is in R2, not on the Mac, so a new machine picks up where the old
one left off. Put the R2 key in `terraform/backend.credentials.hcl`:

```hcl
access_key = "<username of mediasafe/r2-terraform-state>"
secret_key = "<password of mediasafe/r2-terraform-state>"
```

```sh
cd terraform
terraform init -backend-config=backend.credentials.hcl
terraform apply
```

R2 keeps no old versions of the state. After an apply that matters, keep a
copy: `terraform state pull > ~/core-infra-tfstate-$(date +%F).json`.

This downloads the Ubuntu images and creates heavens-door and hermit on
joseph, and echoes on jotaro. It also sets up the backup jobs. heavens-door
(the retired Pi-hole) is created stopped; skip its playbook unless you
bring it back.

## 4. Inside the guests

From `ansible/`:

```sh
ansible-playbook playbooks/runner.yml -e tailscale_authkey=tskey-...   # tag:ci key
ansible-playbook playbooks/hermit.yml -e tailscale_authkey=tskey-... -e registry_password=...
```

The first run on a new host stops at SSH host key verification. Accept the
key once:
`ssh -o StrictHostKeyChecking=accept-new -J root@<host>.tailf69bc5.ts.net <user>@<ip>`,
where `<host>` is the guest's Proxmox host (jotaro for echoes, joseph for the rest).

After the first run, the extra `-e` values aren't needed. Re-running any
playbook should report `changed=0`.

`runner.yml` also firewalls echoes off from the home network, in both
directions, for the VM and for the job containers Docker runs on it. It can
still reach the internet, DNS on the router, and the tailnet. Two exceptions
on the home network: SSH in from jotaro (how Ansible gets there), and one UDP
port out to forgejo, which is Tailscale's direct path to git. If a rule locks
Ansible out, switch the firewall off from jotaro with
`qm guest exec 205 -- ufw disable`.

## 5. Tailscale admin console (manual)

- **DNS:** Terraform sets it (`terraform/tailscale.tf`): MagicDNS on, no
  custom nameservers. The access rules are in `terraform/tailscale-policy.hujson`.
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

Home DNS uses the router's own resolver. Nothing on the LAN depends on
heavens-door, so nothing should need changing.

## After any power cut

Vault comes back sealed. Run `bootstrap/vault-unseal` from the gitops repo.
Apps keep serving on their last secrets until then, but nothing refreshes,
and the nightly Vault snapshot to R2 fails.
