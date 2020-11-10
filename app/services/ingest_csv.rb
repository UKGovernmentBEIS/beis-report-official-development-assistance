require "csv"

class IngestCsv
  ACCEPTABLE_INVALID_ATTRIBUTES = [
    :gdi,
    :intended_beneficiaries,
    :report,
    :receiving_organisation_name,
    :receiving_organisation_type,
    :date,
    :collaboration_type,
    :fstc_applies,
  ].freeze

  attr_accessor :csv, :filename

  def initialize(filename)
    self.filename = filename
    self.csv = CSV.foreach(filename, headers: true, skip_blanks: true, encoding: "bom|utf-8", header_converters: ->(h) { h.strip.downcase })
  end

  def call
    write_log("Starting ingest of #{filename}")

    ActiveRecord::Base.transaction do
      csv.each do |row|
        activity = activity_for(row)

        if activity.nil?
          write_log("Couldn't find Activity where #{row.first.first} is #{row.first.last}")
          next
        end

        if activity == :missing_parent
          write_log("Couldn't find parent Activity where roda_identifier_compound is #{row["parent_roda_identifier_compound"]}")
          next
        end

        Rails.logger.tagged(["IngestCsv", "activity:#{activity.id}"]) do
          attributes = IngestCsvRow.new(row).call

          # Ignore attributes that have been set to :skip
          attributes.delete_if { |_key, value| value == :skip }

          # Ignore parent_roda_identifier_compound attribute as there's no equivalent in RODA
          attributes.delete("parent_roda_identifier_compound")

          if has_transactions?
            transaction = activity.transactions.find_or_initialize_by(
              description: attributes["description"]
            ) { |transaction|
              transaction.ingested = true
              transaction.report = Report.find_by!(financial_quarter: nil, fund: activity.associated_fund, organisation: activity.organisation)
            }

            attributes.delete("delivery_partner_identifier")

            save_changes!(transaction, attributes)
          else
            save_changes!(activity, attributes)
          end
        end
      end
    end
  end

  private

  def save_changes!(model, attributes)
    model.assign_attributes(attributes)

    if model.valid?
      # Clean save
      model.save!
    elsif (model.errors.keys - ACCEPTABLE_INVALID_ATTRIBUTES).empty?
      # Force validation if the only invalid fields are ones we're ok with
      model.save!(validate: false)
    else
      # Skip row and log validation errors, ignoring the ones we've deemed acceptable
      ACCEPTABLE_INVALID_ATTRIBUTES.each { |attr| model.errors.delete(attr) }

      write_log("Skipping #{model.model_name.name} #{model.id}: #{model.errors.full_messages}")

      attributes.sort.each do |k, v|
        write_log("attributes: #{k.ljust(30, " ").slice(0...30)} => #{v}")
      end
    end
  end

  def activity_for(row)
    if has_parent_identifier?
      parent = Activity.find_by(roda_identifier_compound: row["parent_roda_identifier_compound"])
      return :missing_parent if parent.nil?

      activity = Activity.find_or_initialize_by(
        delivery_partner_identifier: row["delivery_partner_identifier"],
        parent: parent,
      ) { |activity|
        activity.ingested = true
        activity.funding_organisation_name = "Department for Business, Energy and Industrial Strategy"
        activity.funding_organisation_reference = "GB-GOV-13"
        activity.funding_organisation_type = "10"
        activity.accountable_organisation_name = "Department for Business, Energy and Industrial Strategy"
        activity.accountable_organisation_reference = "GB-GOV-13"
        activity.accountable_organisation_type = "10"
        activity.reporting_organisation = beis_organisation
        activity.organisation = parent.organisation
        activity.extending_organisation = parent.extending_organisation
      }

      # Always update these
      activity.level = parent.child_level
      activity.form_state = :complete

      activity
    else
      Activity.where.not(level: nil).find_by(
        delivery_partner_identifier: row["delivery_partner_identifier"]
      )
    end
  end

  def has_parent_identifier?
    @has_parent_identifier ||= csv.first.headers.include?("parent_roda_identifier_compound")
  end

  def has_transactions?
    @has_transactions ||= csv.first.headers.include?("transaction_type")
  end

  def write_log(message)
    Rails.logger.info(message)
  end

  def beis_organisation
    @beis_organisation ||= Organisation.find_by(service_owner: true)
  end
end
