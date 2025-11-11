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

ActiveRecord::Schema[8.1].define(version: 2025_11_11_131109) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.decimal "balance", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.decimal "initial_balance", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "interest_rate", precision: 5, scale: 3
    t.date "loan_start_date"
    t.string "name", null: false
    t.datetime "opened_at", null: false
    t.decimal "principal", precision: 10, scale: 2
    t.integer "term_years"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["type"], name: "index_accounts_on_type"
  end

  create_table "adjustments", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "adjusted_at", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "updated_at", null: false
    t.index ["account_id", "adjusted_at"], name: "index_adjustments_on_account_id_and_adjusted_at"
    t.index ["account_id"], name: "index_adjustments_on_account_id"
  end

  create_table "projections", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "annual_return_rate", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.decimal "monthly_contribution", precision: 10, scale: 2, default: "0.0", null: false
    t.date "target_date"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_projections_on_account_id", unique: true
  end

  add_foreign_key "adjustments", "accounts"
  add_foreign_key "projections", "accounts"
end
