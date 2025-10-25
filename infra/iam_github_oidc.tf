#############################################
# GitHub OIDC → IAM role for Terraform CI
#############################################

# 1) OIDC provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # GitHub’s current root CA thumbprint
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# 2) Role that GitHub Actions can assume (branch-locked)
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-ci"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
      Action    = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        },
        StringLike = {
          # Lock to your repo + main branch
          "token.actions.githubusercontent.com:sub" = "repo:Freshslade/cloud-resume:ref:refs/heads/main"
        }
      }
    }]
  })
}

# 3) Permissions for Terraform to manage this stack
resource "aws_iam_policy" "github_actions_policy" {
  name = "github-actions-terraform-ci-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # identity
      { Effect = "Allow", Action = ["sts:GetCallerIdentity"], Resource = "*" },

      # hosting stack permissions
      { Effect = "Allow", Action = ["s3:*"], Resource = ["*"] },
      { Effect = "Allow", Action = ["cloudfront:*"], Resource = ["*"] },

      # ACM read (include tags)
      { Effect = "Allow", Action = [
        "acm:ListCertificates",
        "acm:DescribeCertificate",
        "acm:ListTagsForCertificate"
      ], Resource = "*" },

      # state lock infra
      { Effect = "Allow", Action = ["dynamodb:*"], Resource = ["*"] },

      # optional for future API/Lambda work
      { Effect = "Allow", Action = ["apigateway:*", "lambda:*", "logs:*"], Resource = ["*"] },

      # IAM reads needed by Terraform during refresh/plan
      { Effect = "Allow", Action = [
        "iam:GetOpenIDConnectProvider",
        "iam:ListOpenIDConnectProviders",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:GetRole",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies"
      ], Resource = "*" }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ci_policy" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
