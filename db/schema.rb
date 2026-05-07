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

ActiveRecord::Schema[8.1].define(version: 2026_05_06_131150) do
  create_table "a1_packages", force: :cascade do |t|
    t.string "addressee_name"
    t.string "addressee_site"
    t.datetime "created_at", null: false
    t.integer "telephone_number"
    t.datetime "updated_at", null: false
  end

  create_table "a2_packages", force: :cascade do |t|
    t.string "addressee_name"
    t.string "addressee_site"
    t.datetime "created_at", null: false
    t.integer "telephone_number"
    t.datetime "updated_at", null: false
  end

  create_table "a3_packages", force: :cascade do |t|
    t.string "addressee_name"
    t.string "addressee_site"
    t.datetime "created_at", null: false
    t.integer "telephone_number"
    t.datetime "updated_at", null: false
  end

  create_table "notifications", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "notification_type", null: false
    t.integer "package_id"
    t.datetime "read_at"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["package_id"], name: "index_notifications_on_package_id"
    t.index ["status"], name: "index_notifications_on_status"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "ocr_records", force: :cascade do |t|
    t.float "confidence_score", default: 0.0
    t.string "courier_company"
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "image_content_type"
    t.string "image_file_name"
    t.integer "image_file_size"
    t.string "image_url", null: false
    t.float "processing_time"
    t.text "raw_text"
    t.string "recipient_address"
    t.string "recipient_city"
    t.string "recipient_district"
    t.string "recipient_name"
    t.string "recipient_phone"
    t.string "recipient_province"
    t.string "sender_name"
    t.string "sender_phone"
    t.integer "status", default: 0
    t.string "tracking_number"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["created_at"], name: "index_ocr_records_on_created_at"
    t.index ["status"], name: "index_ocr_records_on_status"
    t.index ["tracking_number"], name: "index_ocr_records_on_tracking_number"
    t.index ["user_id"], name: "index_ocr_records_on_user_id"
  end

  create_table "operation_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.json "details"
    t.string "ip_address"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id"
    t.index ["action"], name: "index_operation_logs_on_action"
    t.index ["created_at"], name: "index_operation_logs_on_created_at"
    t.index ["resource_type"], name: "index_operation_logs_on_resource_type"
    t.index ["user_id"], name: "index_operation_logs_on_user_id"
  end

  create_table "package_exceptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description", null: false
    t.integer "exception_type", null: false
    t.integer "package_id", null: false
    t.integer "reported_by_id", null: false
    t.datetime "resolved_at"
    t.integer "resolved_by_id"
    t.text "solution"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_package_exceptions_on_deleted_at"
    t.index ["exception_type"], name: "index_package_exceptions_on_exception_type"
    t.index ["package_id"], name: "index_package_exceptions_on_package_id"
    t.index ["reported_by_id"], name: "index_package_exceptions_on_reported_by_id"
    t.index ["resolved_by_id"], name: "index_package_exceptions_on_resolved_by_id"
    t.index ["status"], name: "index_package_exceptions_on_status"
  end

  create_table "packages", force: :cascade do |t|
    t.string "courier_company"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.integer "package_type", default: 0
    t.datetime "picked_up_at"
    t.integer "picked_up_by_id"
    t.string "pickup_code", null: false
    t.string "recipient_address"
    t.string "recipient_name", null: false
    t.string "recipient_phone", null: false
    t.text "remark"
    t.integer "status", default: 0, null: false
    t.string "storage_location"
    t.datetime "stored_at"
    t.integer "stored_by_id"
    t.string "tracking_number", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.decimal "weight", precision: 8, scale: 2
    t.index ["deleted_at"], name: "index_packages_on_deleted_at"
    t.index ["picked_up_by_id"], name: "index_packages_on_picked_up_by_id"
    t.index ["pickup_code"], name: "index_packages_on_pickup_code"
    t.index ["recipient_phone"], name: "index_packages_on_recipient_phone"
    t.index ["status"], name: "index_packages_on_status"
    t.index ["stored_at"], name: "index_packages_on_stored_at"
    t.index ["stored_by_id"], name: "index_packages_on_stored_by_id"
    t.index ["tracking_number"], name: "index_packages_on_tracking_number", unique: true
    t.index ["user_id"], name: "index_packages_on_user_id"
  end

  create_table "system_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "key", null: false
    t.integer "setting_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["key"], name: "index_system_settings_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "employee_number"
    t.datetime "last_login_at"
    t.string "last_login_ip"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "phone", null: false
    t.integer "role", default: 0, null: false
    t.integer "status", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["employee_number"], name: "index_users_on_employee_number", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
  end

  add_foreign_key "notifications", "packages"
  add_foreign_key "notifications", "users"
  add_foreign_key "ocr_records", "users"
  add_foreign_key "operation_logs", "users"
  add_foreign_key "package_exceptions", "packages"
  add_foreign_key "package_exceptions", "users", column: "reported_by_id"
  add_foreign_key "package_exceptions", "users", column: "resolved_by_id"
  add_foreign_key "packages", "users"
  add_foreign_key "packages", "users", column: "picked_up_by_id"
  add_foreign_key "packages", "users", column: "stored_by_id"
end
