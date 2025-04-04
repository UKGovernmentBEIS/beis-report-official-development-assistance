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

ActiveRecord::Schema[7.0].define(version: 2025_02_04_092602) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "activities", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "partner_organisation_identifier"
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
    t.string "roda_identifier"
    t.string "intended_beneficiaries", array: true
    t.string "gdi"
    t.integer "total_applications"
    t.integer "total_awards"
    t.string "collaboration_type"
    t.integer "oda_eligibility", default: 1
    t.boolean "fstc_applies"
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
    t.integer "covid19_related", default: 0
    t.text "objectives"
    t.string "oda_eligibility_lead"
    t.string "beis_identifier"
    t.integer "gcrf_challenge_area"
    t.string "country_partner_organisations", array: true
    t.integer "fund_pillar"
    t.string "uk_po_named_contact"
    t.string "channel_of_delivery_code"
    t.integer "programme_status"
    t.integer "source_fund_code"
    t.string "gcrf_strategic_area", default: [], array: true
    t.uuid "originating_report_id"
    t.string "benefitting_countries", array: true
    t.boolean "is_oda"
    t.integer "ispf_themes", array: true
    t.uuid "linked_activity_id"
    t.integer "tags", array: true
    t.string "ispf_oda_partner_countries", array: true
    t.string "ispf_non_oda_partner_countries", array: true
    t.string "spending_breakdown_filename"
    t.boolean "hybrid_beis_dsit_activity", default: false
    t.index ["extending_organisation_id"], name: "index_activities_on_extending_organisation_id"
    t.index ["level"], name: "index_activities_on_level"
    t.index ["organisation_id"], name: "index_activities_on_organisation_id"
    t.index ["originating_report_id"], name: "index_activities_on_originating_report_id"
    t.index ["parent_id"], name: "index_activities_on_parent_id"
    t.index ["roda_identifier"], name: "index_activities_on_roda_identifier"
    t.index ["transparency_identifier"], name: "index_activities_on_transparency_identifier", unique: true
  end

  create_table "adjustment_details", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "adjustment_id"
    t.uuid "user_id"
    t.string "adjustment_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["adjustment_id"], name: "index_adjustment_details_on_adjustment_id"
    t.index ["adjustment_type"], name: "index_adjustment_details_on_adjustment_type"
    t.index ["user_id"], name: "index_adjustment_details_on_user_id"
  end

  create_table "audits", force: :cascade do |t|
    t.uuid "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.uuid "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.text "audited_changes"
    t.integer "version", default: 0
    t.text "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at", precision: nil
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "budgets", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
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
    t.string "providing_organisation_name"
    t.string "providing_organisation_type"
    t.string "providing_organisation_reference"
    t.uuid "providing_organisation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["parent_activity_id"], name: "index_budgets_on_parent_activity_id"
    t.index ["providing_organisation_id"], name: "index_budgets_on_providing_organisation_id"
    t.index ["report_id"], name: "index_budgets_on_report_id"
  end

  create_table "comments", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "commentable_id"
    t.string "commentable_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "owner_id"
    t.uuid "report_id"
    t.index ["commentable_id"], name: "index_comments_on_commentable_id"
    t.index ["commentable_type"], name: "index_comments_on_commentable_type"
    t.index ["owner_id"], name: "index_comments_on_owner_id"
    t.index ["report_id"], name: "index_comments_on_report_id"
  end

  create_table "commitments", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "value", precision: 13, scale: 2
    t.uuid "activity_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "transaction_date"
    t.index ["activity_id"], name: "index_commitments_on_activity_id", unique: true
  end

  create_table "external_incomes", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "activity_id"
    t.uuid "organisation_id"
    t.decimal "amount", precision: 13, scale: 2
    t.integer "financial_quarter"
    t.integer "financial_year"
    t.boolean "oda_funding"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_external_incomes_on_activity_id"
    t.index ["organisation_id"], name: "index_external_incomes_on_organisation_id"
  end

  create_table "forecasts", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "report_id"
    t.integer "financial_quarter", null: false
    t.integer "financial_year", null: false
    t.index ["parent_activity_id", "financial_year", "financial_quarter", "forecast_type"], name: "unique_type_per_unversioned_item", unique: true, where: "(report_id IS NULL)"
    t.index ["parent_activity_id", "financial_year", "financial_quarter", "report_id"], name: "unique_report_per_versioned_item", unique: true, where: "(report_id IS NOT NULL)"
    t.index ["parent_activity_id"], name: "index_forecasts_on_parent_activity_id"
    t.index ["report_id"], name: "index_forecasts_on_report_id"
  end

  create_table "historical_events", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "activity_id"
    t.text "value_changed"
    t.text "new_value"
    t.text "previous_value"
    t.text "reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "report_id"
    t.string "trackable_id"
    t.string "trackable_type"
    t.index ["activity_id"], name: "index_historical_events_on_activity_id"
    t.index ["report_id"], name: "index_historical_events_on_report_id"
    t.index ["trackable_type", "trackable_id"], name: "index_historical_events_on_trackable_type_and_trackable_id"
    t.index ["user_id"], name: "index_historical_events_on_user_id"
  end

  create_table "incoming_transfers", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "source_id", null: false
    t.uuid "destination_id", null: false
    t.uuid "report_id"
    t.decimal "value", precision: 13, scale: 2, null: false
    t.integer "financial_year"
    t.integer "financial_quarter"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "beis_identifier"
    t.index ["destination_id"], name: "index_incoming_transfers_on_destination_id"
    t.index ["report_id"], name: "index_incoming_transfers_on_report_id"
    t.index ["source_id"], name: "index_incoming_transfers_on_source_id"
  end

  create_table "matched_efforts", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "activity_id"
    t.uuid "organisation_id"
    t.integer "funding_type"
    t.integer "category"
    t.decimal "committed_amount", precision: 13, scale: 2
    t.string "currency"
    t.decimal "exchange_rate", precision: 14, scale: 12
    t.date "date_of_exchange_rate"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_matched_efforts_on_activity_id"
    t.index ["organisation_id"], name: "index_matched_efforts_on_organisation_id"
  end

  create_table "org_participations", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "organisation_id"
    t.uuid "activity_id"
    t.integer "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_org_participations_on_activity_id"
    t.index ["organisation_id", "activity_id", "role"], name: "idx_org_participations_on_org_and_act_and_role", unique: true
    t.index ["organisation_id"], name: "index_org_participations_on_organisation_id"
    t.index ["role"], name: "index_org_participations_on_role"
  end

  create_table "organisations", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "organisation_type"
    t.string "language_code"
    t.string "default_currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "iati_reference"
    t.string "beis_organisation_reference"
    t.integer "role"
    t.boolean "active", default: true
    t.string "alternate_names", array: true
    t.index ["iati_reference"], name: "index_organisations_on_iati_reference", unique: true
  end

  create_table "organisations_users", id: false, force: :cascade do |t|
    t.uuid "organisation_id", null: false
    t.uuid "user_id", null: false
    t.index ["organisation_id", "user_id"], name: "index_organisations_users_on_organisation_id_and_user_id"
    t.index ["user_id", "organisation_id"], name: "index_organisations_users_on_user_id_and_organisation_id"
  end

  create_table "outgoing_transfers", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
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

  create_table "reports", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "state", default: "active", null: false
    t.string "description"
    t.uuid "fund_id"
    t.uuid "organisation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "deadline"
    t.integer "financial_quarter"
    t.integer "financial_year"
    t.string "export_filename"
    t.datetime "approved_at", precision: nil
    t.boolean "is_oda"
    t.index ["fund_id", "organisation_id", "is_oda"], name: "enforce_one_editable_report_per_series", unique: true, where: "((state)::text <> 'approved'::text)"
    t.index ["fund_id", "organisation_id"], name: "enforce_one_historic_report_per_series", unique: true, where: "((financial_quarter IS NULL) OR (financial_year IS NULL))"
    t.index ["fund_id"], name: "index_reports_on_fund_id"
    t.index ["organisation_id"], name: "index_reports_on_organisation_id"
    t.index ["state"], name: "index_reports_on_state"
  end

  create_table "transactions", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.text "description"
    t.string "transaction_type"
    t.date "date"
    t.decimal "value", precision: 13, scale: 2
    t.string "disbursement_channel"
    t.string "currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "type"
    t.index ["parent_activity_id"], name: "index_transactions_on_parent_activity_id"
    t.index ["report_id"], name: "index_transactions_on_report_id"
    t.index ["type"], name: "index_transactions_on_type"
  end

  create_table "users", id: :uuid, default: -> { "public.gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "organisation_id"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login", default: true
    t.string "mobile_number"
    t.datetime "mobile_number_confirmed_at", precision: nil
    t.datetime "deactivated_at", precision: nil
    t.datetime "anonymised_at", precision: nil
    t.string "otp_secret"
    t.index ["organisation_id"], name: "index_users_on_organisation_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "activities", "activities", column: "parent_id", on_delete: :restrict
  add_foreign_key "activities", "organisations", column: "extending_organisation_id"
  add_foreign_key "activities", "organisations", on_delete: :restrict
  add_foreign_key "budgets", "activities", column: "parent_activity_id", on_delete: :cascade
  add_foreign_key "budgets", "organisations", column: "providing_organisation_id"
  add_foreign_key "forecasts", "activities", column: "parent_activity_id", on_delete: :cascade
  add_foreign_key "incoming_transfers", "activities", column: "destination_id", on_delete: :restrict
  add_foreign_key "incoming_transfers", "activities", column: "source_id", on_delete: :restrict
  add_foreign_key "outgoing_transfers", "activities", column: "destination_id", on_delete: :restrict
  add_foreign_key "outgoing_transfers", "activities", column: "source_id", on_delete: :restrict
  add_foreign_key "transactions", "activities", column: "parent_activity_id", on_delete: :cascade
  add_foreign_key "users", "organisations", on_delete: :restrict
end
