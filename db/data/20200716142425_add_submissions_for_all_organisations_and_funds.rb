require "csv"

class AddSubmissionsForAllOrganisationsAndFunds < ActiveRecord::Migration[6.0]
  def up
    newton_fund = Activity.funds.where("title ILIKE ?", "Newton fund").first
    gcrf = Activity.funds.where("title ILIKE ?", "GCRF").first

    rows = CSV.read("#{Rails.root}/vendor/data/dp_to_fund_mappings/dp_mappings_072020.csv", headers: [:title, :identifier, :gcrf, :newton_fund])
    rows_without_headers = rows[1..-1]
    organisation_hash = rows_without_headers.each_with_object({}) { |row, hash|
      next if row[:identifier].nil?
      hash[row[:identifier]] = {title: row[:title], gcrf: row[:gcrf], newton_fund: row[:newton_fund]}
    }

    organisation_hash.each do |key, value|
      organisation = Organisation.find_by(iati_reference: key)
      if value[:gcrf] == "true"
        gcrf_submission = Submission.new(fund: gcrf, organisation: organisation, description: "Historic tracker data (GCRF)")
        gcrf_submission.save!
      end

      if value[:newton_fund] == "true"
        newt_submission = Submission.new(fund: newton_fund, organisation: organisation, description: "Historic tracker data (Newton fund)")
        newt_submission.save!
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
