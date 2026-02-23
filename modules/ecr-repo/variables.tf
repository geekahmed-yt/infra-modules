variable "repositories" {
  description = "Map of repository name to config. Each value must have tags_prefixes (list of tag prefixes for lifecycle 'keep newest N' rule). Example: { scraper = { tags_prefixes = [\"v\", \"sha-\"] } }"
  type = map(object({
    tags_prefixes = list(string)
  }))
}

variable "scan_on_push" {
  description = "Enable image scanning on push to surface CVEs at push time."
  type        = bool
  default     = true
}

variable "immutability" {
  description = "Image tag mutability: IMMUTABLE prevents overwriting tags; MUTABLE allows overwrites."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.immutability)
    error_message = "immutability must be \"IMMUTABLE\" or \"MUTABLE\"."
  }
}

variable "untagged_expire_days" {
  description = "Lifecycle rule: expire untagged images older than this many days."
  type        = number
  default     = 7
}

variable "keep_tagged_max_count" {
  description = "Lifecycle rule: retain only the newest N tagged images matching tag prefixes per repository."
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags to merge into all ECR resources."
  type        = map(string)
  default     = {}
}
