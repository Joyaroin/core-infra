terraform {
  # Which Terraform version this code needs. 1.11+ for state locking on R2.
  required_version = ">= 1.11"

  # The state lives in Cloudflare R2 (S3-compatible), next to the Cloudflare
  # stack's in the same bucket, so it survives losing the Mac. The access key
  # is in backend.credentials.hcl (git-ignored), passed to `terraform init`.
  backend "s3" {
    bucket = "mediasafe-tfstate"
    key    = "core-infra/terraform.tfstate"
    region = "auto"
    endpoints = {
      s3 = "https://e611254754d8c1922b8ead788aab6f40.r2.cloudflarestorage.com"
    }

    # R2 isn't AWS, so skip AWS's own checks.
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true

    use_lockfile = true # stops two runs changing things at once
  }

  required_providers {
    # "proxmox" is the local name we'll use in this code.
    proxmox = {
      source  = "bpg/proxmox" # registry.terraform.io/bpg/proxmox
      version = "~> 0.122.0"  # allows 0.122.x only
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.29.0"
    }
  }
}
