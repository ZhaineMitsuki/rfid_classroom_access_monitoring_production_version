#!/bin/bash
# AWS Setup Script for RFID Classroom Access Monitoring
# Run this script locally to prepare for AWS deployment

set -e

echo "🚀 AWS Deployment Setup for RFID Classroom Access Monitoring"
echo "============================================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Check prerequisites
echo ""
print_info "Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI not found. Please install it first:"
    echo "  macOS: brew install awscli"
    echo "  Windows: Download from https://aws.amazon.com/cli/"
    echo "  Linux: sudo apt install awscli or sudo yum install awscli"
    exit 1
else
    print_success "AWS CLI found"
fi

# Check if AWS is configured
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS CLI not configured. Please run: aws configure"
    echo "You'll need:"
    echo "  • AWS Access Key ID"
    echo "  • AWS Secret Access Key"
    echo "  • Default region (e.g., us-east-1)"
    echo "  • Default output format (json)"
    exit 1
else
    print_success "AWS CLI configured"
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region)
    print_info "Account ID: $AWS_ACCOUNT_ID"
    print_info "Region: $AWS_REGION"
fi

# Create .env.example for AWS
echo ""
print_info "Creating environment configuration files..."

cat > .env.aws.example << 'EOF'
# AWS Configuration
RAILS_ENV=production
AWS_REGION=ap-southeast-1
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
S3_BUCKET_NAME=classroom-monitoring-assets-ACCOUNT_ID

# Database Configuration
DATABASE_URL=postgresql://postgres:PASSWORD@RDS_ENDPOINT:5432/classroom_access_production

# Redis Configuration  
REDIS_URL=redis://REDIS_ENDPOINT:6379/0

# Rails Configuration
SECRET_KEY_BASE=generate_with_rails_secret
RAILS_MASTER_KEY=your_master_key_here
RAILS_SERVE_STATIC_FILES=true

# Email Configuration (Choose one)
# Option 1: SMTP (Gmail)
SMTP_USERNAME=your_gmail@gmail.com
SMTP_PASSWORD=your_app_password
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587

# Option 2: AWS SES (Alternative)
# SES_REGION=us-east-1
# SES_ACCESS_KEY_ID=your_ses_access_key
# SES_SECRET_ACCESS_KEY=your_ses_secret_key

# Application Configuration
DOMAIN_NAME=your-domain.com
FORCE_SSL=false

# Encryption (Keep your existing values)
ENCRYPTION_KEY=your_existing_encryption_key
ENCRYPTION_IV=your_existing_encryption_iv
EOF

print_success "Created .env.aws.example"

# Generate Rails secret
if command -v rails &> /dev/null && [ -f "Gemfile" ]; then
    echo ""
    print_info "Generating Rails secret key..."
    SECRET_KEY=$(bundle exec rails secret 2>/dev/null || openssl rand -hex 64)
    echo "SECRET_KEY_BASE=$SECRET_KEY" > .rails_secret
    print_success "Rails secret generated and saved to .rails_secret"
    print_warning "Add this to your environment variables!"
else
    print_warning "Rails not found. You'll need to generate SECRET_KEY_BASE manually"
fi

# Create CloudFormation parameter file
echo ""
print_info "Creating CloudFormation parameters file..."

cat > aws-parameters.json << EOF
[
  {
    "ParameterKey": "KeyName",
    "ParameterValue": "your-ec2-key-pair"
  },
  {
    "ParameterKey": "DBUsername", 
    "ParameterValue": "postgres"
  },
  {
    "ParameterKey": "DBPassword",
    "ParameterValue": "YourSecurePassword123!"
  }
]
EOF

print_success "Created aws-parameters.json"

# Create deployment checklist
echo ""
print_info "Creating deployment checklist..."

cat > DEPLOYMENT_CHECKLIST.md << 'EOF'
# AWS Deployment Checklist

## Before You Start
- [ ] AWS CLI installed and configured
- [ ] EC2 Key Pair created in your AWS region
- [ ] Domain name ready (optional)

## Step 1: Deploy Infrastructure
```bash
# Update aws-parameters.json with your values
aws cloudformation create-stack \
  --stack-name classroom-monitoring \
  --template-body file://aws-deployment.md \
  --parameters file://aws-parameters.json \
  --capabilities CAPABILITY_IAM
```

## Step 2: Wait for Infrastructure
```bash
# Check status
aws cloudformation describe-stacks \
  --stack-name classroom-monitoring \
  --query 'Stacks[0].StackStatus'
```

## Step 3: Get Infrastructure Details
```bash
# Get outputs
aws cloudformation describe-stacks \
  --stack-name classroom-monitoring \
  --query 'Stacks[0].Outputs'
```

## Step 4: Deploy Application
1. SSH into EC2 instance
2. Copy and run the deploy-aws.sh script
3. Update environment variables with real AWS endpoints

## Step 5: Configure Load Balancer
1. Create target group pointing to EC2 instance
2. Update ALB listener to forward to target group
3. Configure health checks

## Step 6: Set Up Domain (Optional)
1. Point your domain to ALB DNS name
2. Request SSL certificate in AWS Certificate Manager
3. Add HTTPS listener to ALB

## Step 7: Final Configuration
- [ ] Test application access
- [ ] Verify email sending
- [ ] Check RFID functionality
- [ ] Set up monitoring alerts
- [ ] Configure backups

## Important Commands
```bash
# SSH to EC2
ssh -i your-key.pem ec2-user@EC2_PUBLIC_IP

# Check application status
sudo systemctl status classroom-monitoring

# View application logs
sudo journalctl -u classroom-monitoring -f

# Restart application
sudo systemctl restart classroom-monitoring
```

## Cost Monitoring
- Set up billing alerts in AWS
- Monitor free tier usage
- Plan for post-free-tier costs (~$35-50/month)
EOF

print_success "Created DEPLOYMENT_CHECKLIST.md"

# Create quick start script
echo ""
print_info "Creating quick start script..."

cat > quick-deploy.sh << 'EOF'
#!/bin/bash
# Quick AWS deployment script

echo "🚀 Quick AWS Deployment"

# Check if parameters file exists
if [ ! -f "aws-parameters.json" ]; then
    echo "❌ aws-parameters.json not found. Please update it with your values."
    exit 1
fi

# Deploy CloudFormation stack
echo "📦 Deploying infrastructure..."
aws cloudformation create-stack \
  --stack-name classroom-monitoring \
  --template-body file://aws-deployment.md \
  --parameters file://aws-parameters.json \
  --capabilities CAPABILITY_IAM

echo "⏳ Waiting for stack creation..."
aws cloudformation wait stack-create-complete \
  --stack-name classroom-monitoring

echo "✅ Infrastructure deployed!"

# Get outputs
echo "📋 Infrastructure details:"
aws cloudformation describe-stacks \
  --stack-name classroom-monitoring \
  --query 'Stacks[0].Outputs' \
  --output table

echo ""
echo "🎯 Next steps:"
echo "1. SSH into the EC2 instance"
echo "2. Run the deploy-aws.sh script"
echo "3. Configure your domain (optional)"
echo "4. Test the application"
EOF

chmod +x quick-deploy.sh
print_success "Created quick-deploy.sh"

# Final instructions
echo ""
echo "🎉 AWS setup preparation complete!"
echo ""
print_info "Next steps:"
echo "1. 📝 Update aws-parameters.json with your EC2 key pair name and database password"
echo "2. 🔑 Create an EC2 Key Pair in AWS Console if you don't have one"
echo "3. 🚀 Run ./quick-deploy.sh to deploy infrastructure"
echo "4. 📋 Follow DEPLOYMENT_CHECKLIST.md for complete setup"
echo ""
print_warning "Important files created:"
echo "  • .env.aws.example - Environment variables template"
echo "  • aws-parameters.json - CloudFormation parameters"
echo "  • DEPLOYMENT_CHECKLIST.md - Step-by-step guide"
echo "  • quick-deploy.sh - Automated deployment script"
echo "  • .rails_secret - Generated Rails secret key"
echo ""
print_info "Estimated costs:"
echo "  • First 12 months: ~$6/year (Route 53 only)"
echo "  • After free tier: ~$35-50/month"
echo ""
print_success "You're ready to deploy to AWS! 🚀" 