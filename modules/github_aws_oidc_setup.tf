variable "repositories" {
  description = "List of GitHub repositories to set up AWS OIDC"
  type        = list(string)
  default     = ["terraform-github-aws-oidc"]
}

module "github_aws_oidc" {
  source  = "git@github.com:observeinc/terraform-github-aws-oidc.git?ref=1.1.2"
  for_each = toset(var.repositories)

  organization = "observeinc" 
  repository   = each.value
  policy_arn   = module.gateway.api_execute_admin_policy_arn
}

output "aws_oidc_role_arns" {
  value = { for repo in var.repositories : repo => module.github_aws_oidc[repo].role_arn }
  description = "The ARNs of the AWS IAM roles created for each GitHub repository"
}
