require "rails_helper"

RSpec.describe Forecast, type: :model do
  before do
    @default_scopes = Forecast.default_scopes
    Forecast.default_scopes = []
  end

  after do
    Forecast.default_scopes = @default_scopes
  end

  let(:activity) { build(:project_activity) }

  describe "validations" do
    it { should validate_presence_of(:forecast_type) }
    it { should validate_presence_of(:period_start_date) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:value) }

    context "when the activity belongs to a partner organisation" do
      before { activity.update(organisation: build_stubbed(:partner_organisation)) }

      it "should validate the presence of report" do
        actual = build_stubbed(:actual, parent_activity: activity, report: nil)
        expect(actual.valid?).to be false
      end
    end

    context "when the activity belongs to BEIS" do
      before { activity.update(organisation: build_stubbed(:beis_organisation)) }

      it "should not validate the presence of report" do
        actual = build_stubbed(:actual, parent_activity: activity, report: nil)
        expect(actual.valid?).to be true
      end
    end
  end
end
