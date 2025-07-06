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

ActiveRecord::Schema[8.0].define(version: 2025_07_02_084944) do
  create_table "courses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.bigint "term_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "content"
    t.decimal "price", precision: 10
    t.index ["term_id"], name: "index_courses_on_term_id"
  end

  create_table "enrollments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "purchase_id", null: false
    t.string "enrollable_type", null: false
    t.bigint "enrollable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enrollable_type", "enrollable_id"], name: "index_enrollments_on_enrollable"
    t.index ["enrollable_type", "enrollable_id"], name: "index_enrollments_on_enrollable_type_and_enrollable_id"
    t.index ["purchase_id"], name: "index_enrollments_on_purchase_id"
    t.index ["student_id", "enrollable_id", "enrollable_type"], name: "idx_enrollments_access_check"
    t.index ["student_id"], name: "index_enrollments_on_student_id"
  end

  create_table "licenses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "code"
    t.integer "status"
    t.datetime "redeemed_at"
    t.bigint "school_id", null: false
    t.bigint "term_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_licenses_on_code", unique: true
    t.index ["school_id", "status"], name: "index_licenses_on_school_id_and_status"
    t.index ["school_id"], name: "index_licenses_on_school_id"
    t.index ["term_id"], name: "index_licenses_on_term_id"
  end

  create_table "payment_methods", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "method_type"
    t.json "details"
    t.bigint "student_id", null: false
    t.bigint "license_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["license_id"], name: "index_payment_methods_on_license_id"
    t.index ["method_type"], name: "index_payment_methods_on_method_type"
    t.index ["student_id"], name: "index_payment_methods_on_student_id"
  end

  create_table "purchases", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "active"
    t.bigint "student_id", null: false
    t.bigint "payment_method_id", null: false
    t.string "purchaseable_type", null: false
    t.bigint "purchaseable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_purchases_on_active"
    t.index ["payment_method_id"], name: "index_purchases_on_payment_method_id"
    t.index ["purchaseable_type", "purchaseable_id"], name: "index_purchases_on_purchaseable"
    t.index ["purchaseable_type", "purchaseable_id"], name: "index_purchases_on_purchaseable_type_and_purchaseable_id"
    t.index ["student_id"], name: "index_purchases_on_student_id"
  end

  create_table "schools", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "admin_id"
    t.index ["admin_id"], name: "index_schools_on_admin_id"
  end

  create_table "students", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.bigint "school_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_students_on_school_id"
    t.index ["user_id"], name: "index_students_on_user_id"
  end

  create_table "terms", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.date "start_date"
    t.date "end_date"
    t.bigint "school_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "price", precision: 10
    t.index ["school_id"], name: "index_terms_on_school_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "courses", "terms"
  add_foreign_key "enrollments", "purchases"
  add_foreign_key "enrollments", "students"
  add_foreign_key "licenses", "schools"
  add_foreign_key "licenses", "terms"
  add_foreign_key "payment_methods", "licenses"
  add_foreign_key "payment_methods", "students"
  add_foreign_key "purchases", "payment_methods"
  add_foreign_key "purchases", "students"
  add_foreign_key "students", "schools"
  add_foreign_key "students", "users"
  add_foreign_key "terms", "schools"
end
