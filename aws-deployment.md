# AWS Free Tier Deployment Guide
## RFID Classroom Access Monitoring System

### 🎯 Architecture Overview
```
[Route 53] → [Application Load Balancer] → [EC2 t2.micro] → [RDS PostgreSQL t2.micro]
                                                         → [ElastiCache Redis t2.micro]
                                                         → [S3 Bucket]
```

### 💰 Cost Breakdown (First 12 Months)
- **EC2 t2.micro**: $0.00 (750 hours free/month)
- **RDS t2.micro**: $0.00 (750 hours free/month)
- **ElastiCache t2.micro**: $0.00 (750 hours free/month)
- **ALB**: $0.00 (750 hours free/month)
- **S3**: $0.00 (5 GB free)
- **Data Transfer**: $0.00 (15 GB free/month)
- **Route 53**: $0.50/month (hosted zone)

**Total Year 1: ~$6.00**

### 📋 Prerequisites
- AWS Account (credit card required for verification, won't be charged)
- Domain name (optional, can use AWS provided URLs)
- Your Rails application code

### 🚀 Step 1: Create AWS Resources

#### CloudFormation Template
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'RFID Classroom Monitoring - Free Tier Setup'

Parameters:
  KeyName:
    Type: AWS::EC2::KeyPair::KeyName
    Description: EC2 Key Pair for SSH access
  
  DBUsername:
    Type: String
    Default: postgres
    Description: Database master username
  
  DBPassword:
    Type: String
    NoEcho: true
    MinLength: 8
    Description: Database master password

Resources:
  # VPC and Networking
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: classroom-monitoring-vpc

  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: Public Subnet 1

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [1, !GetAZs '']
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: Public Subnet 2

  PrivateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.3.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      Tags:
        - Key: Name
          Value: Private Subnet 1

  PrivateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.4.0/24
      AvailabilityZone: !Select [1, !GetAZs '']
      Tags:
        - Key: Name
          Value: Private Subnet 2

  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: classroom-monitoring-igw

  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC
      InternetGatewayId: !Ref InternetGateway

  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: Public Route Table

  PublicRoute:
    Type: AWS::EC2::Route
    DependsOn: AttachGateway
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  PublicSubnetRouteTableAssociation1:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet1
      RouteTableId: !Ref PublicRouteTable

  PublicSubnetRouteTableAssociation2:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref PublicSubnet2
      RouteTableId: !Ref PublicRouteTable

  # Security Groups
  WebServerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for web server
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          SourceSecurityGroupId: !Ref ALBSecurityGroup
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          SourceSecurityGroupId: !Ref ALBSecurityGroup
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 3000
          ToPort: 3000
          SourceSecurityGroupId: !Ref ALBSecurityGroup
      Tags:
        - Key: Name
          Value: WebServer-SG

  ALBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for Application Load Balancer
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
      Tags:
        - Key: Name
          Value: ALB-SG

  DatabaseSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for RDS database
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          SourceSecurityGroupId: !Ref WebServerSecurityGroup
      Tags:
        - Key: Name
          Value: Database-SG

  RedisSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for Redis cache
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 6379
          ToPort: 6379
          SourceSecurityGroupId: !Ref WebServerSecurityGroup
      Tags:
        - Key: Name
          Value: Redis-SG

  # RDS Database
  DBSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupDescription: Subnet group for RDS database
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
      Tags:
        - Key: Name
          Value: db-subnet-group

  RDSInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceIdentifier: classroom-monitoring-db
      DBInstanceClass: db.t2.micro
      Engine: postgres
      EngineVersion: '15.4'
      AllocatedStorage: 20
      StorageType: gp2
      DBName: classroom_access_production
      MasterUsername: !Ref DBUsername
      MasterUserPassword: !Ref DBPassword
      VPCSecurityGroups:
        - !Ref DatabaseSecurityGroup
      DBSubnetGroupName: !Ref DBSubnetGroup
      BackupRetentionPeriod: 7
      DeletionProtection: false
      Tags:
        - Key: Name
          Value: classroom-monitoring-db

  # ElastiCache Redis
  CacheSubnetGroup:
    Type: AWS::ElastiCache::SubnetGroup
    Properties:
      Description: Subnet group for Redis cache
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2

  RedisCache:
    Type: AWS::ElastiCache::CacheCluster
    Properties:
      CacheNodeType: cache.t2.micro
      Engine: redis
      NumCacheNodes: 1
      VpcSecurityGroupIds:
        - !Ref RedisSecurityGroup
      CacheSubnetGroupName: !Ref CacheSubnetGroup
      Tags:
        - Key: Name
          Value: classroom-monitoring-redis

  # Application Load Balancer
  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: classroom-monitoring-alb
      Scheme: internet-facing
      Type: application
      SecurityGroups:
        - !Ref ALBSecurityGroup
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      Tags:
        - Key: Name
          Value: classroom-monitoring-alb

  # S3 Bucket for assets
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'classroom-monitoring-assets-${AWS::AccountId}'
      PublicAccessBlockConfiguration:
        BlockPublicAcls: false
        BlockPublicPolicy: false
        IgnorePublicAcls: false
        RestrictPublicBuckets: false
      WebsiteConfiguration:
        IndexDocument: index.html
      Tags:
        - Key: Name
          Value: classroom-monitoring-assets

  # EC2 Instance
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: t2.micro
      KeyName: !Ref KeyName
      SecurityGroupIds:
        - !Ref WebServerSecurityGroup
      SubnetId: !Ref PublicSubnet1
      ImageId: ami-047126e50991d067b
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash
          yum update -y
          yum install -y docker git
          service docker start
          usermod -a -G docker ec2-user
          
          # Install Docker Compose
          curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
          chmod +x /usr/local/bin/docker-compose
          
          # Install Node.js and Yarn
          curl -sL https://rpm.nodesource.com/setup_18.x | bash -
          yum install -y nodejs
          npm install -g yarn
          
      Tags:
        - Key: Name
          Value: classroom-monitoring-web

Outputs:
  WebServerPublicIP:
    Description: Public IP of the web server
    Value: !GetAtt EC2Instance.PublicIp
    
  DatabaseEndpoint:
    Description: RDS database endpoint
    Value: !GetAtt RDSInstance.Endpoint.Address
    
  RedisEndpoint:
    Description: Redis cache endpoint
    Value: !GetAtt RedisCache.RedisEndpoint.Address
    
  LoadBalancerDNS:
    Description: Load Balancer DNS name
    Value: !GetAtt ApplicationLoadBalancer.DNSName
    
  S3BucketName:
    Description: S3 bucket for assets
    Value: !Ref S3Bucket
```

### 🔧 Step 2: Deploy the Infrastructure

1. **Save the CloudFormation template** as `aws-infrastructure.yml`

2. **Deploy using AWS CLI:**
```bash
aws cloudformation create-stack \
  --stack-name classroom-monitoring \
  --template-body file://aws-infrastructure.yml \
  --parameters ParameterKey=KeyName,ParameterValue=your-key-pair \
               ParameterKey=DBUsername,ParameterValue=postgres \
               ParameterKey=DBPassword,ParameterValue=YourSecurePassword123 \
  --capabilities CAPABILITY_IAM
```

3. **Or deploy via AWS Console:**
   - Go to CloudFormation in AWS Console
   - Create Stack → Upload template file
   - Fill in parameters

### 🚀 Step 3: Configure Your Rails Application

#### Update Production Configuration
```ruby
# config/environments/production.rb

# Update database configuration
config.active_storage.service = :amazon

# Add load balancer health check
config.force_ssl = false  # ALB handles SSL termination
```

#### Update Database Configuration
```yaml
# config/database.yml
production:
  adapter: postgresql
  encoding: unicode
  database: classroom_access_production
  username: <%= ENV['DATABASE_USER'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
  host: <%= ENV['DATABASE_HOST'] %>
  port: 5432
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

#### Create Deployment Script
```bash
#!/bin/bash
# deploy.sh

# Set environment variables
export DATABASE_URL="postgresql://postgres:YourPassword@your-rds-endpoint:5432/classroom_access_production"
export REDIS_URL="redis://your-redis-endpoint:6379/0"
export RAILS_ENV=production
export SECRET_KEY_BASE=$(rails secret)

# Deploy application
git pull origin main
bundle install --without development test
yarn install
rails assets:precompile
rails db:migrate
sudo systemctl restart rails-app
```

### 📦 Step 4: Application Deployment

#### Create Systemd Service
```ini
# /etc/systemd/system/rails-app.service
[Unit]
Description=Rails Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/rfid_classroom_access_monitoring
ExecStart=/home/ec2-user/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always
Environment=RAILS_ENV=production
Environment=DATABASE_URL=your-database-url
Environment=REDIS_URL=your-redis-url

[Install]
WantedBy=multi-user.target
```

### 🔒 Step 5: SSL Setup with Let's Encrypt

```bash
# Install Certbot
sudo yum install -y python3-pip
sudo pip3 install certbot

# Get SSL certificate
sudo certbot certonly --standalone -d your-domain.com

# Configure ALB with SSL certificate
```

### 📊 Step 6: Monitoring & Maintenance

#### CloudWatch Alarms
- CPU utilization > 80%
- Database connections > 80%
- Application errors

#### Backup Strategy
- RDS automated backups (7 days)
- S3 versioning for assets
- EC2 AMI snapshots weekly

### 💡 Cost Optimization Tips

1. **Use Spot Instances** (after free tier expires)
2. **S3 Lifecycle policies** for old assets
3. **CloudFront CDN** for better performance
4. **Reserved Instances** for predictable workloads

### ⚠️ Important Notes

- **Free tier expires after 12 months**
- **Monitor usage** to avoid charges
- **Set up billing alerts** at $1, $5, $10
- **Consider migration** to other platforms before expiry

### 🎯 Next Steps After Free Tier

When your free tier expires in 12 months:

1. **Migrate to Oracle Cloud Always Free** ($0 forever)
2. **Use AWS Spot Instances** (~70% cheaper)
3. **Move to smaller cloud providers** (DigitalOcean, Linode)
4. **Optimize resources** (smaller instances, managed services)

---

**Total Setup Time:** ~2-3 hours
**Ongoing Maintenance:** ~30 min/month
**Cost Year 1:** ~$6 (Route 53 only)
**Cost Year 2+:** ~$35-50/month 