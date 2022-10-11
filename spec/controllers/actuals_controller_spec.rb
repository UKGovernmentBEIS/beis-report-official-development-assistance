require "rails_helper"

RSpec.describe ActualsController do
  let(:user) { create(:partner_organisation_user, organisation: organisation) }
  let(:organisation) { create(:partner_organisation) }
  let(:activity) { build_stubbed(:project_activity) }
  let(:report) { double("report") }
  let(:result) { Result.new(false) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(Activity).to receive(:find).and_return(activity)
  end

  describe "#update" do
    let(:actual) { build_stubbed(:actual) }
    let(:updater) { instance_double(UpdateActual, call: result) }

    before do
      allow(Actual).to receive(:find).and_return(actual)
      policy = instance_double(ActualPolicy, update?: true)
      allow(ActualPolicy).to receive(:new).and_return(policy)
      allow(UpdateActual).to receive(:new).and_return(updater)
      allow(Report).to receive(:editable_for_activity).and_return(report)
    end

    it "asks the UpdateActual service to persist the changes" do
      params = {
        actual_form: {value: "200.02", financial_quarter: "2"},
        activity_id: "abc123",
        id: "xyz321"
      }

      put :update, params: params

      expect(UpdateActual).to have_received(:new).with(
        user: user,
        actual: actual,
        report: report
      )
      expect(updater).to have_received(:call).with(
        attributes: {"value" => "200.02", "financial_quarter" => "2"}
      )
    end
  end
end
