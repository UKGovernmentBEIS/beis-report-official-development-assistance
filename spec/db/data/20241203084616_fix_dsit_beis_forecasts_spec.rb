require Rails.root + "db/data/20241203084616_fix_dsit_beis_forecasts.rb"

RSpec.describe FixDsitBeisForecasts do
  describe "#migrate!" do
    it "fixes only the appropriate forecasts and includes a count" do
      activity = create(:programme_activity)
      create_forecast_with(activity, "GB-GOV-13", "DEPARTMENT FOR BUSINESS, ENERGY & INDUSTRIAL STRATEGY")
      create_forecast_with(activity, "GB-GOV-26", "DEPARTMENT FOR SCIENCE, INNOVATION AND TECHNOLOGY")

      create_forecast_with(activity, "GB-GOV-26", "NOT CORRECT")

      subject = Forecast.unscoped.order(:providing_organisation_name).last

      expect(Forecast.unscoped.count).to be 3
      expect(subject.providing_organisation_name).to eql "NOT CORRECT"

      migration = described_class.new
      migration.migrate!

      expect(Forecast.unscoped.count).to be 3
      expect(subject.reload.providing_organisation_name).to eql "DEPARTMENT FOR SCIENCE, INNOVATION AND TECHNOLOGY"

      expect(migration.target).to be 1
      expect(migration.fixed).to be 1
    end
  end

  describe "#fix_forecast" do
    it "updates the providing_organisation_name" do
      activity = create(:programme_activity)
      create_forecast_with(activity, "GB-GOV-26", "DEPARTMENT FOR BUSINESS, ENERGY & INDUSTRIAL STRATEGY")
      subject = Forecast.unscoped.last

      expect(subject.providing_organisation_name).to eql("DEPARTMENT FOR BUSINESS, ENERGY & INDUSTRIAL STRATEGY")

      described_class.new.fix_forecast(subject)

      expect(subject.reload.providing_organisation_name).to eql("DEPARTMENT FOR SCIENCE, INNOVATION AND TECHNOLOGY")
    end

    it "does not update the update_at value" do
      activity = create(:programme_activity)
      create_forecast_with(activity, "GB-GOV-26", "DEPARTMENT FOR BUSINESS, ENERGY & INDUSTRIAL STRATEGY")
      subject = Forecast.unscoped.last
      previous_updated_at = subject.updated_at

      travel_to(Date.today + 1.day) do
        described_class.new.fix_forecast(subject)

        expect(subject.reload.updated_at).to eql previous_updated_at
      end
    end
  end

  def create_forecast_with(activity, reference, name)
    sql = "INSERT INTO forecasts \
    (
      providing_organisation_reference,
      providing_organisation_name,
      parent_activity_id,
      created_at,
      updated_at,
      financial_quarter,
      financial_year) \
    VALUES \
    (
      '#{reference}',
      '#{name}',
      '#{activity.id}',
      CURRENT_TIMESTAMP,
      CURRENT_TIMESTAMP,
      '4',
      '2024'
    );"

    ActiveRecord::Base.connection.execute(sql)
  end
end
