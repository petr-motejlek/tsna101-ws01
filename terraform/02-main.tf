provider "aws" {
  region = var.aws_region

  # Why: default_tags propagate to every resource automatically, so we never
  # forget to tag something. Individual resources can still override or add tags.
  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Workshop  = "01"
    }
  }
}

# ---------------------------------------------------------------------------
# Data sources
# ---------------------------------------------------------------------------

# Why: We pin to the first two AZs so the code is deterministic regardless of
# how many AZs the region has. eu-west-1 has 3 (a/b/c); we use a and b.
data "aws_availability_zones" "available" {
  state = "available"
}

# Why: Useful for constructing ARNs and for outputs that help participants
# verify they are working in the correct account.
data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------------

locals {
  # Why: A reusable map of AZ short labels → full AZ names. Using a map
  # (not a list) gives us stable for_each keys ("a", "b") that survive
  # AZ additions/removals without forcing resource recreation.
  azs = {
    "a" = data.aws_availability_zones.available.names[0]
    "b" = data.aws_availability_zones.available.names[1]
  }
}
