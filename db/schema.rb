# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2025_06_17_120700) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cards", force: :cascade do |t|
    t.string "uid"
    t.integer "status", default: 0
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "uid_type", default: 0
    t.integer "remarks"
    t.datetime "deleted_at"
    t.string "original_uid"
    t.index ["user_id"], name: "index_cards_on_user_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.integer "room_number"
    t.integer "room_status", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "remarks"
    t.datetime "deleted_at"
    t.integer "original_room_number"
  end

  create_table "schedules", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "description"
    t.string "subject"
    t.integer "day"
    t.time "start_time"
    t.time "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "school_year"
    t.integer "room_id"
    t.integer "semester", null: false
    t.integer "year_level"
    t.integer "remarks"
    t.datetime "deleted_at"
    t.string "original_school_year"
    t.index ["user_id"], name: "index_schedules_on_user_id"
  end

  create_table "time_tracks", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "time_in"
    t.string "time_out"
    t.bigint "room_id"
    t.integer "card_id"
    t.integer "remarks"
    t.datetime "deleted_at"
    t.index ["card_id"], name: "index_time_tracks_on_card_id"
    t.index ["room_id"], name: "index_time_tracks_on_room_id"
    t.index ["user_id"], name: "index_time_tracks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "firstname"
    t.string "middlename"
    t.string "lastname"
    t.integer "academic_college"
    t.integer "role", default: 1
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "api_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.integer "remarks"
    t.datetime "deleted_at"
    t.string "original_email"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
