#!/usr/bin/env bash
# Production setup script - run this once to initialize your database
# Usage: ./bin/setup-production.sh

set -o errexit

echo "🗄️  Setting up production database..."
bundle exec rake db:create db:migrate

echo "🌱 Seeding database with initial data..."
bundle exec rake db:seed

echo "✅ Production setup complete!"
echo "🔐 Super Admin Login:"
echo "   Email: super_admin@tup.edu.ph"
echo "   Password: 123456"
echo ""
echo "🌐 Your app is ready at: https://classroom-access-monitoring.onrender.com" 