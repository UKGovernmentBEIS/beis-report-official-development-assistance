require "csv"

class IngestCsv
  ACCEPTABLE_INVALID_ATTRIBUTES = [:gdi, :intended_beneficiaries].freeze

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

          activity.assign_attributes(attributes)

          if activity.valid?
            # Clean save
            activity.save!
          elsif (activity.errors.keys - ACCEPTABLE_INVALID_ATTRIBUTES).empty?
            # Force validation if the only invalid fields are ones we're ok with
            activity.save!(validate: false)
          else
            # Skip row and write message
            write_log("Skipping Activity #{activity.id}: #{activity.errors.full_messages}")
            write_log("attributes: #{attributes.sort.inspect}")
            # binding.pry
          end
        end
      end
    end
  end

  private

  def activity_for(row)
    if has_parent_identifier?
      parent = Activity.find_by(roda_identifier_compound: row["parent_roda_identifier_compound"])
      return :missing_parent if parent.nil?

      Activity.new(
        parent: parent,
        level: parent.child_level,
        form_state: :complete,
        ingested: true,
        funding_organisation_name: "Department for Business, Energy and Industrial Strategy",
        funding_organisation_reference: "GB-GOV-13",
        funding_organisation_type: "10",
        accountable_organisation_name: "Department for Business, Energy and Industrial Strategy",
        accountable_organisation_reference: "GB-GOV-13",
        accountable_organisation_type: "10",
        reporting_organisation: beis_organisation,
        organisation: parent.organisation,
        extending_organisation: parent.extending_organisation
      )
    else
      Activity.where.not(level: nil).find_by(
        delivery_partner_identifier: row["delivery_partner_identifier"]
      )
    end
  end

  def has_parent_identifier?
    @has_parent_identifier ||= csv.first.headers.include?("parent_roda_identifier_compound")
  end

  def write_log(message)
    Rails.logger.info(message)
  end

  def beis_organisation
    @beis_organisation ||= Organisation.find_by(service_owner: true)
  end
end
