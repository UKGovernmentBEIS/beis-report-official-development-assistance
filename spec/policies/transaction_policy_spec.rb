require "rails_helper"

RSpec.describe TransactionPolicy do
  let(:user) { create(:administrator) }
  let(:activity) { create(:activity, organisation: user.organisation) }
  let(:transaction) { create(:transaction, activity: activity) }

  subject { described_class.new(user, transaction) }

  it { is_expected.to permit_action(:index) }
  it { is_expected.to permit_action(:show) }
  it { is_expected.to permit_new_and_create_actions }
  it { is_expected.to permit_edit_and_update_actions }
  it { is_expected.to permit_action(:destroy) }

  it "includes activity in resolved scope" do
    resolved_scope = described_class::Scope.new(user, Transaction.all).resolve
    expect(resolved_scope).to include(transaction)
  end
end
