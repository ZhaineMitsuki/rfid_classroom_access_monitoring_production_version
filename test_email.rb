#!/usr/bin/env ruby

# Test script for email delivery
# Run this with: ruby test_email.rb

puts "🔍 Testing Email Configuration..."
puts "================================"

# Check if we're in Rails environment
begin
  require_relative 'config/environment'
  puts "✅ Rails environment loaded"
rescue => e
  puts "❌ Failed to load Rails environment: #{e.message}"
  exit 1
end

# Check current email delivery settings
puts "\n📧 Current Email Settings:"
puts "Delivery method: #{ActionMailer::Base.delivery_method}"
puts "Default from: #{ApplicationMailer.default[:from]}"
puts "Raise delivery errors: #{ActionMailer::Base.raise_delivery_errors}"
puts "Perform deliveries: #{ActionMailer::Base.perform_deliveries}"

# Check SMTP settings if using SMTP
if ActionMailer::Base.delivery_method == :smtp
  smtp_settings = ActionMailer::Base.smtp_settings
  puts "\n🔐 SMTP Settings:"
  puts "Address: #{smtp_settings[:address]}"
  puts "Port: #{smtp_settings[:port]}"
  puts "Domain: #{smtp_settings[:domain]}"
  puts "Username: #{smtp_settings[:user_name] ? '***SET***' : 'NOT SET'}"
  puts "Password: #{smtp_settings[:password] ? '***SET***' : 'NOT SET'}"
end

# Test sending a password reset email
print "\n🧪 Testing password reset email... "

begin
  # Find a user to test with
  user = User.first
  if user.nil?
    puts "❌ No users found in database"
    exit 1
  end
  
  puts "Found user: #{user.email}"
  
  # Generate reset password token and send email
  user.send_reset_password_instructions
  
  puts "✅ Password reset email sent successfully!"
  puts "📬 Check the email for: #{user.email}"
  
  if ActionMailer::Base.delivery_method == :file
    puts "📁 Email saved to: #{Rails.root.join('tmp/mail')}"
    puts "💡 To test real email delivery, set up SMTP credentials"
  end
  
rescue => e
  puts "❌ Failed to send email: #{e.message}"
  puts "Error details: #{e.backtrace.first(3).join('\n')}"
end

puts "\n📋 Next Steps:"
puts "1. If using Gmail, set up App Password (not regular password)"
puts "2. Set environment variables: SMTP_USERNAME and SMTP_PASSWORD"
puts "3. Restart your Rails server"
puts "4. Test the 'Forgot Password' feature" 