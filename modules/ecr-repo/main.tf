resource "aws_ecr_repository" "this" {
  for_each = var.repositories

  name                 = each.key
  image_tag_mutability = var.immutability
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, { Module = "ecr-repo" })
}

# Lifecycle policy: (1) expire untagged images after N days; (2) keep newest N tagged images by prefix
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.repositories

  repository = aws_ecr_repository.this[each.key].name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than ${var.untagged_expire_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_expire_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the newest ${var.keep_tagged_max_count} tagged images matching prefixes ${join(", ", each.value.tags_prefixes)}"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = each.value.tags_prefixes
          countType     = "imageCountMoreThan"
          countNumber   = var.keep_tagged_max_count
        }
        action = { type = "expire" }
      }
    ]
  })
}
