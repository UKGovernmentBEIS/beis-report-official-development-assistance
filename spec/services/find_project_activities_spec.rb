require "rails_helper"

RSpec.describe FindProjectActivities do
  let(:user) { create(:beis_user) }
  let(:service_owner) { create(:beis_organisation) }
  let(:other_organisation) { create(:organisation) }

  let!(:organisation_project) { create(:project_activity, organisation: other_organisation) }
  let!(:other_project) { create(:project_activity) }

  before(:all) do
    Bullet.add_whitelist type: :unused_eager_loading, class_name: "Activity", association: :parent
  end

  after(:all) do
    Bullet.delete_whitelist(type: :unused_eager_loading, class_name: "Activity", association: :parent)
  end

  describe "#call" do
    it "eager loads the organisation and parent activity" do
      expect_any_instance_of(ActiveRecord::Relation)
        .to receive(:includes)
        .with(:organisation, :parent)
        .and_call_original

      described_class.new(organisation: service_owner, current_user: user).call
    end

    context "when the organisation is the service owner" do
      it "returns all project activities" do
        result = described_class.new(organisation: service_owner, current_user: user).call

        expect(result).to match_array [organisation_project, other_project]
      end
    end

    context "when the organisation is not the service owner" do
      it "returns project activities for this organisation" do
        result = described_class.new(organisation: other_organisation, current_user: user).call

        expect(result).to match_array [organisation_project]
      end
    end
  end
end
