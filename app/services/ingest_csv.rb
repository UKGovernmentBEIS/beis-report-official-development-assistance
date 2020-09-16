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

        Rails.logger.tagged(["IngestCsv", "activity:#{activity.id}"]) do
          attributes = IngestCsvRow.new(row).call

          # Ignore attributes that have been set to :skip
          attributes.delete_if { |_key, value| value == :skip }

          activity.assign_attributes(attributes)

          if activity.valid?
            # Clean save
            activity.save!
          elsif (activity.errors.keys - ACCEPTABLE_INVALID_ATTRIBUTES).empty?
            # Force validation if the only invalid fields are ones we're ok with
            activity.save!(validate: false)
          else
            # Skip row and write message
            write_log("Skipping Activity #{row}: #{activity.errors.full_messages}")
            write_log("attributes: #{attributes.inspect}")
            # binding.pry
          end
        end
      end
    end
  end

  private

  def activity_for(row)
    Activity.where.not(level: nil).find_by(
      delivery_partner_identifier: row["delivery_partner_identifier"]
    )
  end

  def write_log(message)
    Rails.logger.info(message)
  end
end
