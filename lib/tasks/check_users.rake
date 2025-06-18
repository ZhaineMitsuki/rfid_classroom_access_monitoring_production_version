namespace :users do
  desc "Check current users in database"
  task check: :environment do
    puts "👥 Current Users in Database:"
    puts "=" * 60

    if User.count == 0
      puts "❌ No users found in database!"
      return
    end

    User.all.order(:role, :email).each do |user|
      role_name = case user.role
                  when 0 then "Professor"
                  when 1 then "Admin"
                  when 2 then "Super Admin"
                  else "Unknown"
                  end
      
      status_name = user.status == 1 ? "✅ Active" : "❌ Inactive"
      
      puts "📧 #{user.email}"
      puts "   👤 #{user.firstname} #{user.lastname}"
      puts "   🎭 Role: #{role_name} (#{user.role})"
      puts "   📊 Status: #{status_name}"
      puts "   🏢 College: #{user.academic_college}"
      puts "   🆔 ID: #{user.id}"
      puts ""
    end

    puts "📈 Summary:"
    puts "   Total Users: #{User.count}"
    puts "   Super Admins: #{User.where(role: 2).count}"
    puts "   Admins: #{User.where(role: 1).count}"
    puts "   Professors: #{User.where(role: 0).count}"
    puts "   Active Users: #{User.where(status: 1).count}"
    puts "   Inactive Users: #{User.where(status: 0).count}"
  end
end 