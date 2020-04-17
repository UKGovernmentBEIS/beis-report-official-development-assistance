# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_04_15_134754) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "activities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organisation_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "identifier"
    t.string "sector"
    t.string "title"
    t.text "description"
    t.string "status"
    t.date "planned_start_date"
    t.date "planned_end_date"
    t.date "actual_start_date"
    t.date "actual_end_date"
    t.string "recipient_region"
    t.string "flow"
    t.string "aid_type"
    t.string "wizard_status"
    t.string "level"
    t.uuid "activity_id"
    t.string "funding_organisation_name"
    t.string "funding_organisation_reference"
    t.string "funding_organisation_type"
    t.string "accountable_organisation_name"
    t.string "accountable_organisation_reference"
    t.string "accountable_organisation_type"
    t.uuid "extending_organisation_id"
    t.string "recipient_country"
    t.string "geography"
    t.uuid "reporting_organisation_id"
    t.string "previous_identifier"
    t.string "sector_category"
    t.index ["activity_id"], name: "index_activities_on_activity_id"
    t.index ["extending_organisation_id"], name: "index_activities_on_extending_organisation_id"
    t.index ["level"], name: "index_activities_on_level"
    t.index ["organisation_id"], name: "index_activities_on_organisation_id"
    t.index ["reporting_organisation_id"], name: "index_activities_on_reporting_organisation_id"
  end

  create_table "auditable_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "trackable_type"
    t.uuid "trackable_id"
    t.string "owner_type"
    t.uuid "owner_id"
    t.string "key"
    t.text "parameters"
    t.string "recipient_type"
    t.uuid "recipient_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id", "owner_type"], name: "index_auditable_events_on_owner_id_and_owner_type"
    t.index ["owner_type", "owner_id"], name: "index_auditable_events_on_owner_type_and_owner_id"
    t.index ["recipient_id", "recipient_type"], name: "index_auditable_events_on_recipient_id_and_recipient_type"
    t.index ["recipient_type", "recipient_id"], name: "index_auditable_events_on_recipient_type_and_recipient_id"
    t.index ["trackable_id", "trackable_type"], name: "index_auditable_events_on_trackable_id_and_trackable_type"
    t.index ["trackable_type", "trackable_id"], name: "index_auditable_events_on_trackable_type_and_trackable_id"
  end

  create_table "budgets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "budget_type"
    t.string "status"
    t.date "period_start_date"
    t.date "period_end_date"
    t.decimal "value", precision: 13, scale: 2
    t.string "currency"
    t.uuid "parent_activity_id"
    t.index ["parent_activity_id"], name: "index_budgets_on_parent_activity_id"
  end

  create_table "implementing_organisations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "reference"
    t.string "organisation_type"
    t.uuid "activity_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["activity_id"], name: "index_implementing_organisations_on_activity_id"
  end

  create_table "organisations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "organisation_type"
    t.string "language_code"
    t.string "default_currency"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "service_owner", default: false
    t.string "iati_reference"
    t.index ["iati_reference"], name: "index_organisations_on_iati_reference", unique: true
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "reference"
    t.text "description"
    t.string "transaction_type"
    t.date "date"
    t.decimal "value", precision: 13, scale: 2
    t.string "disbursement_channel"
    t.string "currency"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "providing_organisation_name"
    t.string "providing_organisation_type"
    t.string "receiving_organisation_name"
    t.string "receiving_organisation_type"
    t.string "providing_organisation_reference"
    t.string "receiving_organisation_reference"
    t.uuid "parent_activity_id"
    t.index ["parent_activity_id"], name: "index_transactions_on_parent_activity_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "identifier"
    t.string "name"
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "role"
    t.uuid "organisation_id"
    t.boolean "active", default: true
    t.index ["identifier"], name: "index_users_on_identifier"
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "activities", "activities"
  add_foreign_key "activities", "organisations", column: "extending_organisation_id"
  add_foreign_key "activities", "organisations", column: "reporting_organisation_id"
  add_foreign_key "activities", "organisations", on_delete: :restrict
  add_foreign_key "budgets", "activities", column: "parent_activity_id", on_delete: :cascade
  add_foreign_key "transactions", "activities", column: "parent_activity_id", on_delete: :cascade
  add_foreign_key "users", "organisations", on_delete: :restrict
end
