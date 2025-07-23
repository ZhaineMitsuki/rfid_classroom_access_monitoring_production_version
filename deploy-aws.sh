#!/bin/bash
# AWS EC2 Deployment Script for RFID Classroom Access Monitoring
# Run this script on your EC2 instance after infrastructure is deployed

set -e

echo "🚀 Starting AWS deployment of RFID Classroom Access Monitoring..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as ec2-user
if [ "$USER" != "ec2-user" ]; then
    print_error "This script should be run as ec2-user"
    exit 1
fi

# Environment variables (replace with your actual values)
export RAILS_ENV=production
export DATABASE_URL="${DATABASE_URL:-postgresql://postgres:password@your-rds-endpoint:5432/classroom_access_production}"
export REDIS_URL="${REDIS_URL:-redis://your-redis-endpoint:6379/0}"
export SECRET_KEY_BASE="${SECRET_KEY_BASE:-$(openssl rand -hex 64)}"
export RAILS_MASTER_KEY="${RAILS_MASTER_KEY:-your-master-key}"

print_status "Environment configured"

# Update system
print_status "Updating system packages..."
sudo yum update -y

# Install Ruby dependencies
print_status "Installing Ruby dependencies..."
sudo yum groupinstall -y "Development Tools"
sudo yum install -y git curl openssl-devel readline-devel zlib-devel libffi-devel

# Install rbenv
if [ ! -d "$HOME/.rbenv" ]; then
    print_status "Installing rbenv..."
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    
    # Install ruby-build
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
else
    print_status "rbenv already installed"
fi

# Source bashrc to get rbenv
source ~/.bashrc || true
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)" || true

# Install Ruby 3.3.7
if ! rbenv versions | grep -q "3.3.7"; then
    print_status "Installing Ruby 3.3.7..."
    rbenv install 3.3.7
    rbenv global 3.3.7
else
    print_status "Ruby 3.3.7 already installed"
fi

# Install Bundler
print_status "Installing Bundler..."
gem install bundler --no-document

# Install Node.js and Yarn (if not already installed)
if ! command -v node &> /dev/null; then
    print_status "Installing Node.js..."
    curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
fi

if ! command -v yarn &> /dev/null; then
    print_status "Installing Yarn..."
    sudo npm install -g yarn
fi

# Clone or update application repository
APP_DIR="$HOME/rfid_classroom_access_monitoring"
if [ ! -d "$APP_DIR" ]; then
    print_status "Cloning application repository..."
    git clone https://github.com/your-username/rfid_classroom_access_monitoring_production_version.git "$APP_DIR"
else
    print_status "Updating application repository..."
    cd "$APP_DIR"
    git pull origin main
fi

cd "$APP_DIR"

# Install dependencies
print_status "Installing Ruby gems..."
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install

print_status "Installing Node.js packages..."
yarn install

# Create environment file
print_status "Creating environment configuration..."
cat > .env.production << EOF
RAILS_ENV=production
DATABASE_URL=$DATABASE_URL
REDIS_URL=$REDIS_URL
SECRET_KEY_BASE=$SECRET_KEY_BASE
RAILS_MASTER_KEY=$RAILS_MASTER_KEY
RAILS_SERVE_STATIC_FILES=true
AWS_REGION=${AWS_REGION:-us-east-1}
S3_BUCKET_NAME=${S3_BUCKET_NAME:-classroom-monitoring-assets}
EOF

# Precompile assets
print_status "Precompiling assets..."
bundle exec rails assets:precompile

# Database setup
print_status "Setting up database..."
bundle exec rails db:create db:migrate

print_status "Seeding database..."
bundle exec rails db:seed

# Create systemd service
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/classroom-monitoring.service > /dev/null << EOF
[Unit]
Description=RFID Classroom Access Monitoring Rails Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=$APP_DIR
Environment=RAILS_ENV=production
EnvironmentFile=$APP_DIR/.env.production
ExecStart=$HOME/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=1
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=classroom-monitoring

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
print_status "Starting application service..."
sudo systemctl daemon-reload
sudo systemctl enable classroom-monitoring
sudo systemctl start classroom-monitoring

# Install and configure Nginx
print_status "Installing and configuring Nginx..."
sudo yum install -y nginx

# Create Nginx configuration
sudo tee /etc/nginx/conf.d/classroom-monitoring.conf > /dev/null << EOF
upstream puma {
    server unix://$APP_DIR/tmp/sockets/puma.sock;
}

server {
    listen 80;
    server_name _;

    root $APP_DIR/public;

    location / {
        proxy_pass http://puma;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control public;
        add_header Last-Modified "";
        add_header ETag "";
        break;
    }
}
EOF

# Update Puma configuration for socket
print_status "Configuring Puma for socket connection..."
mkdir -p "$APP_DIR/tmp/sockets"

cat >> "$APP_DIR/config/puma.rb" << EOF

# Bind to socket for Nginx
bind "unix://$APP_DIR/tmp/sockets/puma.sock"
EOF

# Start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Restart application
sudo systemctl restart classroom-monitoring

# Setup log rotation
print_status "Setting up log rotation..."
sudo tee /etc/logrotate.d/classroom-monitoring > /dev/null << EOF
$APP_DIR/log/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 ec2-user ec2-user
    postrotate
        sudo systemctl reload classroom-monitoring
    endscript
}
EOF

# Create backup script
print_status "Creating backup script..."
tee "$HOME/backup.sh" > /dev/null << EOF
#!/bin/bash
# Database backup script
BACKUP_DIR="$HOME/backups"
DATE=\$(date +%Y%m%d_%H%M%S)

mkdir -p \$BACKUP_DIR

# Database backup
PGPASSWORD=\$(echo "\$DATABASE_URL" | sed 's/.*:\([^@]*\)@.*/\1/') \
pg_dump "\$DATABASE_URL" > "\$BACKUP_DIR/db_backup_\$DATE.sql"

# Keep only last 7 days of backups
find \$BACKUP_DIR -name "db_backup_*.sql" -mtime +7 -delete

echo "Backup completed: \$BACKUP_DIR/db_backup_\$DATE.sql"
EOF

chmod +x "$HOME/backup.sh"

# Add backup to crontab
(crontab -l 2>/dev/null; echo "0 2 * * * $HOME/backup.sh") | crontab -

# Print completion message
print_status "🎉 Deployment completed successfully!"
echo ""
echo "📋 Next Steps:"
echo "1. Update your ALB target group to point to this EC2 instance"
echo "2. Configure your domain DNS to point to the ALB"
echo "3. Set up SSL certificate in ALB"
echo "4. Update environment variables in .env.production as needed"
echo ""
echo "🔗 Service Commands:"
echo "  • Check status: sudo systemctl status classroom-monitoring"
echo "  • View logs: sudo journalctl -u classroom-monitoring -f"
echo "  • Restart app: sudo systemctl restart classroom-monitoring"
echo "  • Check Nginx: sudo systemctl status nginx"
echo ""
echo "🌐 Your application should be accessible at:"
echo "  • Local: http://localhost"
echo "  • ALB: http://your-alb-dns-name"
echo ""
print_warning "Remember to update your environment variables with actual AWS resource endpoints!" 