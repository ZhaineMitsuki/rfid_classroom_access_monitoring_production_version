namespace :users do
  desc "Fix user accounts in production"
  task fix_accounts: :environment do
    puts "🔧 Starting user account fixes..."

    # Fix super admin account
    puts "\n1️⃣ Fixing super admin: zhaineiarasunako0123@gmail.com"
    super_admin = User.find_or_create_by(email: "zhaineiarasunako0123@gmail.com") do |user|
      user.firstname = "Programmer"
      user.lastname = "ZeroTwo"
      user.academic_college = 0
      user.role = 2  # Super Admin
      user.password = "123456"
      user.status = 1  # Active
      user.api_token = "6dbe948bb56f1d6827fbbd8321c7ad14"
      puts "   ✅ Created new super admin"
    end

    # Update existing super admin if needed
    if super_admin.persisted? && !super_admin.changed?
      super_admin.update!(
        role: 2,
        status: 1,
        password: "123456",
        firstname: "Programmer",
        lastname: "ZeroTwo"
      )
      puts "   ✅ Updated existing super admin"
    end

    puts "   📧 Super Admin: #{super_admin.email} (Role: #{super_admin.role}, Status: #{super_admin.status})"

    # Fix precious user to admin
    puts "\n2️⃣ Updating preciousdaniellamapa@gmail.com to Admin"
    precious_user = User.find_by(email: "preciousdaniellamapa@gmail.com")

    if precious_user
      precious_user.update!(
        role: 1,  # Admin role
        status: 1  # Active
      )
      puts "   ✅ Updated to Admin role"
      puts "   📧 Admin: #{precious_user.email} (Role: #{precious_user.role}, Status: #{precious_user.status})"
    else
      # Create as admin if doesn't exist
      precious_user = User.create!(
        email: "preciousdaniellamapa@gmail.com",
        firstname: "Precious Daniella",
        lastname: "Mapa",
        academic_college: 1,
        role: 1,  # Admin
        password: "123456",
        status: 1,
        api_token: SecureRandom.hex(16)
      )
      puts "   ✅ Created new admin user"
      puts "   📧 New Admin: #{precious_user.email} (Role: #{precious_user.role}, Status: #{precious_user.status})"
    end

    puts "\n📊 Final user summary:"
    puts "=" * 50
    User.where(role: [1, 2]).each do |user|
      role_name = case user.role
                  when 0 then "Professor"
                  when 1 then "Admin"
                  when 2 then "Super Admin"
                  end
      status_name = user.status == 1 ? "Active" : "Inactive"
      puts "#{user.email} | #{role_name} | #{status_name}"
    end

    puts "\n🎉 User account fixes completed!"
    puts "🔐 Login credentials:"
    puts "   Super Admin: zhaineiarasunako0123@gmail.com / 123456"
    puts "   Admin: preciousdaniellamapa@gmail.com / 123456"
  end
end 