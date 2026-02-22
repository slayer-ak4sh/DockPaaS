# DockPaaS Troubleshooting Guide

## Common Issues and Solutions

### 1. Deployment Not Triggering

**Symptoms:**
- Code pushed to GitHub but no deployment happens
- No new containers running on EC2

**Solutions:**

**Check EventBridge Rule:**
```bash
aws events describe-rule --name dockpaas-ecr-push-rule
```
Ensure `State: "ENABLED"`

**Check Lambda Permissions:**
```bash
aws lambda get-policy --function-name dockpaas-deployment-trigger
```

**Check EC2 Tags:**
```bash
aws ec2 describe-instances --filters "Name=tag:AutoDeploy,Values=true"
```
Instances must have `AutoDeploy=true` tag

**View Lambda Logs:**
```bash
aws logs tail /aws/lambda/dockpaas-deployment-trigger --follow
```

### 2. Health Checks Failing

**Symptoms:**
- ALB shows unhealthy targets
- Cannot access application via ALB DNS

**Solutions:**

**Check Security Groups:**
```bash
# Verify ALB can reach EC2 on port 8081
aws ec2 describe-security-groups --group-ids <ec2-sg-id>
```

**Check Container Status:**
```bash
# SSH into EC2 instance
docker ps
docker logs dockpaas-app
```

**Test Health Endpoint Locally:**
```bash
curl http://localhost:8081/health
```

**Check Target Group Health:**
```bash
aws elbv2 describe-target-health --target-group-arn <tg-arn>
```

### 3. Cannot Access Application

**Symptoms:**
- ALB DNS not responding
- Connection timeout

**Solutions:**

**Wait for Instances to be Healthy:**
- Initial deployment takes 2-3 minutes
- Check AWS Console → EC2 → Target Groups

**Verify ALB DNS:**
```bash
# Get ALB DNS from Terraform output
terraform output alb_dns_name

# Test connection
curl http://<alb-dns-name>
```

**Check ALB Security Group:**
```bash
# Should allow port 80 from 0.0.0.0/0
aws ec2 describe-security-groups --group-ids <alb-sg-id>
```

### 4. ECR Push Fails in GitHub Actions

**Symptoms:**
- GitHub Actions workflow fails at ECR push step
- Authentication errors

**Solutions:**

**Verify GitHub Secrets:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` (e.g., us-east-2)
- `ECR_REPOSITORY` (value: dockpaas-java)

**Check IAM Permissions:**
User needs:
- `ecr:GetAuthorizationToken`
- `ecr:BatchCheckLayerAvailability`
- `ecr:PutImage`
- `ecr:InitiateLayerUpload`
- `ecr:UploadLayerPart`
- `ecr:CompleteLayerUpload`

**Verify ECR Repository Exists:**
```bash
aws ecr describe-repositories --repository-names dockpaas-java
```

### 5. Terraform Apply Fails

**Symptoms:**
- Resource already exists errors
- Permission denied errors

**Solutions:**

**Import Existing Resources:**
```bash
terraform import aws_ecr_repository.ecr_dock dockpaas-java
```

**Check AWS Credentials:**
```bash
aws sts get-caller-identity
```

**Verify IAM Permissions:**
User needs permissions for:
- EC2, VPC, ALB, ECR, Lambda, EventBridge, S3, IAM

**Clean State (if needed):**
```bash
cd terraform
rm -rf .terraform
rm terraform.tfstate*
terraform init
```

### 6. S3 Deployment Reports Not Accessible

**Symptoms:**
- 403 Forbidden when accessing S3 website URL
- Reports not uploading

**Solutions:**

**Check S3 Bucket Policy:**
```bash
aws s3api get-bucket-policy --bucket <bucket-name>
```

**Verify Public Access Settings:**
```bash
aws s3api get-public-access-block --bucket <bucket-name>
```

**Check EC2 IAM Role:**
```bash
# EC2 needs s3:PutObject and s3:PutObjectAcl
aws iam get-role-policy --role-name dockpaas-ec2-role --policy-name dockpaas-ec2-policy
```

**Test Upload Manually:**
```bash
# From EC2 instance
echo "test" > /tmp/test.txt
aws s3 cp /tmp/test.txt s3://<bucket-name>/test.txt --acl public-read
```

### 7. Docker Container Won't Start

**Symptoms:**
- Container exits immediately
- Application errors in logs

**Solutions:**

**Check Container Logs:**
```bash
docker logs dockpaas-app
```

**Verify Image:**
```bash
docker images | grep dockpaas
docker inspect <image-id>
```

**Test Locally:**
```bash
docker run -it --rm -p 8081:8081 <ecr-repo>:latest
```

**Check Port Conflicts:**
```bash
netstat -tulpn | grep 8081
```

### 8. SSM Command Not Executing

**Symptoms:**
- Lambda triggers but deployment doesn't run
- No SSM command history

**Solutions:**

**Check SSM Agent:**
```bash
# On EC2 instance
systemctl status amazon-ssm-agent
```

**Verify IAM Instance Profile:**
```bash
aws ec2 describe-instances --instance-ids <instance-id> --query 'Reservations[0].Instances[0].IamInstanceProfile'
```

**Check SSM Command History:**
```bash
aws ssm list-commands --filters "Key=InvokedAfter,Value=2024-01-01"
```

**View Command Output:**
```bash
aws ssm get-command-invocation --command-id <command-id> --instance-id <instance-id>
```

## Getting Help

1. Check CloudWatch Logs for all services
2. Review AWS Console for resource status
3. Verify all tags are correctly applied
4. Ensure security groups allow required traffic
5. Check IAM permissions for all roles

## Useful Commands

```bash
# View all DockPaaS resources
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=DockPaas

# Check EC2 instance user data execution
cat /var/log/cloud-init-output.log

# View deployment script logs
tail -f /var/log/messages | grep docker

# Test deployment script manually
cd /opt/dockpaas
source .env
./deploy.sh
```

## Still Having Issues?

Open an issue on GitHub with:
- Error messages
- CloudWatch logs
- Steps to reproduce
- AWS region and resource IDs
