require "rails_helper"

RSpec.describe Staff::Exports::OrganisationsController do
  shared_examples "renders XML" do
    it "sets the XML headers correctly" do
      expect(response.headers.to_h).to include({
        "Content-Disposition" => "attachment; filename=\"GB-GOV-ADTJQ.xml\""
      })
    end

    it "renders the correct template" do
      expect(response).to render_template("staff/exports/organisations/show")
    end
  end

  shared_examples "responds with a 401" do
    it "does not allow the user to access the export" do
      expect(response.status).to eq(401)
    end
  end

  shared_examples "allows the user to access the export" do
    it "responds with a 200" do
      expect(response.status).to eq(200)
    end

    it "sets the CSV headers correctly" do
      expect(response.headers.to_h).to include({
        "Content-Type" => "text/csv"
      })
    end
  end

  let(:organisation) { create(:partner_organisation, iati_reference: "GB-GOV-ADTJQ") }
  let(:fund) { Fund.by_short_name("NF") }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  context "when logged in as a partner organisation user" do
    let(:user) { create(:delivery_partner_user, organisation: organisation) }

    describe "#show" do
      it "only adds a breadcrumb for the current page" do
        allow(controller).to receive(:add_breadcrumb).with(any_args)

        expect(controller).to_not receive(:add_breadcrumb).with(t("breadcrumbs.export.index"), exports_path)
        expect(controller).to receive(:add_breadcrumb).with(t("breadcrumbs.export.organisation.show", name: organisation.name), :exports_organisation_path)

        get "show", params: {id: organisation.id}
      end

      it "does not fetch the XML downloads" do
        get "show", params: {id: organisation.id}

        expect(assigns(:xml_downloads)).to be_nil
      end
    end

    describe "#external_income" do
      before do
        get :external_income, params: {id: organisation.id, fund_id: fund.id, format: :csv}
      end

      include_examples "allows the user to access the export"
    end

    describe "#budgets" do
      before do
        get :budgets, params: {id: organisation.id, fund_id: fund.id, format: :csv}
      end

      include_examples "allows the user to access the export"
    end

    describe "#spending_breakdown" do
      before do
        get :spending_breakdown, params: {id: organisation.id, fund_id: fund.id, format: :csv}
      end

      include_examples "allows the user to access the export"
    end

    describe "#actuals" do
      before do
        get :actuals, params: {id: organisation.id, format: :csv}
      end

      include_examples "responds with a 401"
    end

    describe "#programme_activities" do
      before do
        get :programme_activities, params: {id: organisation.id, fund: fund.short_name, format: :xml}
      end

      include_examples "responds with a 401"
    end

    describe "#project_activities" do
      before do
        get :project_activities, params: {id: organisation.id, fund: fund.short_name, format: :xml}
      end

      include_examples "responds with a 401"
    end

    describe "#third_party_project_activities" do
      before do
        get :third_party_project_activities, params: {id: organisation.id, fund: fund.short_name, format: :xml}
      end

      include_examples "responds with a 401"
    end
  end

  context "when logged in as a BEIS user" do
    let(:user) { create(:beis_user) }

    describe "#show" do
      it "adds the breadcrumb for the exports index and the current page" do
        allow(controller).to receive(:add_breadcrumb).with(any_args)

        expect(controller).to receive(:add_breadcrumb).with(t("breadcrumbs.export.index"), exports_path)
        expect(controller).to receive(:add_breadcrumb).with(t("breadcrumbs.export.organisation.show", name: organisation.name), :exports_organisation_path)

        get "show", params: {id: organisation.id}
      end

      it "fetches the XML downloads" do
        get "show", params: {id: organisation.id}

        expect(assigns(:xml_downloads)).to be_an(Array)
      end
    end

    describe "#external_income" do
      before do
        get :external_income, params: {id: organisation.id, fund_id: fund.id, format: :csv}
      end

      include_examples "allows the user to access the export"
    end

    describe "#actuals" do
      before do
        get :actuals, params: {id: organisation.id, format: :csv}
      end

      include_examples "allows the user to access the export"
    end

    describe "#budgets" do
      before do
        get :budgets, params: {id: organisation.id, fund_id: fund.id, format: :csv}
      end

      include_examples "allows the user to access the export"
    end

    describe "#programme_activities" do
      before do
        @activities = double("ActiveRecord::Relation")
        @find_programme_activities_stub = double("FindProgrammeActivities", call: @activities)
        allow(FindProgrammeActivities).to receive(:new).and_return(@find_programme_activities_stub)

        get :programme_activities, params: {id: organisation.id, fund: fund.short_name, format: :xml, skip_validation: 1}
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

        get :project_activities, params: {id: organisation.id, fund: fund.short_name, format: :xml, skip_validation: 1}
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

        get :third_party_project_activities, params: {id: organisation.id, fund: fund.short_name, format: :xml, skip_validation: 1}
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
