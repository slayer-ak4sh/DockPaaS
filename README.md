# 🚀 DockPaaS - Event-Driven Docker Deployment Platform

Event-driven, self-documenting deployment platform on AWS with GitOps workflow and zero-downtime deployments.

## 🏗️ Architecture

```
Developer → git push → GitHub
                  ↓
         GitHub Actions (CI/CD)
                  ↓
         Build & Push → ECR
                  ↓
         ECR Push Event → EventBridge
                  ↓
                Lambda
                  ↓
         SSM Run Command → EC2 ASG
                  ↓
   deploy.sh → Blue-Green Switch → Report → S3
                  ↓
         ALB → Routes Traffic
```

## 🎯 Features

- **Event-Driven**: Auto-deploys on ECR image push via EventBridge
- **Blue-Green Deployment**: Zero-downtime container switching
- **Self-Documenting**: Auto-generated deployment reports on S3
- **Auto-Scaling**: EC2 ASG with health checks
- **GitOps Workflow**: Push code → auto-deploy in 2-5 minutes

## 📋 Prerequisites

- AWS Account
- Terraform >= 1.0
- GitHub Account
- AWS CLI configured

## 🚀 Setup Instructions

### 1. Clone & Configure

```bash
cd demo
```

### 2. Configure GitHub Secrets

Add these secrets to your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` (e.g., us-east-2)
- `ECR_REPOSITORY` (value: dockpaas-java)

### 3. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Note the outputs:
- `ecr_repository_url` - Your ECR repo
- `alb_dns_name` - Access your app here
- `s3_website_url` - View deployment reports

### 4. Push Code to Trigger Deployment

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

## 🔄 Deployment Flow

1. **Push Code** → GitHub Actions builds Docker image
2. **Push to ECR** → EventBridge detects new image
3. **Lambda Triggered** → Sends SSM command to EC2 instances
4. **Blue-Green Deploy** → New container starts, old stops
5. **Report Generated** → Uploaded to S3 with metrics

## 📊 View Deployments

Access deployment history at: `http://<s3_website_url>`

Each report includes:
- Deployment timestamp
- Container details
- Health check status
- System metrics (CPU, Memory, Disk)
- Container logs

## 🧪 Test the Application

```bash
# Get ALB DNS from Terraform output
curl http://<alb_dns_name>
# Response: Greetings from Spring Boot!

curl http://<alb_dns_name>/health
# Response: OK
```

## 🏗️ Infrastructure Components

- **VPC**: Custom VPC with 2 public subnets
- **EC2**: Auto Scaling Group (1-3 instances)
- **ALB**: Application Load Balancer with health checks
- **ECR**: Docker image registry
- **Lambda**: Deployment trigger function
- **EventBridge**: ECR push event detection
- **S3**: Static website for deployment reports
- **IAM**: Roles for EC2, Lambda with least privilege

## 💰 Cost Optimization

- Uses t3.micro instances (free tier eligible)
- ECR lifecycle policy (keeps last 10 images)
- Can use Spot instances for further savings
- Auto-scaling based on demand

## 🔧 Customization

Edit `terraform/variables.tf`:
```hcl
variable "instance_type" {
  default = "t3.micro"  # Change instance size
}

variable "asg_desired_capacity" {
  default = 2  # Change number of instances
}
```

## 📝 Project Structure

```
demo/
├── .github/workflows/
│   └── build-and-push-ecr.yml    # CI/CD pipeline
├── src/                           # Spring Boot app
├── scripts/
│   ├── user_data.sh              # EC2 initialization
│   ├── lambda_function.py        # Deployment trigger
├── terraform/
│   ├── main.tf                   # ECR repository
│   ├── vpc.tf                    # Network infrastructure
│   ├── ec2.tf                    # Compute resources
│   ├── alb.tf                    # Load balancer
│   ├── lambda.tf                 # Lambda function
│   ├── eventbridge.tf            # Event rules
│   ├── s3.tf                     # Deployment reports
│   ├── iam.tf                    # IAM roles/policies
│   └── security_groups.tf        # Security groups
├── Dockerfile                     # Multi-stage build
└── pom.xml                        # Maven config
```

## 🎓 Learning Outcomes

- Event-driven architecture with EventBridge
- Blue-green deployment pattern
- Infrastructure as Code with Terraform
- CI/CD with GitHub Actions
- Docker containerization
- AWS services integration (EC2, ECR, Lambda, ALB, S3)
- Auto-scaling and high availability

## 🐛 Troubleshooting

**Deployment not triggering?**
- Check EventBridge rule is enabled
- Verify Lambda has SSM permissions
- Check EC2 instances have `AutoDeploy=true` tag

**Health checks failing?**
- Ensure security group allows ALB → EC2 on port 8081
- Check container logs: `docker logs dockpaas-app`

**Can't access ALB?**
- Wait 2-3 minutes for instances to be healthy
- Check target group health in AWS Console

## 📚 Next Steps

- Add HTTPS with ACM certificate
- Implement CloudWatch alarms
- Add RDS database integration
- Set up CloudFront CDN
- Implement rollback mechanism

## 🤝 Contributing

This is a learning project. Feel free to fork and enhance!

## 📄 License

MIT License - Free to use for learning and portfolio projects.

---

**Built with ❤️ using AWS, Terraform, Docker, and Spring Boot**
