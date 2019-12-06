require "rails_helper"

RSpec.describe TransactionPolicy do
  subject { described_class.new(user, transaction) }

  let(:organisation) { create(:organisation) }
  let!(:fund) { create(:fund, organisation: organisation) }
  let!(:transaction) { create(:transaction, fund: fund) }

  context "as an administrator" do
    let(:user) { build_stubbed(:administrator) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }
  end

  context "as a delivery partner" do
    let(:user) { build_stubbed(:user) }
    let(:resolved_scope) do
      described_class::Scope.new(user, Transaction.all).resolve
    end

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_new_and_create_actions }
    it { is_expected.to permit_edit_and_update_actions }
    it { is_expected.to permit_action(:destroy) }

    context "with transactions from funds in my own organisation" do
      let(:user) { create(:user, organisations: [organisation]) }

      it "includes transaction in resolved scope" do
        expect(resolved_scope).to include(transaction)
      end
    end

    context "with transactions from funds in another organisation" do
      let(:other_organisation) { create(:organisation) }
      let(:forbidden_fund) { create(:fund, organisation: other_organisation) }
      let(:transaction) { create(:transaction, fund: forbidden_fund) }

      it "does not include transaction in resolved scope" do
        expect(resolved_scope).to_not include(transaction)
      end
    end
  end
end
