# ☁️ Cloud Resume Challenge — Automated with Terraform & AWS

This project is a fully automated deployment of a personal resume website hosted on AWS CloudFront + S3, with infrastructure managed via Terraform and continuous deployment handled by GitHub Actions using OpenID Connect (OIDC) for secure, keyless authentication.

I built this as my first end-to-end cloud automation project — not just to host a static site, but to prove I can design, provision, and automate a full-stack infrastructure from scratch.

🔗 Live site: https://d13gyj40wuzghb.cloudfront.net

---

### 🧭 What This Project Demonstrates
- End-to-end Infrastructure as Code with Terraform
- Secure remote backend (S3 + DynamoDB state locking)
- Automated deployment using GitHub Actions + OIDC
- Static hosting via S3 + CloudFront + ACM certificate
- Real-world DevOps pipeline workflows (`plan` + `apply`)
