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

    describe "searching for delivery partner identifiers" do
      let(:query) { alice_project.delivery_partner_identifier }

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [alice_project]
      end
    end

    describe "searching for BEIS identifiers" do
      let(:query) { programme.beis_identifier }

      before do
        programme.update!(beis_identifier: "programme-id")
      end

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [programme]
      end
    end

    describe "searching for previous identifiers" do
      let(:query) { programme.previous_identifier }

      before do
        programme.update!(previous_identifier: "programme-id")
      end

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [programme]
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

    describe "searching for their own delivery partner identifiers" do
      let(:query) { alice_project.delivery_partner_identifier }

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [alice_project]
      end
    end

    describe "searching for another delivery partner's identifiers" do
      let(:query) { bob_project.delivery_partner_identifier }

      it "returns nothing" do
        expect(activity_search.results).to match_array []
      end
    end

    describe "searching for their own project's BEIS identifiers" do
      let(:query) { alice_project.beis_identifier }

      before do
        alice_project.update!(beis_identifier: "programme-id")
      end

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [alice_project]
      end
    end

    describe "searching for a programme's BEIS identifiers" do
      let(:query) { programme.beis_identifier }

      before do
        programme.update!(beis_identifier: "programme-id")
      end

      it "returns nothing" do
        expect(activity_search.results).to match_array []
      end
    end
  end
end
