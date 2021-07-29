require "rails_helper"

RSpec.describe Staff::Exports::OrganisationsController do
  shared_examples "renders XML" do
    it "sets the XML headers correctly" do
      expect(response.headers.to_h).to include({
        "Content-Disposition" => "attachment; filename=\"GB-GOV-ADTJQ.xml\"",
      })
    end

    it "renders the correct template" do
      expect(response).to render_template("staff/organisations/show")
    end
  end

  shared_examples "does not allow the user to download the XML" do
    it "does not allow the user to download XML" do
      expect(response.status).to eq(401)
    end
  end

  let(:organisation) { create(:delivery_partner_organisation, iati_reference: "GB-GOV-ADTJQ") }
  let(:fund) { Fund.by_short_name("NF") }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
  end

  context "when logged in as a delivery partner" do
    let(:user) { create(:delivery_partner_user, organisation: organisation) }

    describe "#programme_activities" do
      before do
        get :programme_activities, params: {id: organisation.id, fund: fund.short_name}
      end

      include_examples "does not allow the user to download the XML"
    end

    describe "#project_activities" do
      before do
        get :project_activities, params: {id: organisation.id, fund: fund.short_name}
      end

      include_examples "does not allow the user to download the XML"
    end

    describe "#third_party_project_activities" do
      before do
        get :third_party_project_activities, params: {id: organisation.id, fund: fund.short_name}
      end

      include_examples "does not allow the user to download the XML"
    end
  end

  context "when logged in as a BEIS user" do
    let(:user) { create(:beis_user) }

    describe "#programme_activities" do
      before do
        @activities = double("ActiveRecord::Relation")
        @find_programme_activities_stub = double("FindProgrammeActivities", call: @activities)
        allow(FindProgrammeActivities).to receive(:new).and_return(@find_programme_activities_stub)

        get :programme_activities, params: {id: organisation.id, fund: fund.short_name}
      end

      include_examples "renders XML"

      it "finds the programme activities" do
        expect(assigns(:activities)).to eq(@activities)

        expect(FindProgrammeActivities).to have_received(:new).with(organisation: organisation, user: user, fund_code: fund.id)
        expect(@find_programme_activities_stub).to have_received(:call)
      end
    end

    describe "#project_activities" do
      before do
        @activities = double("ActiveRecord::Relation")
        @find_project_activities_stub = double("FindProjectActivities", publishable_to_iati: @activities)
        allow(FindProjectActivities).to receive(:new).and_return(@find_project_activities_stub)
        allow(@find_project_activities_stub).to receive(:call).and_return(@find_project_activities_stub)

        get :project_activities, params: {id: organisation.id, fund: fund.short_name}
      end

      include_examples "renders XML"

      it "finds the project activities" do
        expect(assigns(:activities)).to eq(@activities)

        expect(FindProjectActivities).to have_received(:new).with(organisation: organisation, user: user, fund_code: fund.id)
        expect(@find_project_activities_stub).to have_received(:call)
        expect(@find_project_activities_stub).to have_received(:publishable_to_iati)
      end
    end

    describe "#third_party_project_activities" do
      before do
        @activities = double("ActiveRecord::Relation")
        @find_third_party_project_activities_stub = double("FindThirdPartyProjectActivities", publishable_to_iati: @activities)
        allow(FindThirdPartyProjectActivities).to receive(:new).and_return(@find_third_party_project_activities_stub)
        allow(@find_third_party_project_activities_stub).to receive(:call).and_return(@find_third_party_project_activities_stub)

        get :third_party_project_activities, params: {id: organisation.id, fund: fund.short_name}
      end

      include_examples "renders XML"

      it "finds the project activities" do
        expect(assigns(:activities)).to eq(@activities)

        expect(FindThirdPartyProjectActivities).to have_received(:new).with(organisation: organisation, user: user, fund_code: fund.id)
        expect(@find_third_party_project_activities_stub).to have_received(:call)
        expect(@find_third_party_project_activities_stub).to have_received(:publishable_to_iati)
      end
    end
  end
end
