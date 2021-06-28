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

ActiveRecord::Schema.define(version: 2021_06_24_123510) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "activities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organisation_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "delivery_partner_identifier"
    t.string "sector"
    t.string "title"
    t.text "description"
    t.date "planned_start_date"
    t.date "planned_end_date"
    t.date "actual_start_date"
    t.date "actual_end_date"
    t.string "recipient_region"
    t.string "aid_type"
    t.string "form_state", null: false
    t.string "level", null: false
    t.uuid "extending_organisation_id"
    t.string "recipient_country"
    t.string "geography"
    t.string "previous_identifier"
    t.string "sector_category"
    t.boolean "publish_to_iati", default: true
    t.uuid "parent_id"
    t.string "transparency_identifier"
    t.boolean "call_present"
    t.date "call_open_date"
    t.date "call_close_date"
    t.string "intended_beneficiaries", array: true
    t.string "roda_identifier_fragment"
    t.string "roda_identifier_compound"
    t.boolean "requires_additional_benefitting_countries"
    t.string "gdi"
    t.integer "total_applications"
    t.integer "total_awards"
    t.string "collaboration_type"
    t.integer "oda_eligibility", default: 1, null: false
    t.boolean "fstc_applies"
    t.integer "covid19_related", default: 0
    t.integer "policy_marker_gender", default: 1000
    t.integer "policy_marker_climate_change_adaptation", default: 1000
    t.integer "policy_marker_climate_change_mitigation", default: 1000
    t.integer "policy_marker_biodiversity", default: 1000
    t.integer "policy_marker_desertification", default: 1000
    t.integer "policy_marker_disability", default: 1000
    t.integer "policy_marker_disaster_risk_reduction", default: 1000
    t.integer "policy_marker_nutrition", default: 1000
    t.integer "sdg_1"
    t.integer "sdg_2"
    t.integer "sdg_3"
    t.boolean "sdgs_apply", default: false, null: false
    t.text "objectives"
    t.string "oda_eligibility_lead"
    t.string "beis_identifier"
    t.string "uk_dp_named_contact"
    t.string "country_delivery_partners", array: true
    t.integer "gcrf_challenge_area"
    t.integer "fund_pillar"
    t.integer "programme_status"
    t.string "channel_of_delivery_code"
    t.integer "source_fund_code"
    t.string "gcrf_strategic_area", default: [], array: true
    t.index ["extending_organisation_id"], name: "index_activities_on_extending_organisation_id"
    t.index ["level"], name: "index_activities_on_level"
    t.index ["organisation_id"], name: "index_activities_on_organisation_id"
    t.index ["parent_id"], name: "index_activities_on_parent_id"
    t.index ["roda_identifier_compound"], name: "index_activities_on_roda_identifier_compound"
    t.index ["transparency_identifier"], name: "index_activities_on_transparency_identifier", unique: true
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
    t.date "period_start_date"
    t.date "period_end_date"
    t.decimal "value", precision: 13, scale: 2
    t.string "currency"
    t.uuid "parent_activity_id"
    t.boolean "ingested", default: false
    t.uuid "report_id"
    t.integer "funding_type"
    t.integer "financial_year"
    t.integer "budget_type"
    t.uuid "providing_organisation_id"
    t.string "providing_organisation_name"
    t.string "providing_organisation_type"
    t.string "providing_organisation_reference"
    t.index ["parent_activity_id"], name: "index_budgets_on_parent_activity_id"
    t.index ["providing_organisation_id"], name: "index_budgets_on_providing_organisation_id"
    t.index ["report_id"], name: "index_budgets_on_report_id"
  end

  create_table "comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "comment"
    t.uuid "owner_id"
    t.uuid "activity_id"
    t.uuid "report_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["activity_id"], name: "index_comments_on_activity_id"
    t.index ["owner_id"], name: "index_comments_on_owner_id"
    t.index ["report_id"], name: "index_comments_on_report_id"
  end

  create_table "external_incomes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "activity_id"
    t.uuid "organisation_id"
    t.decimal "amount", precision: 13, scale: 2
    t.integer "financial_quarter"
    t.integer "financial_year"
    t.boolean "oda_funding"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["activity_id"], name: "index_external_incomes_on_activity_id"
    t.index ["organisation_id"], name: "index_external_incomes_on_organisation_id"
  end

  create_table "forecasts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "forecast_type"
    t.date "period_start_date"
    t.date "period_end_date"
    t.decimal "value", precision: 13, scale: 2
    t.string "currency"
    t.string "providing_organisation_name"
    t.string "providing_organisation_type"
    t.string "providing_organisation_reference"
    t.string "receiving_organisation_name"
    t.string "receiving_organisation_type"
    t.string "receiving_organisation_reference"
    t.boolean "ingested", default: false
    t.uuid "parent_activity_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "report_id"
    t.integer "financial_quarter", null: false
    t.integer "financial_year", null: false
    t.index ["parent_activity_id", "financial_year", "financial_quarter", "forecast_type"], name: "unique_type_per_unversioned_item", unique: true, where: "(report_id IS NULL)"
    t.index ["parent_activity_id", "financial_year", "financial_quarter", "report_id"], name: "unique_report_per_versioned_item", unique: true, where: "(report_id IS NOT NULL)"
    t.index ["parent_activity_id"], name: "index_forecasts_on_parent_activity_id"
    t.index ["report_id"], name: "index_forecasts_on_report_id"
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

  create_table "incoming_transfers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "source_id", null: false
    t.uuid "destination_id", null: false
    t.uuid "report_id"
    t.decimal "value", precision: 13, scale: 2, null: false
    t.integer "financial_year"
    t.integer "financial_quarter"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "beis_identifier"
    t.index ["destination_id"], name: "index_incoming_transfers_on_destination_id"
    t.index ["report_id"], name: "index_incoming_transfers_on_report_id"
    t.index ["source_id"], name: "index_incoming_transfers_on_source_id"
  end

  create_table "matched_efforts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "activity_id"
    t.uuid "organisation_id"
    t.integer "funding_type"
    t.integer "category"
    t.decimal "committed_amount", precision: 13, scale: 2
    t.string "currency"
    t.decimal "exchange_rate", precision: 14, scale: 12
    t.date "date_of_exchange_rate"
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["activity_id"], name: "index_matched_efforts_on_activity_id"
    t.index ["organisation_id"], name: "index_matched_efforts_on_organisation_id"
  end

  create_table "organisations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "organisation_type"
    t.string "language_code"
    t.string "default_currency"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "iati_reference"
    t.string "beis_organisation_reference"
    t.integer "role"
    t.boolean "active", default: true
    t.index ["iati_reference"], name: "index_organisations_on_iati_reference", unique: true
  end

  create_table "outgoing_transfers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "source_id", null: false
    t.uuid "destination_id", null: false
    t.decimal "value", precision: 13, scale: 2, null: false
    t.integer "financial_year"
    t.integer "financial_quarter"
    t.uuid "report_id"
    t.string "beis_identifier"
    t.index ["destination_id"], name: "index_outgoing_transfers_on_destination_id"
    t.index ["report_id"], name: "index_outgoing_transfers_on_report_id"
    t.index ["source_id"], name: "index_outgoing_transfers_on_source_id"
  end

  create_table "reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "state", default: "inactive", null: false
    t.string "description"
    t.uuid "fund_id"
    t.uuid "organisation_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "deadline"
    t.integer "financial_quarter"
    t.integer "financial_year"
    t.index ["fund_id", "organisation_id"], name: "enforce_one_editable_report_per_series", unique: true, where: "((state)::text <> ALL (ARRAY[('inactive'::character varying)::text, ('approved'::character varying)::text]))"
    t.index ["fund_id", "organisation_id"], name: "enforce_one_historic_report_per_series", unique: true, where: "((financial_quarter IS NULL) OR (financial_year IS NULL))"
    t.index ["fund_id"], name: "index_reports_on_fund_id"
    t.index ["organisation_id"], name: "index_reports_on_organisation_id"
    t.index ["state"], name: "index_reports_on_state"
  end

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.boolean "ingested", default: false
    t.uuid "report_id"
    t.integer "financial_quarter"
    t.integer "financial_year"
    t.index ["parent_activity_id"], name: "index_transactions_on_parent_activity_id"
    t.index ["report_id"], name: "index_transactions_on_report_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "identifier"
    t.string "name"
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "organisation_id"
    t.boolean "active", default: true
    t.index ["identifier"], name: "index_users_on_identifier"
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
  end

  add_foreign_key "activities", "activities", column: "parent_id", on_delete: :restrict
  add_foreign_key "activities", "organisations", column: "extending_organisation_id"
  add_foreign_key "activities", "organisations", on_delete: :restrict
  add_foreign_key "budgets", "activities", column: "parent_activity_id", on_delete: :cascade
  add_foreign_key "budgets", "organisations", column: "providing_organisation_id"
  add_foreign_key "incoming_transfers", "activities", column: "destination_id", on_delete: :restrict
  add_foreign_key "incoming_transfers", "activities", column: "source_id", on_delete: :restrict
  add_foreign_key "outgoing_transfers", "activities", column: "destination_id", on_delete: :restrict
  add_foreign_key "outgoing_transfers", "activities", column: "source_id", on_delete: :restrict
  add_foreign_key "forecasts", "activities", column: "parent_activity_id", on_delete: :cascade
  add_foreign_key "transactions", "activities", column: "parent_activity_id", on_delete: :cascade
  add_foreign_key "users", "organisations", on_delete: :restrict
end
