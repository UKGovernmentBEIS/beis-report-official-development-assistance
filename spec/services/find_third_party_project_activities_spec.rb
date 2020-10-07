require "rails_helper"

RSpec.describe FindThirdPartyProjectActivities do
  let(:user) { create(:beis_user) }
  let(:service_owner) { create(:beis_organisation) }
  let(:other_organisation) { create(:organisation) }

  let!(:organisation_project) { create(:third_party_project_activity, organisation: other_organisation) }
  let!(:other_project) { create(:third_party_project_activity) }

  describe "#call" do
    it "eager loads the organisation and parent activity" do
      expect_any_instance_of(ActiveRecord::Relation)
        .to receive(:includes)
        .with([:organisation, :parent])
        .and_call_original

      described_class.new(organisation: service_owner, user: user).call
    end

    context "when eager loading parent activities is turned off" do
      it "does not eager load parent" do
        expect_any_instance_of(ActiveRecord::Relation)
          .to receive(:includes)
          .with([:organisation])
          .and_call_original

        described_class.new(organisation: service_owner, user: user)
          .call(eager_load_parent: false)
      end
    end

    context "when the organisation is the service owner" do
      it "returns all third party project activities" do
        result = described_class.new(organisation: service_owner, user: user).call

        expect(result).to match_array [organisation_project, other_project]
      end
    end

    context "when the organisation is not the service owner" do
      it "returns third party project activities for this organisation" do
        result = described_class.new(organisation: other_organisation, user: user).call

        expect(result).to match_array [organisation_project]
      end
    end
  end
end
