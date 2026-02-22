# Contributing to DockPaaS

Thank you for your interest in contributing to DockPaaS! This is a learning project designed to demonstrate event-driven deployment architecture on AWS.

## How to Contribute

### 1. Fork the Repository
```bash
git clone https://github.com/yourusername/dockpaas.git
cd dockpaas
```

### 2. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
```

### 3. Make Your Changes
- Follow existing code style
- Test your changes locally
- Update documentation if needed

### 4. Commit Your Changes
```bash
git add .
git commit -m "Add: brief description of changes"
```

### 5. Push and Create Pull Request
```bash
git push origin feature/your-feature-name
```

## Development Setup

### Prerequisites
- AWS Account with CLI configured
- Terraform >= 1.0
- Docker installed locally
- Java 21 and Maven

### Local Testing
```bash
# Build the application
mvn clean package

# Build Docker image
docker build -t dockpaas-java:local .

# Run locally
docker run -p 8081:8081 dockpaas-java:local

# Test endpoints
curl http://localhost:8081
curl http://localhost:8081/health
```

### Testing Infrastructure Changes
```bash
cd terraform
terraform plan
# Review changes before applying
terraform apply
```

## Enhancement Ideas

- [ ] Add HTTPS support with ACM
- [ ] Implement CloudWatch alarms
- [ ] Add RDS database integration
- [ ] Create rollback mechanism
- [ ] Add CloudFront CDN
- [ ] Implement automated testing
- [ ] Add monitoring dashboard
- [ ] Support multiple environments (dev/staging/prod)

## Code Style

- Use meaningful variable names
- Add comments for complex logic
- Follow Terraform best practices
- Keep functions small and focused

## Questions?

Feel free to open an issue for discussion!

## License

MIT License - Free to use for learning and portfolio projects.
