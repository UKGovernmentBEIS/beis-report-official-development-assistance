require "rails_helper"

RSpec.describe Staff::TransactionsController do
  let(:user) { create(:delivery_partner_user, organisation: organisation) }
  let(:organisation) { create(:delivery_partner_organisation) }
  let(:activity) { build_stubbed(:project_activity) }
  let(:report) { double("report") }
  let(:result) { Result.new(false) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
    allow(Activity).to receive(:find).and_return(activity)
  end

  describe "#update" do
    let(:transaction) { build_stubbed(:transaction) }
    let(:updater) { instance_double(UpdateTransaction, call: result) }

    before do
      allow(Transaction).to receive(:find).and_return(transaction)
      policy = instance_double(TransactionPolicy, update?: true)
      allow(TransactionPolicy).to receive(:new).and_return(policy)
      allow(UpdateTransaction).to receive(:new).and_return(updater)
      allow(Report).to receive(:editable_for_activity).and_return(report)
    end

    it "asks the UpdateTransaction service to persist the changes" do
      params = {
        transaction: {value: "200.02", financial_quarter: "2"},
        activity_id: "abc123",
        id: "xyz321",
      }

      put :update, params: params

      expect(UpdateTransaction).to have_received(:new).with(
        user: user,
        transaction: transaction,
        report: report
      )
      expect(updater).to have_received(:call).with(
        attributes: {"value" => "200.02", "financial_quarter" => "2"}
      )
    end
  end
end
