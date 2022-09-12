RSpec.describe ActivitySearch do
  let(:beis_user) { create(:beis_user) }
  let(:alice) { create(:partner_organisation_user) }
  let(:bob) { create(:partner_organisation_user) }

  let!(:fund) { create(:fund_activity, roda_identifier: "ABC") }

  let!(:alice_programme) { create(:programme_activity, parent: fund, extending_organisation: alice.organisation, roda_identifier: "alice") }
  let!(:alice_project) { create(:project_activity, parent: alice_programme, extending_organisation: alice.organisation) }
  let!(:alice_third_party_project) { create(:third_party_project_activity, parent: alice_project, extending_organisation: alice.organisation) }

  let!(:bob_programme) { create(:programme_activity, parent: fund, extending_organisation: bob.organisation) }
  let!(:bob_project) { create(:project_activity, parent: bob_programme, extending_organisation: bob.organisation) }
  let!(:bob_third_party_project) { create(:third_party_project_activity, parent: bob_project, extending_organisation: bob.organisation, roda_identifier: "bob") }

  let(:activity_search) { ActivitySearch.new(user: user, query: query) }

  context "for BEIS users" do
    let(:user) { beis_user }

    describe "searching for a fund's RODA identifier" do
      let(:query) { fund.roda_identifier }

      it "returns the matching fund" do
        expect(activity_search.results).to match_array [fund]
      end
    end

    describe "searching for partner organisation identifiers" do
      let(:query) { alice_project.partner_organisation_identifier }

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [alice_project]
      end
    end

    describe "searching for BEIS identifiers" do
      let(:query) { bob_programme.beis_identifier }

      before do
        bob_programme.update!(beis_identifier: "programme-id")
      end

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [bob_programme]
      end
    end

    describe "searching for previous identifiers" do
      let(:query) { bob_programme.previous_identifier }

      before do
        bob_programme.update!(previous_identifier: "programme-id")
      end

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [bob_programme]
      end
    end

    describe "searching for IATI identifiers" do
      let(:query) { bob_programme.transparency_identifier }

      before do
        bob_programme.update!(transparency_identifier: "programme-iati-id")
      end

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [bob_programme]
      end
    end

    describe "searching by title" do
      let(:query) { "Search" }

      before do
        alice_third_party_project.update!(title: "Research and development")
        bob_project.update!(title: "Search and rescue")
      end

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [alice_third_party_project, bob_project]
      end
    end

    describe "searching by partial RODA identifier" do
      let(:query) { "roda" }

      before do
        alice_third_party_project.update!(roda_identifier: "roda-123")
        bob_project.update!(roda_identifier: "123-roda")
      end

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [alice_third_party_project, bob_project]
      end
    end
  end

  context "for partner organisations" do
    let(:user) { alice }

    describe "searching for a fund's RODA identifier" do
      let(:query) { fund.roda_identifier }

      it "returns nothing" do
        expect(activity_search.results).to match_array []
      end
    end

    describe "searching for their own partner organisation identifiers" do
      let(:query) { alice_project.partner_organisation_identifier }

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [alice_project]
      end
    end

    describe "searching for another partner organisation's identifiers" do
      let(:query) { bob_project.partner_organisation_identifier }

      it "returns nothing" do
        expect(activity_search.results).to match_array []
      end
    end

    describe "searching for their own project's IATI identifiers" do
      let(:query) { alice_project.transparency_identifier }

      before do
        alice_project.update!(transparency_identifier: "project-iati-id")
      end

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [alice_project]
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
      let(:query) { alice_programme.beis_identifier }

      before do
        alice_programme.update!(beis_identifier: "programme-id")
        bob_programme.update!(beis_identifier: "programme-id")
      end

      it "returns only the user's programme" do
        expect(activity_search.results).to match_array [alice_programme]
      end
    end

    describe "searching by title" do
      let(:query) { "Search" }

      before do
        alice_third_party_project.update!(title: "Research and development")
        bob_project.update!(title: "Search and rescue")
      end

      it "returns only the user's own activities" do
        expect(activity_search.results).to match_array [alice_third_party_project]
      end
    end

    describe "searching by partial RODA identifier" do
      let(:query) { "roda" }

      before do
        alice_third_party_project.update!(roda_identifier: "roda-123")
        bob_project.update!(roda_identifier: "123-roda")
      end

      it "returns the matching activities" do
        expect(activity_search.results).to match_array [alice_third_party_project]
      end
    end
  end
end
