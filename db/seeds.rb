# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Admin reset password
# User.find(1).update(password: "123456")

puts "🌱 Starting database seeding..."

begin
  # SUPER ADMINS
super_admin_1 = User.find_or_create_by(email: "super_admin@tup.edu.ph") do |user|
  user.firstname = "Super"
  user.lastname = "Admin"
  user.academic_college = 0
  user.role = 2
  user.password = "123456"
  user.api_token = "6dbe948bb56f1d6827fbbd8321c7ad14"
  user.status = 1
end
puts "✅ Super Admin 1: #{super_admin_1.email}"

# Additional Super Admin
super_admin_2 = User.find_or_create_by(email: "zhaineiarasunako0123@gmail.com") do |user|
  user.firstname = "Programmer"
  user.lastname = "ZeroTwo"
  user.academic_college = 0
  user.role = 2
  user.password = "123456"
  user.api_token = "6dbe948bb56f1d6827fbbd8321c7ad14"
  user.status = 1
end
puts "✅ Super Admin 2: #{super_admin_2.email}"

# USERS
users_data = [
  { firstname: "Aimee", middlename: "Guardaya", lastname: "Acoba", academic_college: 5, role: 0, email: "aimee_acoba@tup.edu.ph" },
  { firstname: "Marc Ardie", lastname: "Ardiente", academic_college: 1, role: 1, email: "marcardie_ardiente@tup.edu.ph" },
  { firstname: "Minabelle", lastname: "Villafurte", academic_college: 1, role: 1, email: "minabelle_villafuerte@tup.edu.ph" },
  { firstname: "Jonel", lastname: "Macalisang", academic_college: 1, role: 1, email: "jonel_macalisang@tup.edu.ph" },
  { firstname: "Hilda", lastname: "Robino", academic_college: 1, role: 1, email: "hilda_robino@tup.edu.ph" },
  { firstname: "Ian", lastname: "De Los Trinos", academic_college: 1, role: 1, email: "ian_delostrinos@tup.edu.ph" },
  { firstname: "Dennis", lastname: "Tabucol", academic_college: 1, role: 1, email: "dennis_tabucol@tup.edu.ph" },
  { firstname: "Precious Daniella", lastname: "Mapa", academic_college: 1, role: 0, email: "preciousdaniellamapa@gmail.com" }
]

users_data.each do |user_data|
  user = User.find_or_create_by(email: user_data[:email]) do |u|
    u.firstname = user_data[:firstname]
    u.middlename = user_data[:middlename] if user_data[:middlename]
    u.lastname = user_data[:lastname]
    u.academic_college = user_data[:academic_college]
    u.role = user_data[:role]
    u.password = "123456"
    u.api_token = "6dbe948bb56f1d6827fbbd8321c7ad14"
    u.status = 1
  end
  puts "✅ User: #{user.email}"
end

# CARDS
User.all.each_with_index do |user, index|
  next if Card.exists?(user_id: user.id)
  
  card = Card.create!(
    uid: "CARD#{(index + 1).to_s.rjust(3, '0')}",
    status: 1,
    user_id: user.id,
    uid_type: 0,
    remarks: nil
  )
  puts "✅ Card: #{card.uid} for #{user.email}"
end

# ROOMS
rooms_data = [
  { room_number: 408, room_status: 1 },
  { room_number: 409, room_status: 1 },
  { room_number: 410, room_status: 0 },
  { room_number: 411, room_status: 0 },
  { room_number: 412, room_status: 0 }
]

rooms_data.each do |room_data|
  room = Room.find_or_create_by(room_number: room_data[:room_number]) do |r|
    r.room_status = room_data[:room_status]
    r.remarks = nil
  end
  puts "✅ Room: #{room.room_number}"
end

# SCHEDULES
marc_user = User.find_by(email: "marcardie_ardiente@tup.edu.ph")
minabelle_user = User.find_by(email: "minabelle_villafuerte@tup.edu.ph")
jonel_user = User.find_by(email: "jonel_macalisang@tup.edu.ph")
room_408 = Room.find_by(room_number: 408)
room_409 = Room.find_by(room_number: 409)
room_410 = Room.find_by(room_number: 410)

if marc_user && room_408
  marc_schedules = [
    { description: 0, subject: "CPET2L-M", day: 2, start_time: "07:00", end_time: "10:00", year_level: 1 },
    { description: 0, subject: "CPET9L-M", day: 5, start_time: "10:30", end_time: "13:30", year_level: 2 },
    { description: 1, subject: "ELECTIVE2-M", day: 3, start_time: "09:00", end_time: "12:00", year_level: 4 }
  ]

  marc_schedules.each do |schedule_data|
    begin
      schedule = Schedule.find_or_create_by(
        user_id: marc_user.id,
        subject: schedule_data[:subject],
        day: schedule_data[:day],
        start_time: schedule_data[:start_time],
        room_id: room_408.id
      ) do |s|
        s.description = schedule_data[:description]
        s.end_time = schedule_data[:end_time]
        s.school_year = "2024-2025"
        s.semester = 1
        s.year_level = schedule_data[:year_level]
        s.remarks = nil
      end
      puts "✅ Schedule created/found: #{schedule_data[:subject]} for #{marc_user.email}"
    rescue ActiveRecord::RecordInvalid => e
      puts "⚠️  Skipped overlapping schedule: #{schedule_data[:subject]} for #{marc_user.email} - #{e.message}"
    end
  end
end

if minabelle_user && room_409
  # MINABELLE VILLAFUERTE schedules
  minabelle_schedules = [
    { description: 0, subject: "CPET2L-M", day: 2, start_time: "07:00", end_time: "10:00", year_level: 1 },
    { description: 0, subject: "CPET2L-M", day: 2, start_time: "12:30", end_time: "15:30", year_level: 1 },
    { description: 0, subject: "CPET2L-M", day: 3, start_time: "07:00", end_time: "10:00", year_level: 1 },
    { description: 0, subject: "CPET2L-M", day: 3, start_time: "12:30", end_time: "15:30", year_level: 1 },
    { description: 0, subject: "CPTR1L-M", day: 5, start_time: "12:30", end_time: "15:30", year_level: 1 },
    { description: 0, subject: "CPTR1L-M", day: 1, start_time: "07:00", end_time: "10:00", year_level: 1 },
    { description: 1, subject: "CPET10-M", day: 1, start_time: "12:30", end_time: "15:30", year_level: 2 },
    { description: 1, subject: "CPET10-M", day: 4, start_time: "12:30", end_time: "15:30", year_level: 2 },
    { description: 1, subject: "CPET8-M", day: 2, start_time: "10:30", end_time: "12:00", year_level: 2 },
    { description: 1, subject: "CPET8-M", day: 4, start_time: "10:30", end_time: "12:00", year_level: 2 },
    { description: 1, subject: "BET3-M", day: 2, start_time: "07:00", end_time: "10:00", year_level: 3 },
    { description: 1, subject: "BET3-M", day: 3, start_time: "10:30", end_time: "12:00", year_level: 3 },
    { description: 1, subject: "BET3-M", day: 5, start_time: "10:30", end_time: "12:00", year_level: 3 },
    { description: 1, subject: "ELECTIVE1-M", day: 4, start_time: "07:00", end_time: "10:00", year_level: 3 },
    { description: 1, subject: "ELECTIVE1-M", day: 5, start_time: "07:00", end_time: "10:00", year_level: 3 }
  ]

  minabelle_schedules.each do |schedule_data|
    begin
      schedule = Schedule.find_or_create_by(
        user_id: minabelle_user.id,
        subject: schedule_data[:subject],
        day: schedule_data[:day],
        start_time: schedule_data[:start_time],
        room_id: room_409.id
      ) do |s|
        s.description = schedule_data[:description]
        s.end_time = schedule_data[:end_time]
        s.school_year = "2024-2025"
        s.semester = 1
        s.year_level = schedule_data[:year_level]
        s.remarks = nil
      end
      puts "✅ Schedule created/found: #{schedule.subject} for #{minabelle_user.email}"
    rescue ActiveRecord::RecordInvalid => e
      puts "⚠️  Skipped overlapping schedule: #{schedule_data[:subject]} for #{minabelle_user.email} - #{e.message}"
    end
  end
end

if jonel_user && room_410
  # JONEL MACALISANG schedules
  jonel_schedules = [
    { description: 1, subject: "CAD-M", day: 1, start_time: "10:30", end_time: "13:30", year_level: 1 },
    { description: 1, subject: "CAD-M", day: 3, start_time: "10:30", end_time: "13:30", year_level: 1 },
    { description: 1, subject: "CpET14-M", day: 5, start_time: "12:30", end_time: "15:30", year_level: 3 },
    { description: 1, subject: "CpET14-M", day: 2, start_time: "10:30", end_time: "12:00", year_level: 3 },
    { description: 1, subject: "CpET14-M", day: 4, start_time: "10:30", end_time: "12:00", year_level: 3 },
    { description: 0, subject: "CpET14L-M", day: 2, start_time: "12:30", end_time: "15:30", year_level: 3 },
    { description: 0, subject: "CpET14L-M", day: 4, start_time: "12:30", end_time: "15:30", year_level: 3 },
    { description: 0, subject: "CpET14L-M", day: 2, start_time: "16:00", end_time: "19:00", year_level: 3 },
    { description: 0, subject: "CpET14L-M", day: 4, start_time: "16:00", end_time: "19:00", year_level: 3 },
    { description: 0, subject: "CpET14L-M", day: 1, start_time: "16:00", end_time: "19:00", year_level: 3 },
    { description: 0, subject: "CpET14L-M", day: 3, start_time: "16:00", end_time: "19:00", year_level: 3 }
  ]

  jonel_schedules.each do |schedule_data|
    begin
      schedule = Schedule.find_or_create_by(
        user_id: jonel_user.id,
        subject: schedule_data[:subject],
        day: schedule_data[:day],
        start_time: schedule_data[:start_time],
        room_id: room_410.id
      ) do |s|
        s.description = schedule_data[:description]
        s.end_time = schedule_data[:end_time]
        s.school_year = "2024-2025"
        s.semester = 1
        s.year_level = schedule_data[:year_level]
        s.remarks = nil
      end
      puts "✅ Schedule created/found: #{schedule.subject} for #{jonel_user.email}"
    rescue ActiveRecord::RecordInvalid => e
      puts "⚠️  Skipped overlapping schedule: #{schedule_data[:subject]} for #{jonel_user.email} - #{e.message}"
    end
  end
end

  puts "🎉 Database seeding completed!"
  puts "🔐 Super Admin Logins:"
  puts "   📧 super_admin@tup.edu.ph / 123456"
  puts "   📧 zhaineiarasunako0123@gmail.com / 123456"

rescue => e
  puts "❌ Seeding failed: #{e.message}"
  puts e.backtrace.first(5)
  raise e
end
