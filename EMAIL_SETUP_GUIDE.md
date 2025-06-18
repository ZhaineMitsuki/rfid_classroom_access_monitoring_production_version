# 📧 Email Setup Guide for Forgot Password Functionality

This guide will help you fix the email delivery issues for the forgot password feature.

## 🔍 Current Issues

1. **Development Environment**: Emails are saved to files instead of being sent
2. **Missing SMTP Credentials**: Gmail SMTP not properly configured
3. **Production Environment**: May not have proper environment variables set

## 🚀 Quick Fix for Development

### Option 1: Use Gmail SMTP (Recommended)

1. **Enable 2-Factor Authentication** on your Gmail account
2. **Generate an App Password**:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Select "Mail" and your device
   - Copy the 16-character password

3. **Set Environment Variables**:
   ```bash
   # For Windows PowerShell
   $env:SMTP_USERNAME = "your-gmail@gmail.com"
   $env:SMTP_PASSWORD = "your-16-char-app-password"
   
   # For Windows Command Prompt
   set SMTP_USERNAME=your-gmail@gmail.com
   set SMTP_PASSWORD=your-16-char-app-password
   
   # For macOS/Linux
   export SMTP_USERNAME="your-gmail@gmail.com"
   export SMTP_PASSWORD="your-16-char-app-password"
   ```

4. **Restart your Rails server**:
   ```bash
   rails server
   ```

### Option 2: Test Mode (View emails without sending)

If you just want to see what emails look like without sending them:

1. **Add to Gemfile** (in development group):
   ```ruby
   gem 'letter_opener_web', group: :development
   ```

2. **Run**:
   ```bash
   bundle install
   ```

3. **Add to routes.rb** (for development):
   ```ruby
   if Rails.env.development?
     mount LetterOpenerWeb::Engine, at: "/letter_opener"
   end
   ```

## 🌐 Production Setup (Render.com)

### Set Environment Variables on Render:

1. Go to your Render dashboard
2. Select your service
3. Go to Environment → Environment Variables
4. Add/Update:
   - `SMTP_USERNAME`: Your Gmail address
   - `SMTP_PASSWORD`: Your Gmail App Password

## 🧪 Testing Email Delivery

Run the test script I created:

```bash
ruby test_email.rb
```

This will:
- Check your current email configuration
- Test sending a password reset email
- Show you exactly what's happening

## 🔧 Manual Testing

1. **Start your Rails console**:
   ```bash
   rails console
   ```

2. **Test email delivery**:
   ```ruby
   # Find a user
   user = User.first
   
   # Send password reset
   user.send_reset_password_instructions
   
   # Check if email was delivered
   ActionMailer::Base.deliveries.last
   ```

## 📝 Environment Variables Setup

### For Development (.env file method):

1. **Create `.env` file** in your project root:
   ```
   SMTP_USERNAME=your-gmail@gmail.com
   SMTP_PASSWORD=your-16-char-app-password
   ```

2. **Add to Gemfile**:
   ```ruby
   gem 'dotenv-rails', groups: [:development, :test]
   ```

3. **Run**:
   ```bash
   bundle install
   ```

4. **Add `.env` to `.gitignore`**:
   ```
   .env
   ```

## 🚨 Common Issues & Solutions

### Issue: "Authentication failed"
- ✅ **Solution**: Use App Password, not regular Gmail password
- ✅ **Solution**: Enable 2-Factor Authentication first

### Issue: "Connection timed out"
- ✅ **Solution**: Check firewall settings
- ✅ **Solution**: Try port 465 with SSL instead of 587 with TLS

### Issue: "Invalid credentials"
- ✅ **Solution**: Double-check username and app password
- ✅ **Solution**: Make sure environment variables are set correctly

### Issue: "Emails not reaching inbox"
- ✅ **Solution**: Check spam folder
- ✅ **Solution**: Add sender to whitelist
- ✅ **Solution**: Use a proper domain email instead of gmail

## 🔍 Debug Commands

```bash
# Check current delivery method
rails runner "puts ActionMailer::Base.delivery_method"

# Check SMTP settings
rails runner "puts ActionMailer::Base.smtp_settings"

# Send test email
rails runner "User.first.send_reset_password_instructions"

# Check delivered emails (in test mode)
rails runner "puts ActionMailer::Base.deliveries.count"
```

## 📞 Alternative Email Services

If Gmail doesn't work, consider:

1. **SendGrid** (Free tier available)
2. **Mailgun** (Free tier available)
3. **Amazon SES** (Pay per use)
4. **Postmark** (Developer-friendly)

## 🎯 Final Steps

1. Set up Gmail App Password
2. Set environment variables
3. Restart Rails server
4. Run the test script
5. Test the forgot password feature
6. Check your Gmail inbox

After following this guide, your forgot password emails should be delivered successfully! 🎉 