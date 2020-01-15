require "rails_helper"

RSpec.describe TransactionPolicy do
  let(:organisation) { create(:organisation) }

  subject { described_class.new(user, transaction) }

  context "for a fund" do
    let!(:fund) { create(:fund, organisation: organisation) }
    let!(:transaction) { create(:transaction, fund: fund) }

    context "as an administrator" do
      let(:user) { build_stubbed(:administrator) }

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

    context "as a fund_manager" do
      let(:user) { build_stubbed(:fund_manager, organisation: organisation) }

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

    context "as a delivery partner" do
      let(:user) { build_stubbed(:delivery_partner) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_new_and_create_actions }
      it { is_expected.to forbid_edit_and_update_actions }
      it { is_expected.to forbid_action(:destroy) }

      it "does not include transaction in resolved scope" do
        resolved_scope = described_class::Scope.new(user, Transaction.all).resolve
        expect(resolved_scope).not_to include(transaction)
      end
    end
  end
end
