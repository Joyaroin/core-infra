# Imported from the job originally created in the web UI, hence the random ID.
resource "proxmox_backup_job" "forgejo_daily" {
  id             = "be91511d-1aba-4d7d-bee3-a678d4dce45b"
  schedule       = "03:30" # every day at 03:30
  storage        = "local"
  vmid           = ["203"]    # forgejo
  mode           = "snapshot" # back up while running, with no downtime
  compress       = "zstd"
  enabled        = true
  notes_template = "{{guestname}}" # label each backup with the guest's name
  prune_backups = {
    "keep-last" = "7" # keep the newest 7 backups and delete older ones
  }
}

resource "proxmox_backup_job" "pihole_daily" {
  id             = "pihole-daily" # a name you choose; it becomes the job ID in Proxmox
  schedule       = "03:45"        # 15 minutes after forgejo's, so they don't overlap
  storage        = "local"
  vmid           = ["202"] # heavens-door
  mode           = "snapshot"
  compress       = "zstd"
  enabled        = true
  notes_template = "{{guestname}}"
  prune_backups = {
    "keep-last" = "3"
  }
}

resource "proxmox_backup_job" "hermit_weekly" {
  id             = "hermit-weekly"
  schedule       = "sun 04:00" # Sundays at 04:00
  storage        = "local"
  vmid           = ["200"] # hermit
  mode           = "snapshot"
  compress       = "zstd"
  enabled        = true
  notes_template = "{{guestname}}"
  prune_backups = {
    "keep-last" = "1"
  }
}
