RSpec.describe ActivitySearch do
  let(:beis_user) { create(:beis_user) }
  let(:alice) { create(:delivery_partner_user) }
  let(:bob) { create(:delivery_partner_user) }

  let!(:fund) { create(:fund_activity) }
  let!(:programme) { create(:programme_activity, parent: fund) }

  let!(:alice_project) { create(:project_activity, parent: programme, organisation: alice.organisation, roda_identifier_fragment: "fragment") }
  let!(:alice_third_party_project) { create(:third_party_project_activity, parent: alice_project, organisation: alice.organisation) }

  let!(:bob_project) { create(:project_activity, parent: programme, organisation: bob.organisation) }
  let!(:bob_third_party_project) { create(:third_party_project_activity, parent: bob_project, organisation: bob.organisation, roda_identifier_fragment: "fragment") }

  let(:activity_search) { ActivitySearch.new(user: user, query: query) }

  context "for BEIS users" do
    let(:user) { beis_user }

    describe "searching for a fund's RODA identifier" do
      let(:query) { fund.roda_identifier }

      it "returns the matching fund" do
        expect(activity_search.results).to match_array [fund]
      end
    end

    describe "searching for RODA identifier fragments" do
      let(:query) { "fragment" }

      it "returns all activities with that fragment" do
        expect(activity_search.results).to match_array [alice_project, bob_third_party_project]
      end
    end
  end

  context "for delivery partners" do
    let(:user) { alice }

    describe "searching for a fund's RODA identifier" do
      let(:query) { fund.roda_identifier }

      it "returns nothing" do
        expect(activity_search.results).to match_array []
      end
    end

    describe "searching for a RODA identifier fragments" do
      let(:query) { "fragment" }

      it "returns only the user's own activities" do
        expect(activity_search.results).to match_array [alice_project]
      end
    end
  end
end
