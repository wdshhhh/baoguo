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

ActiveRecord::Schema[8.1].define(version: 2026_05_11_000002) do
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

  create_table "batch_operation_logs", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "current_count", default: 0
    t.integer "fail_count", default: 0
    t.text "fail_details"
    t.string "operation_id", null: false
    t.integer "operation_type", null: false
    t.integer "status", default: 0, null: false
    t.integer "success_count", default: 0
    t.integer "total_count", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["operation_id"], name: "index_batch_operation_logs_on_operation_id", unique: true
    t.index ["operation_type"], name: "index_batch_operation_logs_on_operation_type"
    t.index ["status"], name: "index_batch_operation_logs_on_status"
    t.index ["user_id"], name: "index_batch_operation_logs_on_user_id"
  end

  create_table "courier_companies", force: :cascade do |t|
    t.string "code", limit: 20, null: false
    t.string "contact_phone", limit: 20
    t.datetime "created_at", null: false
    t.integer "created_by"
    t.text "description"
    t.string "logo_url", limit: 255
    t.string "name", limit: 50, null: false
    t.integer "status", default: 1, null: false
    t.datetime "updated_at", null: false
    t.integer "updated_by"
    t.string "website", limit: 255
    t.index ["code"], name: "index_courier_companies_on_code", unique: true
    t.index ["name"], name: "index_courier_companies_on_name", unique: true
    t.index ["status"], name: "index_courier_companies_on_status"
  end

  create_table "exception_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "handle_method", null: false
    t.integer "handled_by_id", null: false
    t.integer "package_exception_id", null: false
    t.text "result", null: false
    t.datetime "updated_at", null: false
    t.index ["handle_method"], name: "index_exception_logs_on_handle_method"
    t.index ["handled_by_id"], name: "index_exception_logs_on_handled_by_id"
    t.index ["package_exception_id"], name: "index_exception_logs_on_package_exception_id"
  end

  create_table "login_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "ip_address"
    t.string "refresh_token"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_login_sessions_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "notification_type", null: false
    t.integer "package_id"
    t.datetime "read_at"
    t.string "recipient_phone"
    t.datetime "send_at"
    t.string "send_status"
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
    t.float "confidence"
    t.float "confidence_score", default: 0.0
    t.string "courier_company"
    t.float "courier_company_confidence", default: 0.0
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "image_content_type"
    t.string "image_file_name"
    t.integer "image_file_size"
    t.string "image_url", null: false
    t.integer "package_id"
    t.text "parsed_data"
    t.float "processing_time"
    t.text "raw_text"
    t.string "recipient_address"
    t.float "recipient_address_confidence", default: 0.0
    t.string "recipient_city"
    t.string "recipient_district"
    t.string "recipient_name"
    t.float "recipient_name_confidence", default: 0.0
    t.string "recipient_phone"
    t.float "recipient_phone_confidence", default: 0.0
    t.string "recipient_province"
    t.string "sender_name"
    t.string "sender_phone"
    t.integer "status", default: 0
    t.string "tracking_number"
    t.float "tracking_number_confidence", default: 0.0
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["created_at"], name: "index_ocr_records_on_created_at"
    t.index ["package_id"], name: "index_ocr_records_on_package_id"
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
    t.datetime "exception_time"
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
    t.integer "lock_version"
    t.datetime "outbound_at"
    t.integer "package_type", default: 0
    t.datetime "picked_up_at"
    t.integer "picked_up_by_id"
    t.string "pickup_code", null: false
    t.string "pickup_phone"
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

  create_table "shelves", force: :cascade do |t|
    t.integer "capacity", default: 50, null: false
    t.datetime "created_at", null: false
    t.integer "created_by"
    t.text "description"
    t.string "location", limit: 100
    t.string "name", limit: 50, null: false
    t.integer "status", default: 1, null: false
    t.datetime "updated_at", null: false
    t.integer "updated_by"
    t.index ["name"], name: "index_shelves_on_name", unique: true
    t.index ["status"], name: "index_shelves_on_status"
  end

  create_table "system_setting_logs", force: :cascade do |t|
    t.integer "changed_by"
    t.datetime "created_at", null: false
    t.string "key"
    t.text "new_value"
    t.text "old_value"
    t.boolean "reset", default: false
    t.datetime "updated_at", null: false
  end

  create_table "system_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "key", null: false
    t.integer "setting_type", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "updated_by"
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

  add_foreign_key "batch_operation_logs", "users"
  add_foreign_key "exception_logs", "package_exceptions"
  add_foreign_key "exception_logs", "users", column: "handled_by_id"
  add_foreign_key "login_sessions", "users"
  add_foreign_key "notifications", "packages"
  add_foreign_key "notifications", "users"
  add_foreign_key "ocr_records", "packages"
  add_foreign_key "ocr_records", "users"
  add_foreign_key "operation_logs", "users"
  add_foreign_key "package_exceptions", "packages"
  add_foreign_key "package_exceptions", "users", column: "reported_by_id"
  add_foreign_key "package_exceptions", "users", column: "resolved_by_id"
  add_foreign_key "packages", "users"
  add_foreign_key "packages", "users", column: "picked_up_by_id"
  add_foreign_key "packages", "users", column: "stored_by_id"
end
