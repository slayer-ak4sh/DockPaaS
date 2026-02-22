# Security Best Practices

## Current Security Measures

### 1. IAM Roles (Least Privilege)
- EC2 instances use IAM roles (no hardcoded credentials)
- Lambda has minimal permissions (SSM, EC2 describe only)
- Separate roles for EC2 and Lambda

### 2. Network Security
- VPC with isolated subnets
- Security groups restrict traffic:
  - ALB: Only port 80 inbound
  - EC2: Only port 8081 from ALB
- No SSH access required (using SSM Session Manager)

### 3. Container Security
- Multi-stage Docker builds (smaller attack surface)
- ECR image scanning enabled
- Non-root user in containers (recommended)

### 4. Secrets Management
- GitHub Secrets for CI/CD credentials
- No credentials in code or Terraform state
- IAM roles for AWS service authentication

### 5. Monitoring
- CloudWatch logs for Lambda and EC2
- EventBridge for audit trail
- ALB access logs (can be enabled)

## Recommended Enhancements

### 1. Enable HTTPS
```hcl
# Add to alb.tf
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
```

### 2. Use AWS Secrets Manager
```bash
# Store sensitive configuration
aws secretsmanager create-secret \
  --name dockpaas/config \
  --secret-string '{"db_password":"xxx"}'
```

### 3. Enable VPC Flow Logs
```hcl
resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
}
```

### 4. Implement WAF
```hcl
resource "aws_wafv2_web_acl" "main" {
  name  = "dockpaas-waf"
  scope = "REGIONAL"
  
  default_action {
    allow {}
  }
  
  rule {
    name     = "RateLimitRule"
    priority = 1
    
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    
    action {
      block {}
    }
  }
}
```

### 5. Enable GuardDuty
```bash
aws guardduty create-detector --enable
```

### 6. Use Private Subnets for EC2
- Move EC2 instances to private subnets
- Use NAT Gateway for outbound traffic
- Keep ALB in public subnets

### 7. Implement Backup Strategy
```hcl
resource "aws_backup_plan" "main" {
  name = "dockpaas-backup-plan"
  
  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)"
    
    lifecycle {
      delete_after = 7
    }
  }
}
```

### 8. Enable CloudTrail
```hcl
resource "aws_cloudtrail" "main" {
  name                          = "dockpaas-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
}
```

## Security Checklist

- [ ] Use HTTPS/TLS for all traffic
- [ ] Enable MFA for AWS root account
- [ ] Rotate IAM access keys regularly
- [ ] Use AWS Secrets Manager for sensitive data
- [ ] Enable CloudTrail for audit logging
- [ ] Implement least privilege IAM policies
- [ ] Use private subnets for compute resources
- [ ] Enable VPC Flow Logs
- [ ] Implement WAF rules
- [ ] Enable GuardDuty threat detection
- [ ] Regular security patching (AMI updates)
- [ ] Enable ECR image scanning
- [ ] Use IMDSv2 for EC2 metadata (already enabled)
- [ ] Implement backup and disaster recovery
- [ ] Regular security audits

## Compliance Considerations

### GDPR
- Ensure data residency requirements
- Implement data encryption at rest
- Enable audit logging

### HIPAA
- Use encrypted EBS volumes
- Enable CloudTrail
- Implement access controls

### PCI DSS
- Network segmentation
- Encryption in transit and at rest
- Regular security testing

## Incident Response

1. **Detection**: CloudWatch Alarms, GuardDuty
2. **Isolation**: Security group rules, NACL
3. **Investigation**: CloudTrail, VPC Flow Logs
4. **Recovery**: Automated backups, blue-green rollback
5. **Post-Mortem**: Document and improve

## Reporting Security Issues

If you discover a security vulnerability:
1. Do NOT open a public issue
2. Email: security@yourcompany.com
3. Include detailed description and steps to reproduce
4. Allow 90 days for fix before public disclosure

## Resources

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
