# DockPaaS Architecture Diagram

## Complete Flow

```
┌─────────────┐
│  Developer  │
└──────┬──────┘
       │ git push
       ▼
┌─────────────────┐
│  GitHub Repo    │
└──────┬──────────┘
       │ webhook trigger
       ▼
┌──────────────────────┐
│  GitHub Actions      │
│  - Build Java App    │
│  - Build Docker Img  │
└──────┬───────────────┘
       │ docker push
       ▼
┌──────────────────────┐
│  Amazon ECR          │
│  dockpaas-java:latest│
└──────┬───────────────┘
       │ Image Push Event
       ▼
┌──────────────────────┐
│  EventBridge Rule    │
│  (ECR Push Detector) │
└──────┬───────────────┘
       │ trigger
       ▼
┌──────────────────────┐
│  Lambda Function     │
│  deployment-trigger  │
└──────┬───────────────┘
       │ SSM Send Command
       ▼
┌────────────────────────────────┐
│  EC2 Auto Scaling Group        │
│  ┌──────────┐  ┌──────────┐   │
│  │Instance 1│  │Instance 2│   │
│  │          │  │          │   │
│  │ Docker   │  │ Docker   │   │
│  │ Blue:8081│  │ Blue:8081│   │
│  │ Green:8082  │ Green:8082  │
│  └────┬─────┘  └────┬─────┘   │
└───────┼─────────────┼──────────┘
        │             │
        │ deploy.sh runs:
        │ 1. Pull new image
        │ 2. Start on Green port
        │ 3. Health check
        │ 4. Stop Blue container
        │ 5. Switch ports
        │ 6. Generate report
        │
        ▼
┌──────────────────────┐
│  S3 Bucket           │
│  deployment-reports/ │
│  - index.html        │
│  - deployment-*.md   │
└──────────────────────┘
        │
        │ Public Access
        ▼
┌──────────────────────┐
│  Users View Reports  │
│  http://bucket.s3... │
└──────────────────────┘

        ┌─────────────────┐
        │ Application LB  │
        │ Port 80         │
        └────┬────────────┘
             │ Health Check: /health
             │ Forward to: 8081
             ▼
    ┌────────────────────┐
    │  Target Group      │
    │  EC2 Instances     │
    │  Port 8081         │
    └────────────────────┘
```

## Network Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                    │
│                                                         │
│  ┌──────────────────────┐  ┌──────────────────────┐   │
│  │  Public Subnet 1     │  │  Public Subnet 2     │   │
│  │  10.0.1.0/24         │  │  10.0.2.0/24         │   │
│  │  AZ: us-east-2a      │  │  AZ: us-east-2b      │   │
│  │                      │  │                      │   │
│  │  ┌──────────────┐    │  │  ┌──────────────┐    │   │
│  │  │ EC2 Instance │    │  │  │ EC2 Instance │    │   │
│  │  │ Docker Host  │    │  │  │ Docker Host  │    │   │
│  │  └──────────────┘    │  │  └──────────────┘    │   │
│  │                      │  │                      │   │
│  │  ┌──────────────┐    │  │                      │   │
│  │  │     ALB      │────┼──┼──────────────────────┤   │
│  │  └──────────────┘    │  │                      │   │
│  └──────────────────────┘  └──────────────────────┘   │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │           Internet Gateway                       │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
                    Internet
```

## Security Groups

```
┌─────────────────────────────────────┐
│  ALB Security Group                 │
│  Inbound:                           │
│  - Port 80 from 0.0.0.0/0          │
│  Outbound:                          │
│  - All traffic                      │
└─────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│  EC2 Security Group                 │
│  Inbound:                           │
│  - Port 8081 from ALB SG           │
│  Outbound:                          │
│  - All traffic (ECR, S3, SSM)      │
└─────────────────────────────────────┘
```

## IAM Roles & Permissions

```
┌─────────────────────────────────────┐
│  EC2 IAM Role                       │
│  - ECR: Pull images                 │
│  - S3: Upload reports               │
│  - SSM: Session Manager             │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Lambda IAM Role                    │
│  - SSM: Send commands               │
│  - EC2: Describe instances          │
│  - CloudWatch: Logs                 │
└─────────────────────────────────────┘
```

## Blue-Green Deployment Process

```
Initial State:
┌──────────────────┐
│ Container: Blue  │
│ Port: 8081       │
│ Status: Running  │
└──────────────────┘

New Deployment:
┌──────────────────┐     ┌──────────────────┐
│ Container: Blue  │     │ Container: Green │
│ Port: 8081       │     │ Port: 8082       │
│ Status: Running  │     │ Status: Starting │
└──────────────────┘     └──────────────────┘

Health Check Pass:
┌──────────────────┐     ┌──────────────────┐
│ Container: Blue  │     │ Container: Green │
│ Port: 8081       │     │ Port: 8082       │
│ Status: Running  │     │ Status: Healthy  │
└──────────────────┘     └──────────────────┘

Switch Traffic (iptables redirect 8081 → 8082):
┌──────────────────┐     ┌──────────────────┐
│ Container: Blue  │     │ Container: Green │
│ Port: 8081       │     │ Port: 8082       │
│ Status: Stopping │     │ Status: Active   │
└──────────────────┘     └──────────────────┘

Final State:
                         ┌──────────────────┐
                         │ Container: Green │
                         │ Port: 8082       │
                         │ Status: Running  │
                         └──────────────────┘
                         (Renamed to "dockpaas-app")
```

## Deployment Timeline

```
T+0s    : Developer pushes code to GitHub
T+30s   : GitHub Actions starts build
T+2m    : Docker image built and pushed to ECR
T+2m 5s : EventBridge detects ECR push event
T+2m 6s : Lambda function triggered
T+2m 7s : SSM command sent to EC2 instances
T+2m 10s: EC2 instances start pulling new image
T+2m 30s: New container starts on Green port
T+2m 40s: Health checks pass
T+2m 45s: Old container stopped, traffic switched
T+2m 50s: Deployment report generated
T+3m    : Report uploaded to S3
T+3m 5s : Deployment complete ✅
```

## Cost Breakdown (Monthly Estimate)

```
┌─────────────────────────────────────────────┐
│ Service          │ Usage        │ Cost      │
├─────────────────────────────────────────────┤
│ EC2 (t3.micro)   │ 2 instances  │ ~$15      │
│ ALB              │ 1 ALB        │ ~$16      │
│ ECR              │ <500MB       │ ~$0.50    │
│ S3               │ <1GB         │ ~$0.10    │
│ Lambda           │ <1000 invoc. │ Free      │
│ EventBridge      │ <1M events   │ Free      │
│ Data Transfer    │ <1GB         │ ~$1       │
├─────────────────────────────────────────────┤
│ TOTAL            │              │ ~$33/mo   │
└─────────────────────────────────────────────┘

Note: Can reduce to ~$15/mo with 1 instance + Spot
```
